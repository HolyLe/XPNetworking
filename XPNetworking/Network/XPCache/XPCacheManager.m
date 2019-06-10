//
//  XPCacheManager.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/6/6.
//

#import "XPCacheManager.h"
#import <time.h>
#import <pthread.h>
#import <UIKit/UIKit.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)
@interface XPCacheObject ()<NSCoding>
@property (nonatomic, assign) NSTimeInterval  saveTime;
@property (nonatomic, assign) NSTimeInterval  memoryUseTime;
@property (nonatomic, assign) XPCacheResultStatus  cacheResultStatus;
@end
@implementation XPCacheObject
- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:@(self.cacheResultStatus) forKey:@"cacheResultStatus"];
    [aCoder encodeObject:@(self.cacheType) forKey:@"cacheType"];
    [aCoder encodeObject:@(self.saveTime) forKey:@"saveTime"];
    [aCoder encodeObject:@(self.memoryTime) forKey:@"memoryTime"];
    [aCoder encodeObject:@(self.diskTime) forKey:@"diskTime"];
    [aCoder encodeObject:@(self.isClearWhenDiskTimeOut) forKey:@"isClearWhenDiskTimeOut"];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.cacheResultStatus = [[aDecoder decodeObjectForKey:@"cacheResultStatus"] integerValue];
        _memoryUseTime = time(NULL);
        self.saveTime = [[aDecoder decodeObjectForKey:@"saveTime"] floatValue];
        self.cacheType = [[aDecoder decodeObjectForKey:@"cacheType"] integerValue];
        self.diskTime = [[aDecoder decodeObjectForKey:@"diskTime"] floatValue];
        self.memoryTime = [[aDecoder decodeObjectForKey:@"memoryTime"] floatValue];
        self.isClearWhenDiskTimeOut = [[aDecoder decodeObjectForKey:@"isClearWhenDiskTimeOut"] boolValue];
    }
    return self;
}

@end
@interface XPCacheManager (){
    pthread_mutex_t _lock;
}
@property (nonatomic, strong) dispatch_queue_t  queue;
@property (nonatomic, strong) NSMutableDictionary <NSString *, XPCacheObject *>* memoryData;
@property (nonatomic, strong) NSMutableDictionary <NSString *, XPCacheObject *> * diskData;
/**
 如果内存缓存超过memoryTimeOut时间也没有使用则清除
 */
@property (nonatomic, assign) NSTimeInterval  memoryTimeOut;

/**
 如果磁盘缓存超过disTimeOut时间也没有使用则清除
 */
@property (nonatomic, assign) NSTimeInterval  diskTimeOut;
@end
@implementation XPCacheManager

//初始化
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (void)_appDidReceiveMemoryWarningNotification {
    [self.memoryData removeAllObjects];
    if ([self.delegate respondsToSelector:@selector(xp_cacheRemoveAllMemoryCache)]) {
        [self.delegate xp_cacheRemoveAllMemoryCache];
    }
    
}
- (void)_appDidEnterBackgroundNotification {
    [self.memoryData removeAllObjects];
    if ([self.delegate respondsToSelector:@selector(xp_cacheRemoveAllMemoryCache)]) {
        [self.delegate xp_cacheRemoveAllMemoryCache];
    }
}
- (void)setup{
    pthread_mutex_init(&_lock, NULL);
    _queue = dispatch_queue_create("com.MrXPorse.c_cacheManager", DISPATCH_QUEUE_SERIAL);

    self.memoryTimeOut = 4 * 60;
    self.diskTimeOut = 7 * 60 * 60 * 24;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (NSMutableDictionary<NSString *,XPCacheObject *> *)memoryData{
    if (!_memoryData) {
        _memoryData = [NSMutableDictionary dictionary];
    }
    return _memoryData;
}
- (NSMutableDictionary<NSString *,XPCacheObject *> *)diskData{
    if (!_diskData) {
        _diskData = [NSMutableDictionary dictionary];
    }
    return _diskData;
}
#pragma mark - 数据处理 -
- (void)addObject:(XPCacheObject *)object withKey:(NSString *)key data:(id<NSCoding>)data{
    NSTimeInterval current = time(NULL);
    object.saveTime = current;
    XPCacheType type = object.cacheType;
    switch (type) {
        case XPCacheMemory:{
            
            [self setMemoryDataObject:object key:key];
            [self setMemoryObject:data forKey:key];
            [self removeDiskDataForKey:key];
        }
            break;
        case XPCacheDisk:{
            
            [self setDiskDataObject:object key:key];
            [self setMemoryDataObject:object key:key];
            [self setDiskObject:data forKey:key];
            [self setMemoryObject:data forKey:key];
        }
            break;
        default:
            break;
    }
}
- (void)removeObjectForKey:(NSString *)key{
    [self removeMemoryDataForKey:key];
    [self removeDiskDataForKey:key];
}

- (XPDataPosition)objectForKey:(NSString *)key cacheResult:(XPCacheResultStatus)cacheResult{
    NSDictionary *dic = [self getObjectWithObjectForkey:key newObject:nil];
    XPCacheResultStatus resultType = [dic[@"resultType"] integerValue];
    NSInteger tag = [dic[@"tag"] integerValue];
    if (!(cacheResult & resultType)) {
        tag = XPDataNonContain;
    }
    return tag;
}
- (XPDataPosition)objectForKey:(NSString *)key newObject:(XPCacheObject *)object cacheResult:(XPCacheResultStatus)cacheResult result:(void (^)(XPCacheResultStatus))status{
    NSDictionary *dic = [self getObjectWithObjectForkey:key newObject:object];
    XPDataPosition tag = [dic[@"tag"] integerValue];
    XPCacheResultStatus resultType = [dic[@"resultType"] integerValue];
    if (!(cacheResult & resultType)) {
        tag = XPDataNonContain;
    }
    status(resultType);
    return tag;
}

- (void)objectForKey:(NSString *)key resultBlock:(XPCacheManagerResultBlock)block{
    NSDictionary *dic = [self getObjectWithObjectForkey:key newObject:nil];
    XPCacheResultStatus resultType = [dic[@"resultType"] integerValue];
    NSInteger tag = [dic[@"tag"] integerValue];
    block(resultType, tag);
}

- (NSDictionary *)getObjectWithObjectForkey:(NSString *)key newObject:(XPCacheObject *)newObject{
    NSTimeInterval currentTime = time(NULL);
    
    NSInteger tag = XPDataNonContain;
    XPCacheResultStatus resultType;
    Lock();
    XPCacheObject *object = [self.memoryData objectForKey:key];
    Unlock();
    if (object) {
        tag = XPDataMemoryContain;
        if (newObject) {
            newObject.saveTime = object.saveTime;
            if (object.cacheType == XPCacheMemory) {
                newObject.cacheType = XPCacheMemory;
            }
            [self statusWithMemoryObject:newObject time:currentTime];
        }
        if ([self isShouldUpdateCacheReult:object]) {
            [self statusWithMemoryObject:object time:currentTime];
        }
    }else if(newObject && newObject.cacheType == XPCacheMemory){
        newObject.cacheResultStatus = XPCacheResultNever;
    }else{
        Lock();
        object = [self.diskData objectForKey:key];
        Unlock();
        if (object) {
            tag = XPDataDiskContain;
            if (newObject) {
                newObject.saveTime = object.saveTime;
                [self statusWithDiskObject:newObject time:currentTime];
            }
            if ([self isShouldUpdateCacheReult:object]) {
                [self statusWithDiskObject:object time:currentTime];
            }
            [self setMemoryDataObject:object key:key];
            
        }else{
            object.cacheResultStatus = XPCacheResultNever;
            if (newObject) {
                newObject.cacheResultStatus = XPCacheResultNever;
            }
        }
    }
    switch (tag) {
        case XPDataMemoryContain:
        {
            object.memoryUseTime = currentTime;
        }
            break;
        default:
            break;
    }
    
    resultType = newObject?newObject.cacheResultStatus:object.cacheResultStatus;
    return @{@"tag":@(tag), @"resultType" : @(resultType)};
}

- (void)statusWithMemoryObject:(XPCacheObject *)object time:(NSTimeInterval)currentTime{
    XPCacheResultStatus status;
    switch (object.cacheType) {
        case XPCacheDisk:{
            if (object.memoryTime + object.saveTime >= currentTime || object.memoryTime == 0) {
                status = XPCacheResultNormarl;
            }else if (object.saveTime + object.diskTime >= currentTime || object.diskTime == 0){
                status = XPCacheResultMemoryTimeOut;
            }else{
                status = XPCacheResultDiskTimeOut;
            }
        }
            break;
        case XPCacheMemory:{
            if (object.memoryTime + object.saveTime >= currentTime) {
                status = XPCacheResultNormarl;
            }else{
                status = XPCacheResultMemoryTimeOut;
            }
        }
            break;
        default:
            break;
    }
    object.cacheResultStatus = status;
}
- (void)statusWithDiskObject:(XPCacheObject *)object time:(NSTimeInterval)currentTime{
    XPCacheResultStatus status;
    if (object.saveTime + object.diskTime >= currentTime || object.diskTime == 0) {
        if (object.saveTime + object.memoryTime >= currentTime || object.memoryTime == 0) {
            status = XPCacheResultNormarl;
        }else{
            status = XPCacheResultMemoryTimeOut;
        }
    }else{
        status = XPCacheResultDiskTimeOut;
    }
    object.cacheResultStatus = status;
}
- (BOOL)isShouldUpdateCacheReult:(XPCacheObject *)object{
    if (!object.cacheResultStatus) return YES;
    
    switch (object.cacheType) {
        case XPCacheMemory:{
            if (object.cacheResultStatus & XPCacheResultNormarl) {
                return YES;
            }
        }
            break;
        case XPCacheDisk:{
            if (object.cacheResultStatus & (XPCacheResultMemoryTimeOut | XPCacheResultNormarl)) {
                if (object.diskTime != 0) {
                    return YES;
                }
            }
        }
        default:
            break;
    }
    return NO;
}
- (BOOL)cacheObject:(XPCacheObject *)object1 isEqualToObject:(XPCacheObject *)object2{
    if (!object1 || !object2) {
        return YES;
    }
    if (object2.cacheType != object1.cacheType) {
        return NO;
    }
    if (object1.cacheType == object2.cacheType && object2.cacheType == XPCacheMemory) {
        return object1.memoryTime == object2.memoryTime;
    }
    return object1.memoryTime == object2.memoryTime && object1.diskTime == object2.diskTime && object1.isClearWhenDiskTimeOut == object1.isClearWhenDiskTimeOut;
}
- (BOOL)containObjectKey:(NSString *)key resultStatus:(XPCacheResultStatus)status{
    BOOL isContains = NO;
    if (status & XPCacheResultAll) {
        Lock();
        NSArray *diskKeys = _diskData.allKeys.copy;
        NSArray *memoryKeys = _memoryData.allKeys.copy;
        Unlock();
        isContains = [diskKeys containsObject:key] || [memoryKeys containsObject:key];
    }else{
        NSInteger number = [self objectForKey:key cacheResult:status];
        isContains = number == 0;
    }
    return isContains;
}
#pragma mark - 定时器，定期清除过期缓存 -
- (void)start{
    [self trimCache];
}
- (void)trimCache{
    __weak typeof(self)_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(_self)self = _self;
        if (!self) return;
        [self trimTime];
        [self trimCache];
    });
}
- (void)trimTime{
    __weak typeof(self)_self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self)self = _self;
        if (!self) return;
         [self checkDiskTimeOut];
         [self checkMemoryTimeOut];
    });
}
- (void)checkDiskTimeOut{
    Lock();
    NSDictionary *dic = self.diskData.copy;
    NSArray *allKeys = dic.allKeys.copy;
    Unlock();
    NSTimeInterval currentTime = time(NULL);
    for (NSString *key in allKeys) {
        Lock();
        XPCacheObject *object = [self.diskData objectForKey:key];
        Unlock();
        if(object.saveTime + self.diskTimeOut < currentTime && self.diskTimeOut > 0) {
            [self removeDiskDataForKey:key];
            [self removeMemoryDataForKey:key];
            continue;
        }
        if (object.diskTime == 0) {
            continue;
        }else if(object.saveTime + object.diskTime < currentTime){
            if (object.isClearWhenDiskTimeOut) {
                [self removeDiskDataForKey:key];
                [self removeMemoryDataForKey:key];
            }
        }
    }
}

- (void)checkMemoryTimeOut{
    Lock();
    NSDictionary *dic = self.memoryData.copy;
    NSArray *allKeys = dic.allKeys.copy;
    Unlock();
    NSTimeInterval currentTime = time(NULL);
    for (NSString *key in allKeys) {
        Lock();
        XPCacheObject *object = [self.memoryData objectForKey:key];
        Unlock();
        BOOL canMemoryClear = NO;
        switch (object.cacheType) {
            case XPCacheDisk:
            {
                canMemoryClear =  object.saveTime + object.diskTime < currentTime && object.diskTime != 0 && object.isClearWhenDiskTimeOut;
            }
                break;
            case XPCacheMemory:{
                canMemoryClear = object.saveTime + object.memoryTime < currentTime;
            }
                break;
            default:
                break;
        }
        if (!canMemoryClear) {
            canMemoryClear = object.memoryUseTime + self.memoryTimeOut < currentTime;
        }
        if(canMemoryClear){
            [self removeMemoryDataForKey:key];
        }
    }
}
#pragma mark - 数据更新 -
- (void)removeDiskDataForKey:(NSString *)key{
    if ([self.delegate respondsToSelector:@selector(xp_cacheWillRemoveFromDisk:)]) {
        [self.delegate xp_cacheWillRemoveFromDisk:key];
    }
    Lock();
    [self.diskData removeObjectForKey:key];
    Unlock();
    if ([self.delegate respondsToSelector:@selector(xp_cacheUpdata)]) {
        [self.delegate xp_cacheUpdata];
    }
}

- (void)removeMemoryDataForKey:(NSString *)key{
    if ([self.delegate respondsToSelector:@selector(xp_cacheWillRemoveFromMemory:)]) {
        [self.delegate xp_cacheWillRemoveFromMemory:key];
    }
    Lock();
    [self.memoryData removeObjectForKey:key];
    Unlock();
}
- (void)setDiskDataObject:(XPCacheObject *)object key:(NSString *)key{
    Lock();
    [self.diskData setObject:object forKey:key];
    Unlock();
    if ([self.delegate respondsToSelector:@selector(xp_cacheUpdata)]) {
        [self.delegate xp_cacheUpdata];
    }
}
- (void)setDiskObject:(id <NSCoding>)object forKey:(NSString *)key{
    if ([self.delegate respondsToSelector:@selector(xp_cacheWillSaveDiskIn:data:)]) {
        [self.delegate xp_cacheWillSaveDiskIn:key data:object];
    }
}
- (void)setMemoryDataObject:(XPCacheObject *)object key:(NSString *)key{
    object.memoryUseTime = time(NULL);
    Lock();
    [self.memoryData setObject:object forKey:key];
    Unlock();
}
- (void)setMemoryObject:(id <NSCoding>)object forKey:(NSString *)key{
    if ([self.delegate respondsToSelector:@selector(xp_cacheWillSaveMemoryIn:data:)]) {
        [self.delegate xp_cacheWillSaveMemoryIn:key data:object];
    }
}
+ (nullable NSArray<NSString *> *)modelPropertyWhitelist{
    return @[@"diskData"];
}

+ (NSString *)statusStringWithStatus:(XPCacheResultStatus)statu{
    NSMutableString *resultString = [NSMutableString string];
    
    if (statu & XPCacheResultNormarl) {
        [resultString appendString:@"XPCacheResultNormarl |"];
    }
    if (statu & XPCacheResultDiskTimeOut) {
        [resultString appendString:@"XPCacheResultDiskTimeOut |"];
    }
    if (statu & XPCacheResultMemoryTimeOut) {
        [resultString appendString:@"XPCacheResultMemoryTimeOut |"];
    }
    
    if (statu == XPCacheResultNever) {
        [resultString replaceCharactersInRange:NSMakeRange(0, resultString.length) withString:@"XPCacheResultNever |"];
    }
    if (statu == XPCacheResultAll) {
        [resultString replaceCharactersInRange:NSMakeRange(0, resultString.length) withString:@"XPCacheResultAll |"];
    }
    [resultString deleteCharactersInRange:NSMakeRange(resultString.length - 1, 1)];
    return resultString;
}
- (void)removeAllCache{
    Lock();
    [_memoryData removeAllObjects];
    [_diskData removeAllObjects];
    Unlock();
    if ([self.delegate respondsToSelector:@selector(xp_cacheRemoveAllMemoryCache)]) {
        [self.delegate xp_cacheRemoveAllMemoryCache];
    }
    if ([self.delegate respondsToSelector:@selector(xp_cacheRemoveAllDiskCache)]) {
        [self.delegate xp_cacheRemoveAllDiskCache];
    }
    if ([self.delegate respondsToSelector:@selector(xp_cacheUpdata)]) {
        [self.delegate xp_cacheUpdata];
    }
}
@end

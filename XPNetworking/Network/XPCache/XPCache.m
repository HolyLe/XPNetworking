//
//  XPCache.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/6/6.
//

#import "XPCache.h"

#if __has_include(<YYCache/YYCache.h>)
#import <YYCache/YYCache.h>
#else
#import "YYCache.h"
#endif
#import "XPCacheManager.h"

static NSString * const XPCachePathName = @"com.MrXPorse.net";
static NSString * const XPCacheManagerName = @"com.MrXPorse.cacheManager";

@interface XPCacheManager (rh)
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *, XPCacheObject *> * diskData;
@end

@interface XPCache ()<XPCacheManagerDelegate>{
    XPCacheManager *_cacheManager;
    YYMemoryCache *_memoryCache;
    YYDiskCache *_diskCache;
}

@end
static XPCache *_caches = nil;
@implementation XPCache
#pragma mark - 初始化 -
+ (nullable XPCache *)shareCache{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _caches = [XPCache new];
    });
    return _caches;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup{
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cacheFolder stringByAppendingPathComponent:XPCachePathName];
    _diskCache = [[YYDiskCache alloc] initWithPath:path];
    _memoryCache = [YYMemoryCache new];
    _memoryCache.name = XPCachePathName;
    _cacheManager =  [XPCacheManager new];
    id data =  [_diskCache objectForKey:XPCacheManagerName];
    if ([data isKindOfClass:[NSDictionary class]]) {
        _cacheManager.diskData = [NSMutableDictionary dictionaryWithDictionary:data];
    }else{
        [_diskCache removeAllObjects];
    }
    _cacheManager.delegate = self;
    [_cacheManager start];
}

#pragma mark - 缓存 -
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key{
    [self setObject:object forKey:key withCacheType:XPCacheDisk diskTime:0 memoryTime:0 isClear:NO];
}


- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key memoryTime:(NSTimeInterval)memoryTime{
    [self setObject:object forKey:key withCacheType:XPCacheMemory diskTime:0 memoryTime:memoryTime isClear:NO];
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key memoryTime:(NSTimeInterval)memoryTime diskTime:(NSTimeInterval)diskTime{
    [self setObject:object forKey:key withCacheType:XPCacheDisk diskTime:diskTime memoryTime:memoryTime isClear:NO];
}
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key memoryTime:(NSTimeInterval)memoryTime clearDiskTime:(NSTimeInterval)diskTime{
    
    [self setObject:object forKey:key withCacheType:XPCacheDisk diskTime:diskTime memoryTime:memoryTime isClear:YES];
}
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withCacheType:(XPCacheType)cacheType diskTime:(NSTimeInterval)diskTime memoryTime:(NSTimeInterval)memoryTime isClear:(BOOL)isClear{
    if (!object || (cacheType == XPCacheMemory && memoryTime <= 0)) {
        [_cacheManager removeObjectForKey:key];
    }else{
        XPCacheObject *cacheObject = [XPCacheObject new];
        cacheObject.cacheType = cacheType;
        if (cacheType == XPCacheDisk && diskTime > 0 && (memoryTime > diskTime || memoryTime == 0)) {
            memoryTime = diskTime;
        }
        cacheObject.memoryTime = memoryTime;
        cacheObject.diskTime = diskTime;
        cacheObject.isClearWhenDiskTimeOut = isClear;
        [_cacheManager addObject:cacheObject withKey:key data:object];
    }
}
+ (void)setExtendedData:(NSData *)extendedData toObject:(id)object{
    [YYDiskCache setExtendedData:extendedData toObject:object];
}
+ (NSData *)getExtendedDataFromObject:(id)object{
    return [YYDiskCache getExtendedDataFromObject:object];
}
#pragma mark - 查询 -
- (BOOL)containObjectKey:(NSString *)key{
    return [_cacheManager containObjectKey:key resultStatus:XPCacheResultAll];
}
- (BOOL)containObjectKey:(NSString *)key cacheResult:(XPCacheResultStatus)cacheResult{
    return [_cacheManager containObjectKey:key resultStatus:cacheResult];
}

- (XPDataPosition)containObjectKey:(NSString *)key withNewCacheType:(XPCacheType)cacheType diskTime:(NSTimeInterval)diskTime memoryTime:(NSTimeInterval)memoryTime isClear:(BOOL)isClear cacheResult:(XPCacheResultStatus)reslut result:(void (^)(XPCacheResultStatus status))status{
    XPCacheObject *cacheObject = [XPCacheObject new];
    cacheObject.cacheType = cacheType;
    cacheObject.memoryTime = memoryTime;
    cacheObject.diskTime = diskTime;
    if (cacheType == XPCacheDisk && diskTime > 0 && (memoryTime > diskTime || memoryTime == 0)) {
        cacheObject.memoryTime = cacheObject.diskTime;
    }
    cacheObject.isClearWhenDiskTimeOut = isClear;
    return [_cacheManager objectForKey:key newObject:cacheObject cacheResult:reslut result:status];
}

- (id)objectForKey:(NSString *)key cacheResult:(XPCacheResultStatus)cacheResult{
    NSInteger tag = [_cacheManager objectForKey:key cacheResult:cacheResult];
    return [self objectForKey:key position:tag];
}

- (void)objectForKey:(NSString *)key withBlock:(XPCacheResultBlock)block{
    if (!block) return;
    Weak;
    [_cacheManager objectForKey:key resultBlock:^(XPCacheResultStatus status, NSInteger tag) {
        block(status, [weakSelf objectForKey:key position:tag]);
    }];
}

- (id)objectForKey:(NSString *)key withNewCacheType:(XPCacheType)cacheType diskTime:(NSTimeInterval)diskTime memoryTime:(NSTimeInterval)memoryTime isClear:(BOOL)isClear cacheResult:(XPCacheResultStatus)reslut result:(void (^)(XPCacheResultStatus))status{
    return [self objectForKey:key position:[self containObjectKey:key withNewCacheType:cacheType diskTime:diskTime memoryTime:memoryTime isClear:isClear cacheResult:reslut result:status]];
}


- (id)objectForKey:(NSString *)key{
    return [self objectForKey:key cacheResult:XPCacheResultNormarl];
}
- (id)objectForKey:(NSString *)key position:(XPDataPosition)position{
    id data = nil;
    switch (position) {
        case XPDataMemoryContain:{
            data = [_memoryCache objectForKey:key];
            break;
        }
        case XPDataDiskContain:{
            data = [_diskCache objectForKey:key];
            [_memoryCache setObject:data forKey:key];
            break;
        }
        default:
            break;
    }
    return data;
}
- (NSUInteger)cacheSize{
    return _diskCache.totalCost;
}
#pragma mark - 删除 -
- (void)removeObjectForKey:(NSString *)key{
    [_cacheManager removeObjectForKey:key];
}
#pragma mark - XPCacheManagerDelegate -
- (void)xp_cacheWillRemoveFromDisk:(NSString *)key{
    [_diskCache removeObjectForKey:key];
}

- (void)xp_cacheWillRemoveFromMemory:(NSString *)key{
    [_memoryCache removeObjectForKey:key];
}
- (void)xp_cacheWillSaveMemoryIn:(NSString *)key data:(id)data{
    [_memoryCache setObject:data forKey:key];
}
- (void)xp_cacheWillSaveDiskIn:(NSString *)key data:(id)data{
    [_diskCache setObject:data forKey:key];
}
- (void)xp_cacheUpdata{
    [_diskCache setObject:_cacheManager.diskData.copy forKey:XPCacheManagerName];
}
- (void)xp_cacheRemoveAllDiskCache{
    [_diskCache removeAllObjects];
}
- (void)xp_cacheRemoveAllMemoryCache{
    [_memoryCache removeAllObjects];
}
- (void)removeAllCache{
    [_cacheManager removeAllCache];
}

@end

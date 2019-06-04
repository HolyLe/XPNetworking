//
//  XPRequestNetworkManager.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/7.
//

#import "XPRequestNetworkManager.h"
#import "XPRequestUniquePackage.h"
#import <pthread/pthread.h>
#import "XPRequestCategory.h"
#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface XPRequestUniqueTime : NSObject{
    @package;
    NSTimeInterval _uniqueOutTime;
    NSTimeInterval _startTime;
}

@end
@implementation XPRequestUniqueTime

@end
static  NSString *const XPRequestValidationErrorDomain = @"com.rh.network";
@interface XPRequestNetworkManager ()<XPRequestPackageDelegate>{
    pthread_mutex_t _lock;
    dispatch_queue_t _queue;
}
@property (nonatomic, strong) NSMutableDictionary < NSString *,XPRequestUniquePackage *> * uniqueList;
@property (nonatomic, strong) NSMutableDictionary < NSString *, XPRequestUniqueTime *> * timeList;

@property (nonatomic, assign) NSTimeInterval autoTrimInterval;

@end
static XPRequestNetworkManager *_manager = nil;
@implementation XPRequestNetworkManager

- (void)addRequest:(XPBaseRequest *)request{
    NSString *indentifier = [self requestIndentityWithRequest:request];
    if (![self isValidRequest:request indentifier:indentifier]) {
        NSError * __autoreleasing error = nil;
        error = [NSError errorWithDomain:XPRequestValidationErrorDomain code:XPRequestValidErrorUrlFormat userInfo:@{NSLocalizedDescriptionKey : @"Invalid Url format"}];
        request.error = error;
        [request requestFailDealWithRequest:request];
        return;
    }
    Lock();
    XPRequestUniquePackage *package = self.uniqueList[indentifier];
    Unlock();
    if (package) {
        [package addRequest:request];
    }else{
        if (request.isUnique) {
            Lock();
            XPRequestUniqueTime *time = _timeList[indentifier];
            Unlock();
            if (time && CACurrentMediaTime() <= time -> _uniqueOutTime + time -> _startTime) {
                NSError * __autoreleasing error = nil;
                error = [NSError errorWithDomain:XPRequestValidationErrorDomain code:XPRequestValidErrorUniquedFormat userInfo:@{NSLocalizedDescriptionKey : @"Invalid Unique activate"}];
                request.error = error;
                [request requestFailDealWithRequest:request];
                return;
            }
            time = [XPRequestUniqueTime new];
            time -> _startTime = CACurrentMediaTime();
            time -> _uniqueOutTime = request.uniqueTimeOut;
            
            Lock();
            [self.timeList setValue:time forKey:indentifier];
            Unlock();
        }
        package = [XPRequestUniquePackage new];
        Lock();
        [self.uniqueList setValue:package forKey:indentifier];
        Unlock();
        package.delegate = self;
        [package addRequest:request];
    }
}

- (void)cancelRequest:(XPBaseRequest *)request{
    Lock();
    XPRequestUniquePackage *package = self.uniqueList[[self requestIndentityWithRequest:request]];
    Unlock();
    if (request.isExecuting) {
        [[XPRequestSessionManager shareManager] cancelWithRequest:request];
    }
    if (package) {
        if (request.isUnique) {
            [self cacelRequestPackage:request];
        }else{
            [package removeRequest:request];
        }
    }
}
- (void)cancelAllRequest{
    Lock();
    NSArray *allKeys = [_uniqueList allKeys];
    Unlock();
    if (allKeys.count > 0) {
        NSArray *array = allKeys.copy;
        for (NSString *key in array) {
            Lock();
            XPRequestUniquePackage *page = _uniqueList[key];
            Unlock();
            [page removeRequestPackage];
        }
    }
}
- (void)cacelRequestPackage:(XPBaseRequest *)request{
    NSString *indentity = [self requestIndentityWithRequest:request];
    Lock();
    XPRequestUniquePackage *package = _uniqueList[indentity];
    Unlock();
    [package removeRequestPackage];
    Lock();
    [_uniqueList removeObjectForKey:indentity];
    Unlock();
}
- (BOOL)isValidRequest:(XPBaseRequest *)request indentifier:(NSString *)indentifier{
    BOOL isValid = NO;
    if ([indentifier hasPrefix:@"http://"] || [indentifier hasPrefix:@"https://"]) {
        isValid = YES;
    }
    if (!isValid) {
        NSLog(@"检验url不合法");
    }
    return isValid;
}

- (NSString *)requestIndentityWithRequest:(XPBaseRequest *)request{
    NSString *string = [XPRequestTool jsonURLStringWithRequest:request];
    NSMutableString *str = [NSMutableString string];
    if (request.uniqueIdentity > 0) {
        [str appendFormat:@"-%ld", request.uniqueIdentity];
        if (request.uniqueTimeOut > 0) {
            [str appendFormat:@"timeOut%f",request.uniqueTimeOut];
        }
    }
    return [string stringByAppendingString:str.copy];
}


- (void)trimRecursively{
    __weak typeof(self)_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(_self)self = _self;
        [self trimInBackground];
        [self trimRecursively];
    });
}
- (void)trimInBackground{
    dispatch_async(_queue, ^{
        [self trimToTime];
    });
}
- (void)trimToTime{
    Lock();
    NSArray *keys = _timeList.allKeys.copy;
    Unlock();
    for (NSString *key in keys) {
        Lock();
        XPRequestUniqueTime *time = _timeList[key];
        Unlock();
        if (time -> _startTime + time -> _uniqueOutTime <= CACurrentMediaTime()) {
            Lock();
            [_timeList removeObjectForKey:key];
            Unlock();
        }
    }
}
#pragma mark - XPRequestPackageDelegate -

- (void)uniqueRequestFinished:(XPBaseRequest *)request{
    Lock();
    [_uniqueList removeObjectForKey:[self requestIndentityWithRequest:request]];
    Unlock();
}
- (void)startRequestWithRequest:(XPBaseRequest *)request index:(NSInteger)index{
    if (request.isUnique) {
        Lock();
        XPRequestUniqueTime *time = _timeList[[self requestIndentityWithRequest:request]];
        Unlock();
        if (time) {
            time -> _startTime = CACurrentMediaTime();
        }
    }
}
#pragma mark - 初始化 -
- (void)configuredProject:(configure)configure{
    XPRequestConfiguration * config = [XPRequestConfiguration new];
    configure(config);
    _autoTrimInterval = config.autoTrimInterval;
    [XPRequestSessionManager shareManager].configuration = config;
}

- (XPRequestConfiguration *)configuration{
    return [[XPRequestSessionManager shareManager] configuration];
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
    pthread_mutex_init(&_lock, NULL);
    _autoTrimInterval = 5;
    [self timeList];
    _queue = dispatch_queue_create("com.MrXPorse.networkManager", DISPATCH_QUEUE_SERIAL);
    [self trimRecursively];
}

/**
 懒加载
 */
- (NSMutableDictionary *)uniqueList{
    if (!_uniqueList) {
        _uniqueList = [NSMutableDictionary dictionary];
    }
    return _uniqueList;
}
- (NSMutableDictionary<NSString *,XPRequestUniqueTime *> *)timeList{
    if (!_timeList) {
        _timeList = [NSMutableDictionary dictionary];
    }
    return _timeList;
}
+ (XPRequestNetworkManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [XPRequestNetworkManager new];
    });
    return _manager;
}
@end

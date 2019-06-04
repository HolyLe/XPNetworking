//
//  XPBaseRequest.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/4/30.
//

#import "XPBaseRequest.h"
#import "XPRequestNetworkManager.h"
#import "XPRequestCategory.h"
#import "XPRequestUniquePackage.h"
#import "XPCache.h"
#import <pthread.h>


@interface XPBaseRequest ()
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) id originalResponseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSURLSessionTask * requestTask;
@property (nonatomic, assign, readwrite) XPRequestRunningStatus  runningStaus;
@property (nonatomic, assign, readwrite) CGFloat  speed;
@property (nonatomic, assign, readwrite) BOOL  isCacheData;
@end
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wincomplete-implementation"
@implementation XPBaseRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cacheStatus = XPCacheResultNormarl;
        self.allowsCellularAccess = YES;
        _runningStaus = XPRequestRunningStatus_unStart;
        _requestTask = nil;
        self.validStatus = @[@(200), @(300)];
        _uniqueTimeOut = 1;
    }
    return self;
}
@synthesize params = _params;

- (NSMutableDictionary *)params{
    if (!_params) {
        _params = [NSMutableDictionary dictionary];
    }
    return _params;
}
- (NSHTTPURLResponse *)response{
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSURLRequest *)currentRequest{
    return self.requestTask.currentRequest;
}
- (NSURLSessionTask *)currentRequestTask{
    return self.uniqueDelegate.task;
}
- (NSDictionary *)responseHeaders{
    return self.response.allHeaderFields;
}

- (NSURLRequest *)originalRequest{
    return self.requestTask.originalRequest;
}
- (NSInteger)requestStatus{
    return self.response.statusCode;
}


- (BOOL)isValidReult{
    NSInteger status = self.requestStatus;
    NSInteger minStatus = MIN([[_validStatus lastObject] integerValue], [[_validStatus firstObject] integerValue]);
    NSInteger maxStatus = MAX([[_validStatus lastObject] integerValue], [[_validStatus firstObject] integerValue]);
    return status >= minStatus && status <= maxStatus;
}
- (BOOL)validateJson{
    if (!self.originalResponseObject) {
        return NO;
    }
    return YES;
}
- (BOOL)isUnique{
    return self.uniqueIdentity > 0 && self.uniqueTimeOut > 0;
}

- (BOOL)isCancelled{
    return self.runningStaus == XPRequestRunningStatus_finish_Cancel;
}

- (BOOL)isExecuting{
    return self.runningStaus == XPRequestRunningStatus_running;
}

- (BOOL)isFinshed{
    return self.runningStaus == XPRequestRunningStatus_finish_Cancel || self.runningStaus == XPRequestRunningStatus_finish_Failure || self.runningStaus == XPRequestRunningStatus_finish_Success;
}

- (BOOL)isFail{
    return self.runningStaus == XPRequestRunningStatus_finish_Failure;
}

- (BOOL)isUnstart{
    return self.runningStaus == XPRequestRunningStatus_unStart;
}



#pragma mark -method -
- (void)start{
    if ([self isExecuting]) return;
    [self requestWillStartCallBack:self];
    self.runningStaus = XPRequestRunningStatus_running;
    [[XPRequestNetworkManager shareManager] addRequest:self];
}
- (void)stop{
    [self requestWillStopCallBack:self];
    [[XPRequestNetworkManager shareManager] cancelRequest:self];
    [self requestDidStopCallBack:self];
}

- (void)clearCompletionBlock{
    _sucess = nil;
    _failure = nil;
}
- (void)setParams:(NSMutableDictionary *)params{
    if ([params isKindOfClass:[NSMutableDictionary class]]) {
        _params = params;
    }else if([params isKindOfClass:[NSDictionary class]]){
        _params = params.mutableCopy;
    }
}
#pragma mark - RequestFinish -
/**
 请求成功，在后台进程进行的操作
 */
- (void)requestSuccessPreprocessor:(XPBaseRequest *)request{
    
}

/**
 请求成功回调， 在主线程完成
 */
- (void)requsetSuccessFilter:(XPBaseRequest *)request{
    
}

/**
 请求失败，在后台进程进行的操作
 */
- (void)requestFailedPreprocessor:(XPBaseRequest *)request{
    
}

/**
 请求失败回调， 在主线程完成
 */
- (void)requestFailedFilter:(XPBaseRequest *)request{
    
}

/**
 请求取消，在后台进程进行的操作
 */
- (void)requestCancelledPreprocessor:(XPBaseRequest *)request{
    
}

/**
 请求取消回调， 在主线程完成
 */
- (void)requestCancelledFilter:(XPBaseRequest *)request{
    
}

- (void)setCompletionBlockWithSuccess:(XPBaseRequestCompletionBlock)success failure:(XPBaseRequestCompletionBlock)failure{
    self.sucess = success;
    self.failure = failure;
}


- (void)startCompletionBlockWithSuccess:(XPBaseRequestCompletionBlock)success failure:(XPBaseRequestCompletionBlock)failure{
    [self setCompletionBlockWithSuccess:success failure:failure];
    
    [self start];
}

- (BOOL)isCustomCacheData{

    return NO;
}

- (NSString *)cacheKey{
    return [[XPRequestSessionManager shareManager] requestCacheKey:self];
}
- (NSString *)fullUrl{
    if (self.uniqueDelegate) {
        return self.uniqueDelegate.fullUrl;
    }
    return [XPRequestTool fullUrlPathWithRequest:self];
}

- (void)requestWillStart{
    
}



@end
#pragma clang diagnostic pop

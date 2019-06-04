//
//  XPRequestUniquePackage.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/7.
//

#import <pthread/pthread.h>

#import "XPRequestUniquePackage.h"
#import "XPRequestCategory.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

typedef NS_ENUM(NSUInteger, XPCacheQueryStatus) {
    XPCacheQuery_UnStart = 0,//没有开始查询
    XPCacheQuery_Querying,//正在查询
    XPCacheQuery_Finish//完成查询
};
typedef NS_ENUM(NSUInteger, XPRequestStartStatus) {
    XPRequestStatus_noCache = 0,//请求没有缓存
    XPRequestStatus_cacheNil,//缓存无过期但缓存是空的
    XPRequestStatus_timeOut,//缓存过期
    XPRequestStatus_valid//缓存有效
};

@protocol XPRequestPackageCacheDelegate <NSObject>

- (void)queryFinshWithData:(XPBaseRequest *)request;

@end

@interface XPRequestPackageCache : NSObject
/**
 代理
 */
@property (nonatomic, weak) id <XPRequestPackageCacheDelegate> delegate;

/**
 查询装填
 */
@property (nonatomic, assign) XPCacheQueryStatus  queryStatus;

/**
 请求发起时的状态
 */
@property (nonatomic, assign) XPRequestStartStatus status;

@property (nonatomic, strong) XPBaseRequest * request;

@property (nonatomic, copy) NSString * key;

@property (nonatomic, assign) XPDataPosition  position;
//缓存的数据，有可能为nil
@property (nonatomic, strong) id  data;

//查询数据
- (void)queryDataWithRequest:(XPBaseRequest *)request;

//缓存数据
- (void)saveData;

@end

@implementation XPRequestPackageCache

- (void)saveData{
    if (![self.request isCacheStatusValid]) {
        return;
    }
    XPBaseRequest *request = self.request;
    id data = nil;
    data = request.responseObject;
    NSString *key = self.key;
    if (data) {
        [[XPCache shareCache] setObject:data forKey:key withCacheType:request.cacheType diskTime:request.diskCacheTime memoryTime:request.memoryCacheTime isClear:request.isClearWhenDiskTimeOut];
        self.status = XPRequestStatus_valid;
    }else{
        [[XPCache shareCache] removeObjectForKey:key];
    }
    
}
- (void)queryDataWithRequest:(XPBaseRequest *)request{
    if (![request isCacheStatusValid]) {
        self.status = XPRequestStatus_noCache;
        return;
    }
    if (self.queryStatus == XPCacheQuery_UnStart) {
        self.request = request;
        self.key = [XPRequestTool requestCacheKey:request];
        self.queryStatus = XPCacheQuery_Querying;
        [self loadRequestCache];
    }
}

- (void)loadRequestCache{
    __weak typeof(self)weakSelf = self;
    XPBaseRequest *request = self.request;
    self.position = [[XPCache shareCache] containObjectKey:self.key withNewCacheType:request.cacheType diskTime:request.diskCacheTime memoryTime:request.memoryCacheTime isClear:request.isClearWhenDiskTimeOut cacheResult:XPCacheResultAll result:^(XPCacheResultStatus status) {
        __strong typeof(weakSelf)self = weakSelf;
        BOOL isNormal = status & self.request.cacheStatus;
        if (isNormal) {
            self.status = XPRequestStatus_valid;
        }else{
            self.status = XPRequestStatus_timeOut;
        }
    }];
    
    [self loadingCache];
}
- (void)loadingCache{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        id responseObject = [[XPCache shareCache] objectForKey:self.key position:self.position];
        self.queryStatus = XPCacheQuery_Finish;
        XPBaseRequest *request = self.request;
        
        request.originalResponseObject = responseObject;
        if (request.customData) {
            request.responseObject = request.customData(responseObject);
        }else{
            request.responseObject = responseObject;
        }
        self.data = responseObject;
        BOOL isValidateJson = [request validateJson];
        if (self.status == XPRequestStatus_valid) {
            if (isValidateJson) {
                [request requestDidSuccess];
            }else{
                self.data = nil;
                request.responseObject = nil;
                self.status = XPRequestStatus_cacheNil;
                [[XPRequestSessionManager shareManager] startWithRequest:request];
            }
        }else{
            if (!isValidateJson) {
                self.data = nil;
                request.responseObject = nil;
            }
            [self.delegate queryFinshWithData:request];
        }
    });
}
- (void)dealloc
{
    
}
@end
@interface XPRequestUniquePackage ()<XPRequestUniqueDelegate,XPRequestPackageCacheDelegate>{
    pthread_mutex_t _lock;
    BOOL _isAllCancelled;
}
@property (nonatomic, strong) NSMutableArray <XPBaseRequest *> * requests;
@property (nonatomic, strong) NSMutableArray <XPBaseRequest *>* cancelRequests;
@property (nonatomic, strong) NSMutableArray <XPBaseRequest *>* cacheRequests;
//最新的数据
@property (nonatomic, strong) XPRequestPackageCache * packageCache;
@property (nonatomic, assign) BOOL  isFinish;
@property (nonatomic, strong) XPBaseRequest * currentRequest;
@property (nonatomic, assign) NSInteger  currentIndex;
@property (nonatomic, assign) NSInteger  loadedCacheCount;
@property (nonatomic, assign) NSInteger  unloadCacheCount;
@property (nonatomic, assign) BOOL  isLastObject;


/**
 同步数据
 */
@property (nonatomic, assign) NSTimeInterval  currentTime;
@property (nonatomic, assign) NSUInteger  currentCount;
@end

@implementation XPRequestUniquePackage

- (void)addRequest:(XPBaseRequest *)request{
    if ([self.requests containsObject:request]) {
        return;
    }
    Lock();
    [self.requests addObject:request];
    Unlock();
    request.uniqueDelegate = self;
    [self.packageCache queryDataWithRequest:request];
    if ([request isCacheStatusValid]) {
        _unloadCacheCount ++;
        if (self.packageCache.queryStatus == XPCacheQuery_Finish) {
            [self loadCacheData:request];
        }else{
            Lock();
            [self.cacheRequests addObject:request];
            Unlock();
        }
    }
    
    if (_currentIndex == -1) {
        _currentIndex ++;
        [self packageWillStartRequest:request];
    }
}
- (void)loadCacheData:(XPBaseRequest *)request{
    
    dispatch_queue_t queue = request.queue;
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    
    __weak typeof(request)weakRequest = request;
    __weak typeof(self)weakSelf = self;
    dispatch_async(queue, ^{
        __strong typeof(weakRequest)request = weakRequest;
        __strong typeof(weakSelf)self = weakSelf;
        if (!self.packageCache.data) {
            [self cacheCountLoad:request];
            return;
        }
        if (!self) return;
        if (self.isSuccess) return;
        if (request.customData) {
            request.responseObject = request.customData( self.packageCache.data);
        }else{
            request.responseObject = self.packageCache.data;
        }
        if (request.loadCacheWhenFirstStart && request.sucess) {
            request.isCacheData = YES;
            request.sucess(request);
            request.isCacheData = NO;
        }
        [self cacheCountLoad:request];
    });
}
- (void)cacheCountLoad:(XPBaseRequest *)request{
    if ([request.delegate respondsToSelector:@selector(requestFirstCacheLoaded:)]) {
        [request.delegate requestFirstCacheLoaded:request];
    }
    self.loadedCacheCount ++;
    [self requestFailDeal:request];
}
#pragma mark - Delegate -
- (XPBaseRequest *)currentRequest{
    if (_currentIndex < self.requests.count) {
        return _requests[_currentIndex];
    }
    return [_requests  lastObject];
}

- (void)packageWillStartRequest:(XPBaseRequest *)request{
    if (self.packageCache.status == XPRequestStatus_valid || self.packageCache.status == XPRequestStatus_cacheNil) {
        return;
    }
    [self start:request];
}

- (void)start:(XPBaseRequest *)request{
    [[XPRequestSessionManager shareManager] startWithRequest:request];
    if ([self.delegate respondsToSelector:@selector(startRequestWithRequest:index:)]) {
        [self.delegate startRequestWithRequest:request index:self.currentIndex];
    }
    
}

- (void)removeRequest:(XPBaseRequest *)request{
    Lock();
    NSInteger index = [_requests indexOfObject:request];
    Unlock();
    
    if (index == NSNotFound) return;
    
    Lock();
    [self.cancelRequests addObject:request];
    Unlock();
    if (index == _currentIndex) {
        if ([request.uniqueDelegate respondsToSelector:@selector(requestCancelled:)]) {
            [request.uniqueDelegate requestCancelled:request];
        }
    }
}


- (BOOL)isLastObject{
    if (!_isLastObject) {
        _isLastObject = [self isLastRequest];
    }
    return  _isLastObject;
}
- (BOOL)isLastRequest{
    return  _currentIndex + 1 == _requests.count || _isAllCancelled;;
}
- (void)removeRequestPackage{
    _isAllCancelled = YES;
    if (_requests.count > _currentIndex) {
        [self removeRequest:[_requests objectAtIndex:_currentIndex]];
    }
}

#pragma mark - XPRequestUnique -
- (void)requestFailed:(__kindof XPBaseRequest *)request{
    [self uniqueRequestRequest:request];
}

- (void)requestSuccessed:(__kindof XPBaseRequest *)request{
    self.isFinish = YES;
    if (request.uniqueIdentity == 0) {
        Lock();
        NSArray *arr = _requests.copy;
        Unlock();
        for (XPBaseRequest *obj in arr) {
            if ([self.cancelRequests containsObject:obj]) {
                continue;
            }
            [obj requestSuccessDealWithRequest:request];
        }
    }else{
        [request requestSuccessDealWithRequest:request];
    }
    
    [self packageFinish:request];
}



- (void)requestCancelled:(__kindof XPBaseRequest *)request{
    [request requestCancelDeal];
    [self uniqueRequestRequest:request];
}
- (void)uniqueRequestRequest:(XPBaseRequest *)request{
    
    if ([self isLastObject]) {
        self.isFinish = YES;
        [self requestFailDeal:request];
    }else{
        _currentIndex ++ ;
        Lock();
        XPBaseRequest *currentRequest = [_requests objectAtIndex:_currentIndex];
        Unlock();
        if ([self.cancelRequests containsObject:currentRequest]) {
            if ([currentRequest.uniqueDelegate respondsToSelector:@selector(requestCancelled:)]) {
                [currentRequest.uniqueDelegate requestCancelled:currentRequest];
            }
        }else{
            [self packageWillStartRequest:currentRequest];
        }
    }
}
- (void)requestFailDeal:(XPBaseRequest *)request{
    BOOL canBack = self.isFinish && self.unloadCacheCount == self.loadedCacheCount && ((self.packageCache.queryStatus == XPCacheQuery_Finish && self.loadedCacheCount > 0) || (self.packageCache.status == XPRequestStatus_noCache));
    if (canBack) {
        if (_requests.count > 0 && request.uniqueIdentity == 0) {
            Lock();
            NSArray *arr = _requests.copy;
            Unlock();
            for (XPBaseRequest *obj in arr) {
                if ([self.cancelRequests containsObject:obj]) {
                    continue;
                }
                [obj requestFailDealWithRequest:request];
            }
        }else{
            [request requestFailDealWithRequest:request];
        }
        
        [self packageFinish:request];
    }
}

#pragma mark - 初始化 -
- (instancetype)init{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}
- (void)setup{
    
    pthread_mutex_init(&_lock, NULL);
    _isAllCancelled = NO;
    _currentIndex = -1;
    Weak;
    self.uploadProgress = ^(NSProgress * _Nonnull progress, CGFloat speed) {
        Strong;
        NSArray *array = self.requests.copy;
        for (XPBaseRequest *request in array) {
            if (request.uploadProgress) {
                request.uploadProgress(progress, speed);
            }
        }
    };
    self.downloadProgress = ^(NSProgress * _Nonnull progress, CGFloat speed) {
        Strong;
        NSArray *array = self.requests.copy;
        for (XPBaseRequest *request in array) {
            if (request.downloadProgress) {
                request.downloadProgress(progress, speed);
            }
        }
    };
}
- (void)dealloc
{
    [self.requests removeAllObjects];
    [self.cancelRequests removeAllObjects];
    [self.cancelRequests removeAllObjects];
}
#pragma mark - 同步设置 -
- (void)setProgress:(NSProgress *)progress{
    if (!self.uploadProgress && !self.downloadProgress) {
        return;
    }
    NSTimeInterval current = CACurrentMediaTime();
    if (self.currentTime == 0) {
        self.currentTime = CACurrentMediaTime();
        self.currentCount = progress.completedUnitCount;
    }else{
        if (current - self.currentTime >= 0.3) {
            NSUInteger count = progress.completedUnitCount;
            self.speed = (count - self.currentCount)/0.3;
            self.currentCount = count;
            self.currentTime = current;
        }
        if (self.uploadProgress) {
            self.uploadProgress(progress, progress.fractionCompleted == 1?0: self.speed);
        }else if (self.downloadProgress){
            self.downloadProgress(progress, progress.fractionCompleted == 1?0: self.speed);
        }
    }
    if (progress.fractionCompleted == 1) {
        self.currentTime = 0;
        self.speed = 0;
        self.currentTime = 0;
    }
}

- (NSURLSessionTask *)task{
    return self.currentRequest.requestTask;
}
- (void)setRequestData{
    XPBaseRequest *request = self.currentRequest;
    NSArray *array = @[@"responseJSONObject",@"responseData",@"responseString",@"originalResponseObject"];
    for (XPBaseRequest *otherRequest in self.requests) {
        if (otherRequest == request) continue;
        for (NSString *key in array) {
            id value = [request valueForKey:key];
            if (value) {
                [otherRequest setValue:value forKey:key];
            }
        }
    }
    [self packageCacheData];
}
#pragma mark - 懒加载 -
/**
 懒加载
 */
- (NSMutableArray<XPBaseRequest *> *)requests{
    if (!_requests) {
        _requests = [NSMutableArray array];
    }
    return _requests;
}
- (NSMutableArray<XPBaseRequest *> *)cancelRequests{
    if (!_cancelRequests) {
        _cancelRequests = [NSMutableArray array];
    }
    return _cancelRequests;
}
- (NSMutableArray<XPBaseRequest *> *)cacheRequests{
    if (!_cacheRequests) {
        _cacheRequests = [NSMutableArray array];
    }
    return _cacheRequests;
}
- (XPRequestPackageCache *)packageCache{
    
    if (!_packageCache) {
        _packageCache = [XPRequestPackageCache new];
        _packageCache.delegate = self;
    }
    return _packageCache;
}
- (NSString *)fullUrl{
    if (!_fullUrl) {
        XPBaseRequest *request = [_requests firstObject];
        _fullUrl = [XPRequestTool fullUrlPathWithRequest:request];
    }
    return _fullUrl;
}

- (void)packageFinish:(XPBaseRequest *)request{
    BOOL canBack = self.isFinish && self.unloadCacheCount == self.loadedCacheCount && ((self.packageCache.queryStatus == XPCacheQuery_Finish && self.loadedCacheCount > 0) || (self.packageCache.status == XPRequestStatus_noCache));
    
    if (canBack || self.isSuccess) {
        if ([self.delegate respondsToSelector:@selector(uniqueRequestFinished:)]) {
            [self.delegate uniqueRequestFinished:request];
        }
    }
}

#pragma mark - Cache代理 -

- (void)queryFinshWithData:(XPBaseRequest *)request{
    if (self.isSuccess) {
        return;
    }
    Lock();
    NSArray *array = self.cacheRequests.copy;
    Unlock();
    for (XPBaseRequest *obj in array) {
        [self loadCacheData:obj];
    }
}

- (void)packageCacheData{
    _packageCache.request = self.currentRequest;
    [_packageCache saveData];
}
@end

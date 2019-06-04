//
//  XPRequestCategory.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/2.
//

#import "XPRequestCategory.h"
@implementation XPBaseRequest(RequestAccessory)

- (void)requestWillStartCallBack:(XPBaseRequest *)request{
    
}
- (void)requestDidStopCallBack:(XPBaseRequest *)request{
    
}
- (void)requestWillStopCallBack:(XPBaseRequest *)request{
    
}
- (void)requestDidError{
    
    if (self.cacheType == 0) {
        self.responseObject = nil;
    }
    if (self.uniqueDelegate) {
        if ([self.uniqueDelegate respondsToSelector:@selector(requestFailed:)]) {
            [self.uniqueDelegate requestFailed:self];
        }
    }else if (self.delegate){
        [self requestFailDealWithRequest:self];
    }
}
- (void)requestDidSuccess{
    self.uniqueDelegate.isSuccess = YES;
    self.error = nil;
    if (self.uniqueDelegate) {
        if ([self.uniqueDelegate respondsToSelector:@selector(requestSuccessed:)]) {
            [self.uniqueDelegate requestSuccessed:self];
        }
    }else{
        [self requestSuccessDealWithRequest:self];
    }
}
- (BOOL)isCacheStatusValid{
    return self.cacheType > 0 && self.cacheType < 3;
}
//请求完成处理
- (void)requestFailDealWithRequest:(XPBaseRequest *)request{
    self.runningStaus = XPRequestRunningStatus_finish_Failure;
    NSLog(@"错误：：request::::%@, %@",[self.fullUrl lastPathComponent], request.error);
    @autoreleasepool{
        [self requestFailedPreprocessor:self];
    }
    dispatch_queue_t queue;
    if (self.queue) {
        queue = self.queue;
    }else{
        queue = dispatch_get_main_queue();
    }
    dispatch_async(queue, ^{
        [self requestWillStopCallBack:self];
        
        [self requestFailedFilter:self];
        
        if (self.failure) {
            self.failure(self);
        }
        if ([self.delegate respondsToSelector:@selector(requestFailed:)]) {
            [self.delegate requestFailed:self];
        }
        [self requestDidStopCallBack:self];
        
        [self clearCompletionBlock];
    });
}
- (void)requestCancelDeal{
    //    NSLog(@"取消：：request::::%@",[obj.fullUrl lastPathComponent]);
    self.runningStaus = XPRequestRunningStatus_finish_Cancel;
    @autoreleasepool{
        [self requestCancelledPreprocessor:self];
    }
    dispatch_queue_t queue;
    if (self.queue) {
        queue = self.queue;
    }else{
        queue = dispatch_get_main_queue();
    }
    dispatch_async(queue, ^{
        [self requestWillStopCallBack:self];
        [self requestCancelledFilter:self];
        if (self.cancel) {
            self.cancel(self);
        }
        if ([self.delegate respondsToSelector:@selector(requestCancelled:)]) {
            [self.delegate requestCancelled:self];
        }
        [self requestDidStopCallBack:self];
        [self clearCompletionBlock];
        
    });
}
- (void)requestSuccessDealWithRequest:(XPBaseRequest *)request{
    self.runningStaus = XPRequestRunningStatus_finish_Success;
    @autoreleasepool{
        [self requestSuccessPreprocessor:self];
    }
    dispatch_queue_t queue;
    if (self.queue) {
        queue = self.queue;
    }else{
        queue = dispatch_get_main_queue();
    }
    dispatch_async(queue, ^{
        [self requestWillStopCallBack:self];
        [self requsetSuccessFilter:self];
        if (self.customData) {
            self.responseObject = self.customData(self.originalResponseObject);
        }else{
            self.responseObject = self.originalResponseObject;
        }
        if (self.sucess) {
            self.sucess(self);
        }
        if ([self.delegate respondsToSelector:@selector(requestSuccessed:)]) {
            [self.delegate requestSuccessed:self];
        }
        [self requestDidStopCallBack:self];
        [self clearCompletionBlock];
        
    });
}

@end


@implementation XPBatchRequest(RequestAccessory)
- (void)requestWillStartCallBack:(XPBaseRequest *)request{
    
}
- (void)requestDidStopCallBack:(XPBaseRequest *)request{
    
}
- (void)requestWillStopCallBack:(XPBaseRequest *)request{
    
}
@end
@implementation XPBaseRequest (chain)

- (XPBaseRequest *(^)(NSString *))xbaseUrl{
    Weak;
    return ^(NSString *baseUrl){
        Strong;
        self.baseUrl = baseUrl;
        return self;
    };
}

- (XPBaseRequest *(^)(NSString *))xroute{
    Weak;
    return ^(NSString *route){
        Strong;
        self.route = route;
        return self;
    };
}
- (XPBaseRequest *(^)(NSString *))xpath{
    Weak;
    return ^(NSString *path){
        Strong;
        self.path = path;
        return self;
    };
}
-(XPBaseRequest *(^)(XPRequestMethod))xmethod{
    Weak;
    return ^(XPRequestMethod method){
        Strong;
        self.method = method;
        return self;
    };
}
- (XPBaseRequest *(^)(dispatch_queue_t))xqueue{
    Weak;
    return ^(dispatch_queue_t queue){
        Strong;
        self.queue = queue;
        return self;
    };
}
- (XPBaseRequest *(^)(NSString *))xdownLoadPath{
    Weak;
    return ^(NSString *downLoadPath){
        Strong;
        self.downloadPath = downLoadPath;
        return self;
    };
}
- (XPBaseRequest *(^)(NSDictionary *))xparasConvert{
    Weak;
    return ^(NSDictionary *parasConvert){
        Strong;
        self.parasConvert = parasConvert;
        return self;
    };
}
- (XPBaseRequest *(^)(NSInteger))xuniqueIdentity{
    Weak;
    return ^(NSInteger tag){
        Strong;
        self.uniqueIdentity = tag;
        return self;
    };
}
- (XPBaseRequest *(^)(CGFloat))xuniqueTimeOut{
    Weak;
    return ^(CGFloat time){
        Strong;
        self.uniqueTimeOut = time;
        return self;
    };
}
- (XPBaseRequest *(^)(NSTimeInterval))xmemoryTime{
    Weak;
    return ^(NSTimeInterval time){
        Strong;
        self.memoryCacheTime = time;
        return self;
    };
}
- (XPBaseRequest *(^)(NSTimeInterval))xdiskTime{
    Weak;
    return ^(NSTimeInterval time){
        Strong;
        self.diskCacheTime = time;
        return self;
    };
}
- (XPBaseRequest *(^)(AFSecurityPolicy *))xsecurity{
    Weak;
    return ^(AFSecurityPolicy *policy){
        Strong;
        self.securityPolicy = policy;
        return self;
    };
}
- (XPBaseRequest *(^)(NSString *))xcacheName{
    Weak;
    return ^(NSString *name){
        Strong;
        self.cacheName = name;
        return self;
    };
}
- (XPBaseRequest *(^)(XPCacheResultStatus))xlegalStatus{
    Weak;
    return ^(XPCacheResultStatus status){
        Strong;
        self.cacheStatus = status;
        return self;
    };
}
- (XPBaseRequest *(^)(BOOL))xloadCacheWhenFirstStart{
    Weak;
    return ^(BOOL loadCacheWhenFirstStart){
        Strong;
        self.loadCacheWhenFirstStart = loadCacheWhenFirstStart;
        return self;
    };
}
- (XPBaseRequest *(^)(xdata))xcustomData{
    Weak;
    return ^(xdata data){
        Strong;
        self.customData = data;
        return self;
    };
}
- (XPBaseRequest *(^)(xpara))xpara{
    Weak;
    return ^(xpara para){
        Strong;
        if (para) {
            para(self.params);
        }
        return self;
    };
}

@end

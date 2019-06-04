

//
//  XPBatchRequest.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/4/30.
//

#import "XPBatchRequest.h"
#import "XPBaseRequest.h"
#import "XPRequestCategory.h"
#import <pthread/pthread.h>
#import "XPBatchRequestManager.h"
#import "XPBaseRequest.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)
@interface XPBatchRequest ()<XPRequestDelegate>{
    NSInteger _finishedCount;
    BOOL _isStart;
    NSInteger _cacheCount;
    BOOL _isfinish;
    pthread_mutex_t _lock;
}
/**
 请求列表
 */
@property (nonatomic, strong) NSMutableArray <XPBaseRequest *>* requests;

@property (nonatomic, assign) BOOL  isCacheData;

@property (nonatomic, strong) NSMutableArray <NSNumber *>* cancelRequests;

@property (nonatomic, strong) NSMutableArray <XPBaseRequest *> * finishedCacheRequests;
/**
 请求成功的index
 */
@property (nonatomic, strong) NSMutableArray <NSNumber *>* successRequests;

/**
 请求失败的index
 */
@property (nonatomic, strong) NSMutableArray <NSNumber *>* failRequests;

@end
@implementation XPBatchRequest

//初始化
- (XPBatchRequest *)initWithRequest:(NSArray *)requests{
    XPBatchRequest *request = [self init];
    [request addRequestArray:requests];
    return request;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        _finishedCount = 0;
        _cacheCount = 0;
    }
    return self;
}
- (void)addRequestArray:(NSArray<XPBaseRequest *> *)requestArray{
    if (requestArray.count == 0 || ![requestArray isKindOfClass:[NSArray class]]) {
        return;
    }
    [self.requests addObjectsFromArray:requestArray];
    
}
- (void)addRequest:(XPBaseRequest *)request{
    [self.requests addObject:request];
}

- (void)startCompletionBlockWithSuccess:(XPBatchResultBlock)completeBlock{
    [self setCompleteBlock:completeBlock];
    [self start];
}

- (void)start{
    if (_isStart) {
        NSLog(@"batchRequest请求已经开始了");
        return;
    }
    if (self.requests.count == 0) {
        [self batchNetWorkComplete];
        return;
    }
    _isfinish = NO;
    _isStart = YES;
    _cacheCount = 0;
    [[XPBatchRequestManager shareManager] addBatchRequest:self];
    [self.finishedCacheRequests removeAllObjects];
    [self.failRequests removeAllObjects];
    [self.successRequests removeAllObjects];
    for (XPBaseRequest *request in _requests) {
        request.delegate = self;
        if ([request isCacheStatusValid]) {
            _cacheCount ++;
        }
        [request start];
    }
}

- (void)stop{
    [self clearRequest];
    [[XPBatchRequestManager shareManager] removeRequest:self];
}
- (void)setCompletionBlockWithSuccess:(XPBatchResultBlock)completeBlock{
    self.completeBlock = completeBlock;
}
- (void)clearCompletionBlock{
    self.completeBlock = nil;
}

- (void)dealloc
{
//    [self clearRequest];
    [self clearCompletionBlock];
//    NSLog(@"batchRequest销毁了");
}
- (void)clearRequest{
    for (XPBaseRequest *request in self.requests) {
        [request stop];
    }
}

#pragma mark - XPRequestDelegate -
- (void)requestFailed:(__kindof XPBaseRequest *)request{
    _finishedCount ++;
    Lock();
    [self.failRequests addObject:@([_requests indexOfObject:request])];
    Unlock();
    if (_finishedCount == _requests.count) {
        _isfinish = YES;
        [self batchCompleteAndRemove];
    }
    
    [self cacheRequestIsAdd:YES request:request];
}
- (void)requestCancelled:(__kindof XPBaseRequest *)request{
    _finishedCount ++;
    Lock();
    [self.cancelRequests addObject:@([_requests indexOfObject:request])];
    Unlock();
    if (_finishedCount == _requests.count) {
        _isfinish = YES;
        [self batchCompleteAndRemove];
    }
    
   [self cacheRequestIsAdd:NO request:request];
}
- (void)requestSuccessed:(__kindof XPBaseRequest *)request{
    
    _finishedCount ++;
    Lock();
    [self.successRequests addObject:@([_requests indexOfObject:request])];
    Unlock();
    if (_finishedCount == _requests.count) {
        _isfinish = YES;
        [self batchCompleteAndRemove];
    }
    
    [self cacheRequestIsAdd:YES request:request];
}

- (void)batchCompleteAndRemove{
    [self batchComplete];
    [[XPBatchRequestManager shareManager] removeRequest:self];
}
- (void)batchComplete{
    
        if (_completeBlock) {
            _completeBlock(self);
        }
        if ([_delegate respondsToSelector:@selector(batchRequestcomplete:)]) {
            [_delegate batchRequestcomplete:self];
        }
    
    
}
- (void)batchNetWorkComplete{
    [self batchComplete];
    _isStart = NO;
}

#pragma mark - Cache -
- (void)requestFirstCacheLoaded:(__kindof XPBaseRequest *)request{
    
    [self cacheRequestIsAdd:YES request:request];
}
- (void)batchCacheComplete{
    self.isCacheData = YES;
    [self batchComplete];
    self.isCacheData = NO;
}

- (void)cacheRequestIsAdd:(BOOL)isAdd request:(XPBaseRequest *)request{
    if (_isfinish) return;
    if (![request isCacheStatusValid]) return;
    Lock();
    BOOL isContain = [self.finishedCacheRequests containsObject:request];
    Unlock();
    if (isAdd) {
        if (isContain) return;
        Lock();
        [self.finishedCacheRequests addObject:request];
        Unlock();
    }else{
        if (!isContain) return;
        Lock();
        [self.finishedCacheRequests removeObject:request];
        Unlock();
        _cacheCount --;
    }
    if (_cacheCount == self.finishedCacheRequests.count) {
        [self batchCacheComplete];
    }
}

//懒加载
- (NSMutableArray<XPBaseRequest *> *)requests{
    if (!_requests) {
        _requests = [NSMutableArray array];
    }
    return _requests;
}
- (NSMutableArray<NSNumber *> *)successRequests{
    if (!_successRequests) {
        _successRequests = [NSMutableArray array];
    }
    return _successRequests;
}
- (NSMutableArray<NSNumber *> *)failRequests{
    if (!_failRequests) {
        _failRequests = [NSMutableArray array];
    }
    return _failRequests;
}
- (NSMutableArray<NSNumber *> *)cancelRequests{
    if (!_cancelRequests) {
        _cancelRequests = [NSMutableArray array];
    }
    return _cancelRequests;
}
- (NSMutableArray<XPBaseRequest *> *)finishedCacheRequests{
    if (!_finishedCacheRequests) {
        _finishedCacheRequests = [NSMutableArray array];
    }
    return _finishedCacheRequests;
}
@end


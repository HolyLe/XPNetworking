//
//  XPChainRequest.m
//  WisdomMember
//
//  Created by 麻小亮 on 2018/6/19.
//  Copyright © 2018年 ABLE. All rights reserved.
//

#import "XPChainRequest.h"
#import "XPBatchRequestManager.h"
#import "XPBaseRequest.h"
@interface XPChainRequest ()<XPRequestDelegate>{
    NSInteger  _currentIndex;
}
/**
 请求列表
 */
@property (nonatomic, strong) NSMutableArray <XPBaseRequest *>* requests;


@property (nonatomic, strong) NSMutableArray <NSNumber *>* cancelRequests;
/**
 请求成功的index
 */
@property (nonatomic, strong) NSMutableArray <NSNumber *>* successRequests;

/**
 请求失败的index
 */
@property (nonatomic, strong) NSMutableArray <NSNumber *>* failRequests;

@end


@implementation XPChainRequest

- (instancetype)initWithRequests:(NSArray<XPBaseRequest *> *)requests
{
    XPChainRequest *request = [self init];
    [request addRequests:requests];
    return request;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.tag = 0;
        _currentIndex = -1;
        self.isWillFinished = YES;
    }
    return self;
}
- (void)addRequests:(NSArray<XPBaseRequest *> *)requests
{
    if ([XPRequestTool isBlank:requests]) {
        return;
    }
    [self.requests addObjectsFromArray:requests];
}

- (void)addRequest:(XPBaseRequest *)request{
    [self.requests addObject:request];
}

- (void)start{
    if (_currentIndex > - 1) {
        NSLog(@"chainRequestStart");
        return;
    }
    if (_requests.count > 0) {
        if ([self startNextRequest]) {
            [[XPChainRequestManager shareManager] addChainRequest:self];
            return;
        }
    }
    [self chainComplete];
}


- (void)stop{
    [self clearRequest];
    [[XPChainRequestManager shareManager] removeRequest:self];
}
- (void)setCompletionBlockWithSuccess:(XPChainResultBlock)completeBlock{
    self.completeBlock = completeBlock;
}
- (void)startCompletionBlockWithSuccess:(XPChainResultBlock)completeBlock{
    [self setCompletionBlockWithSuccess:completeBlock];
    [self start];
}

- (void)chainCompleteAndRemove{
    [self chainComplete];
    [[XPChainRequestManager shareManager] removeRequest:self];
}

- (void)chainComplete{
    if ([_delegate respondsToSelector:@selector(chainRequestcomplete:)]) {
        [_delegate chainRequestcomplete:self];
    }
    if (_completeBlock) {
        _completeBlock(self);
    }
    _currentIndex = -1;
}

- (void)dealloc{
//    [self clearRequest];
    [self clearCompletionBlock];
//    NSLog(@"chainRequest销毁了");
}

- (void)clearCompletionBlock{
    self.completeBlock = nil;
}
- (void)clearRequest {
    if (_currentIndex < _requests.count) {
        XPBaseRequest *request = _requests[_currentIndex];
        [request stop];
    }
}

- (BOOL)startNextRequest{
    if (!_isWillFinished) {
        _isWillFinished = YES;
        if (_currentIndex + 1 < _requests.count) {
            _currentIndex ++;
            XPBaseRequest *request = _requests[_currentIndex];
            request.delegate = self;
            [request start];
            return YES;
        }
    }
    [self chainComplete];
    return NO;
}

#pragma mark - RequestDelegate -

- (void)requestFailed:(__kindof XPBaseRequest *)request{
    [self.failRequests addObject:@([_requests indexOfObject:request])];
    if (![self startNextRequest]) {
        [[XPChainRequestManager shareManager] removeRequest:self];
    }
}

- (void)requestCancelled:(__kindof XPBaseRequest *)request{
    [self.cancelRequests addObject:@([_requests indexOfObject:request])];
    if (![self startNextRequest]) {
        [[XPChainRequestManager shareManager] removeRequest:self];
    }
}

- (void)requestSuccessed:(__kindof XPBaseRequest *)request{
    [self.successRequests addObject:@([_requests indexOfObject:request])];
    if (![self startNextRequest]) {
        [[XPChainRequestManager shareManager] removeRequest:self];
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
@end

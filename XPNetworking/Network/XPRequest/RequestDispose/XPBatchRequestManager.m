//
//  XPBatchRequestManager.m
//  WisdomMember
//
//  Created by 麻小亮 on 2018/7/6.
//  Copyright © 2018年 ABLE. All rights reserved.
//

#import "XPBatchRequestManager.h"
#import <pthread/pthread.h>
#import "XPChainRequest.h"
#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface XPBatchRequestManager (){
    pthread_mutex_t _lock;
}
@property (nonatomic, strong) NSMutableArray * batchRequests;
@end
static XPBatchRequestManager *_batchRequestManager = nil;
@implementation XPBatchRequestManager
+ (XPBatchRequestManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _batchRequestManager = [XPBatchRequestManager new];
    });
    return _batchRequestManager;
}
- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}
- (NSMutableArray *)batchRequests{
    if (!_batchRequests) {
        _batchRequests = [NSMutableArray array];
    }
    return _batchRequests;
}

- (void)addBatchRequest:(XPBatchRequest *)request{
    [self.batchRequests addObject:request];
}
- (void)removeRequest:(XPBatchRequest *)request{
    [self.batchRequests removeObject:request];
}
@end
@interface XPChainRequestManager (){
    pthread_mutex_t _lock;
}
@property (nonatomic, strong) NSMutableArray * chainRequests;
@property (nonatomic, strong) NSMutableArray * tags;
@end
static XPChainRequestManager *_chainRequestManager = nil;
@implementation XPChainRequestManager
+ (XPChainRequestManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _chainRequestManager = [XPChainRequestManager new];
    });
    return _chainRequestManager;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}
- (NSMutableArray *)chainRequests{
    if (!_chainRequests) {
        _chainRequests = [NSMutableArray array];
    }
    return _chainRequests;
}
- (NSMutableArray *)tags{
    if (!_tags) {
        _tags = [NSMutableArray array];
    }
    return _tags;
}
- (void)addChainRequest:(XPChainRequest *)request{
    Lock();
    if (request.tag != 0) {
        NSNumber *tag = @(request.tag);
        if ([self.tags containsObject:tag]) {
            return;
        }else{
            [self.tags addObject:tag];
        }
    }
    [self.chainRequests addObject:request];
    Unlock();
}
- (void)removeRequest:(XPChainRequest *)request{
    Lock();
    if (request.tag != 0) {
        [self.tags removeObject:@(request.tag)];
    }
    [self.chainRequests removeObject:request];
    Unlock();
}
@end

//
//  XPChainRequest.h
//  WisdomMember
//
//  Created by 麻小亮 on 2018/6/19.
//  Copyright © 2018年 ABLE. All rights reserved.
//

#import <Foundation/Foundation.h>


@class XPBaseRequest, XPChainRequest;
@protocol XPChainRequestDelegate <NSObject>
@optional
- (void)chainRequestcomplete:(XPChainRequest *)chainRequest;
@end

typedef void (^ XPChainResultBlock) (XPChainRequest *chainRequest);
@interface XPChainRequest : NSObject

/**
 设置为YES，将会结束请求
 */
@property (nonatomic, assign) BOOL  isWillFinished;

/**
 请求列表
 */
@property (nonatomic, strong, readonly) NSMutableArray <XPBaseRequest *>* requests;

/**
 请求成功的index
 */
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *>* successRequests;


/**
 唯一标记，默认为0，若不为零则相同tag值得请求队列结束时才能进行下一个
 */
@property (nonatomic, assign) NSInteger  tag;
/**
 请求失败的index
 */
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *>* failRequests;


@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *>* cancelRequests;

@property (nonatomic, copy) XPChainResultBlock completeBlock;

@property (nonatomic, weak) id <XPChainRequestDelegate> delegate;

- (void)addRequest:(XPBaseRequest *)request;

- (instancetype)initWithRequests:(NSArray <XPBaseRequest *>*)requests;

- (void)addRequests:(NSArray <XPBaseRequest *>*)requests;

- (void)stop;

- (void)start;

- (void)clearCompletionBlock;

/**
 开始并回调
 */
- (void)startCompletionBlockWithSuccess:(XPChainResultBlock)completeBlock;
/**
 完成回调
 */
- (void)setCompletionBlockWithSuccess:(XPChainResultBlock)completeBlock;

@end

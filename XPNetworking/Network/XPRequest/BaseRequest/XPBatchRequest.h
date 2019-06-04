//
//  XPBatchRequest.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/4/30.
//

#import <Foundation/Foundation.h>
@class XPBatchRequest, XPBaseRequest;
/*
 请求多线程管理
 */
typedef void(^XPBatchResultBlock)(XPBatchRequest *batchRequest);


@protocol XPBatchRequestDelegate <NSObject>
@optional
- (void)batchRequestcomplete:(XPBatchRequest *)batchRequest;
@end
@interface XPBatchRequest : NSObject

- (XPBatchRequest *)initWithRequest:(NSArray *)requests;


/**
 请求列表
 */
@property (nonatomic, strong, readonly) NSMutableArray <XPBaseRequest *>* requests;

@property (nonatomic, weak) id <XPBatchRequestDelegate> delegate;

/**
 请求成功的index
 */
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *>* successRequests;

/**
 请求失败的index
 */
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *>* failRequests;

@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *>* cancelRequests;

@property (nonatomic, assign, readonly) BOOL  isCacheData;

@property (nonatomic, copy) XPBatchResultBlock completeBlock;
/**
 添加请求
 */
- (void)addRequest:(XPBaseRequest *)request;

/**
 添加请求列表
 */
- (void)addRequestArray:(NSArray <XPBaseRequest *>*)requestArray;


/**
 开始并回调
 */
- (void)startCompletionBlockWithSuccess:(XPBatchResultBlock)completeBlock;
/**
 完成回调
 */
- (void)setCompletionBlockWithSuccess:(XPBatchResultBlock)completeBlock;

/**
 开始
 */
- (void)start;
/**
 停止
 */
- (void)stop;

/**
 清空回调
 */
- (void)clearCompletionBlock;

@end



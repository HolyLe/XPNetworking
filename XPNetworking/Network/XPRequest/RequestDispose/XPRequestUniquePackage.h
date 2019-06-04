//
//  XPRequestUniquePackage.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/7.
//

#import <Foundation/Foundation.h>
#import "XPRequestSessionManager.h"

@protocol XPRequestPackageDelegate <NSObject>
- (void)uniqueRequestFinished:(XPBaseRequest *)request;
- (void)startRequestWithRequest:(XPBaseRequest *)request index:(NSInteger)index;
@end

@interface XPRequestUniquePackage : NSObject

@property (nonatomic, strong, readonly) NSMutableArray <XPBaseRequest *> * requests;
@property (nonatomic, assign, readonly) NSInteger  currentIndex;
@property (nonatomic, weak) id <XPRequestPackageDelegate> delegate;
@property (nonatomic, strong, readonly) XPBaseRequest * currentRequest;

//------------共同的数据

/**
 请求任务
 */
@property (nonatomic, strong) NSURLSessionTask * task;
/**
 请求结果二进制
 */
@property (nonatomic, strong) NSData *responseData;


/**
 请求结果字符串
 */
@property (nonatomic, strong) NSString *responseString;

/**
 请求的结果
 */
@property (nonatomic, strong) id responseObject;

/**
 请求原始
 */
@property (nonatomic, strong) id originalResponseObject;

/**
 请求结果的json对象
 */
@property (nonatomic, strong) id responseJSONObject;

@property (nonatomic, copy) XPURLSessionTaskProgressBlock  uploadProgress;

@property (nonatomic, copy) XPURLSessionTaskProgressBlock  downloadProgress;

/**
 网络请求错误信息
 */
@property (nonatomic, strong) NSError * error;

//上传或下载速度,字节为单位
@property (nonatomic, assign) CGFloat  speed;

- (void)setProgress:(NSProgress *)progress;

- (void)setRequestData;
//-------------------------------------------------------
/**
 请求是否成功
 */
@property (nonatomic, assign) BOOL  isSuccess;
/**
 url完整地址
 */
@property (nonatomic, copy) NSString * fullUrl;

/**
 添加请求
 */
- (void)addRequest:(XPBaseRequest *)request;

/**
 移除请求
 */
- (void)removeRequest:(XPBaseRequest *)request;


/**
 移除整个请求包
 */
- (void)removeRequestPackage;

- (void)packageFinish:(XPBaseRequest *)request;

@end

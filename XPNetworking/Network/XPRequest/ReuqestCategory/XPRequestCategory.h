//
//  XPRequestCategory.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/2.
//

#import <Foundation/Foundation.h>
#import "XPBaseRequest.h"
#import "XPBatchRequest.h"
#import "XPRequestUniquePackage.h"

typedef id(^xdata)(id data);
typedef void(^xpara)(NSMutableDictionary *params);

@interface XPBaseRequest (Setter)
@property (nonatomic, strong, readwrite) NSData *responseData;

@property (nonatomic, strong, readwrite) id responseJSONObject;

@property (nonatomic, strong, readwrite) id responseObject;

@property (nonatomic, strong, readwrite) NSString *responseString;

@property (nonatomic, strong, readwrite) NSError *error;

@property (nonatomic, strong, readwrite) NSURLSessionTask * requestTask;

@property (nonatomic, assign, readwrite) XPRequestRunningStatus runningStaus;

@property (nonatomic, strong, readwrite) id originalResponseObject;



@property (nonatomic, assign, readwrite) CGFloat  speed;

@property (nonatomic, assign, readwrite) BOOL  isCacheData;
@end

@interface XPRequestUniquePackage (Set)
- (void)packageCacheData;
@end
@interface XPBaseRequest (RequestAccessory)
- (void)requestWillStartCallBack:(XPBaseRequest *)request;
- (void)requestWillStopCallBack:(XPBaseRequest *)request;
- (void)requestDidStopCallBack:(XPBaseRequest *)request;
//请求失败
- (void)requestDidSuccess;
//请求成功
- (void)requestDidError;

/**
 是否是需要缓存
 */
- (BOOL)isCacheStatusValid;
//请求完成处理
- (void)requestFailDealWithRequest:(XPBaseRequest *)request;
- (void)requestCancelDeal;
- (void)requestSuccessDealWithRequest:(XPBaseRequest *)request;

@end

@interface XPBatchRequest (RequestAccessory)

- (void)requestWillStartCallBack:(XPBaseRequest *)request;
- (void)requestWillStopCallBack:(XPBaseRequest *)request;
- (void)requestDidStopCallBack:(XPBaseRequest *)request;
@end


@interface XPBaseRequest (chain)
- (XPBaseRequest *(^)(NSString *))xbaseUrl;
- (XPBaseRequest *(^)(NSString *))xroute;
- (XPBaseRequest *(^)(NSString *))xpath;
- (XPBaseRequest *(^)(XPRequestMethod))xmethod;
- (XPBaseRequest *(^)(dispatch_queue_t))xqueue;
- (XPBaseRequest *(^)(NSString *))xdownLoadPath;
- (XPBaseRequest *(^)(NSDictionary *))xparasConvert;
- (XPBaseRequest *(^)(NSInteger))xuniqueIdentity;
- (XPBaseRequest *(^)(CGFloat))xuniqueTimeOut;
- (XPBaseRequest *(^)(NSTimeInterval))xmemoryTime;
- (XPBaseRequest *(^)(NSTimeInterval))xdiskTime;
- (XPBaseRequest *(^)(AFSecurityPolicy *))xsecurity;
- (XPBaseRequest *(^)(NSString *))xcacheName;
- (XPBaseRequest *(^)(XPCacheResultStatus))xlegalStatus;
- (XPBaseRequest *(^)(BOOL))xloadCacheWhenFirstStart;
- (XPBaseRequest *(^)(xdata))xcustomData;
- (XPBaseRequest *(^)(xpara))xpara;
@end

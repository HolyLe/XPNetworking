//
//  XPRequestSessionManager.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/4.
//

#import <Foundation/Foundation.h>
#import "XPBaseRequest.h"
#import "XPRequestConfiguration.h"
@interface XPRequestSessionManager : NSObject
+ (XPRequestSessionManager *)shareManager;
@property (nonatomic, strong) XPRequestConfiguration * configuration;

@property (nonatomic, strong, readonly) AFHTTPSessionManager * manager;

/**
 开始一个请求
 */

- (NSURLSessionTask *)startWithRequest:(XPBaseRequest *)request;

- (void)cancelWithRequest:(XPBaseRequest *)request;

- (NSString *)requestCacheKey:(XPBaseRequest *)request;

@end

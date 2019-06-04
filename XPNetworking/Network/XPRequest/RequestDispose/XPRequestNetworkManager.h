//
//  XPRequestNetworkManager.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/7.
//

#import <Foundation/Foundation.h>
#import "XPRequestConfiguration.h"
@class XPBaseRequest, XPRequestConfiguration;
typedef void(^configure)(XPRequestConfiguration *configure);
@interface XPRequestNetworkManager : NSObject


+ (XPRequestNetworkManager *)shareManager;

@property (nonatomic, strong, readonly) XPRequestConfiguration * configuration;

/**
 配置项目

 */
- (void)configuredProject:(configure)configure;

/**
 添加请求
 */
- (void)addRequest:(XPBaseRequest *)request;

/**
 取消请求
 */
- (void)cancelRequest:(XPBaseRequest *)request;

/**
 取消所有请求
 */
- (void)cancelAllRequest;

- (void)cacelRequestPackage:(XPBaseRequest *)request;


@end

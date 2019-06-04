//
//  XPRequestConfiguration.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/7.
//

#import <Foundation/Foundation.h>
#import "XPRequestDefines.h"
NS_ASSUME_NONNULL_BEGIN
@class AFSecurityPolicy;
@interface XPRequestConfiguration : NSObject

/**
 请求超时时间
 */
@property (nonatomic, assign) NSTimeInterval  timeOut;


/**
 请求格式
 */
@property (nonatomic, assign) XPRequestSerializerType  requestSerializerType;


/**
 有效的requestCode范围
 */
@property (nonatomic, strong) NSIndexSet * validStatusCodes;
/**
 响应格式
 */
@property (nonatomic, assign) XPResponseSerializerType  responseSerializerType;

/**
 证书
 */
@property (nonatomic, strong, nullable) AFSecurityPolicy * securityPolicy;

/**
 manager配置
 */
@property (nonatomic, strong) NSURLSessionConfiguration * managerConfiguration;

/**
 
 */
@property (nonatomic, strong) NSDictionary * headerFieldValueDictionary;
/**
 是否打印日志
 */
@property (nonatomic, assign) BOOL  canPrintLog;


/**
 自动清理时长
 */
@property (nonatomic, assign) NSTimeInterval  autoTrimInterval;
@end
NS_ASSUME_NONNULL_END

//
//  XPRequestDefines.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/7.
//

#ifndef XPRequestDefines_h
#define XPRequestDefines_h
#import "XPRequestTool.h"
#import "XPCache.h"
#import <QuartzCore/QuartzCore.h>
#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(FORMAT, ...) nil
#endif

#ifndef Weak
#define Weak  __weak __typeof(self) weakSelf = self
#endif

#ifndef Strong
#define Strong  __strong __typeof(weakSelf) self = weakSelf
#endif

typedef id(^xdata)(id data);
typedef void(^xpara)(NSMutableDictionary *params);

#pragma mark - Enum -


/**
 请求方式
 */
typedef NS_ENUM(NSUInteger, XPRequestMethod) {
    XPRequestPost = 0,
    XPRequestGet,
    XPRequestPut,
    XPRequestHead,
    XPRequestDelete,
    XPRequestPatch
};

typedef NS_ENUM(NSUInteger, XPRequestSerializerType){
    XPRequestSerializerTypeHTTP = 0,
    XPRequestSerializerTypeJSON
};

typedef NS_ENUM(NSInteger, XPResponseSerializerType) {
    XPResponseSerializerTypeJSON = 0,
    XPResponseSerializerTypeXMLParser = 1,
    XPResponseSerializerTypeHTTP = 2
};
typedef NS_ENUM(NSInteger, XPRequestValidError) {
    XPRequestValidErrorStatusCode = -8,
    XPRequestValidErrorJsonFormat = -9,
    XPRequestValidErrorUrlFormat = -10,
    XPRequestValidErrorUniquedFormat = -11
};
typedef NS_ENUM(NSInteger, XPRequestRunningStatus) {
    XPRequestRunningStatus_unStart = 0,//未开始
    XPRequestRunningStatus_running,//请求中-单
    XPRequestRunningStatus_finish_Success,//请求成功
    XPRequestRunningStatus_finish_Failure,//请求失败
    XPRequestRunningStatus_finish_Cancel,
    
};
#endif /* XPRequestDefines_h */

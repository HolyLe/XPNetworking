//
//  XPRequestTool.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/9.
//

#import <Foundation/Foundation.h>
@class XPBaseRequest;


@interface XPRequestTool : NSObject

+ (NSStringEncoding)stringEncodingWithRequest:(XPBaseRequest *)request;

+ (NSString *)fullUrlPathWithRequest:(XPBaseRequest *)request;

+ (NSString *)jsonURLStringWithRequest:(XPBaseRequest *)request;

+ (NSString *)urlPathWithRequest:(XPBaseRequest *)request;

+ (NSDictionary *)paraConvetFromDic:(NSDictionary *)parameters withConvert:(NSDictionary *)convertDic;

+ (NSString *)requestCacheKey:(XPBaseRequest *)request;

+ (NSString *)md5StringFromString:(NSString *)string;

+ (BOOL)validateResumeData:(NSData *)data;

+ (BOOL)isBlank:(id)obj;
@end



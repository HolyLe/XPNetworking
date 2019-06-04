//
//  XPRequestTool.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/9.
//

#include <CommonCrypto/CommonCrypto.h>
#include <zlib.h>
#import "XPRequestTool.h"
#import "XPBaseRequest.h"
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif
static id objectToJsonObjectRecursive(NSObject *object){
    if (!object || object == (id)kCFNull) return nil;
    if ([object isKindOfClass:[NSDictionary class]]) {
        if ([NSJSONSerialization isValidJSONObject:object]) return object;
        NSMutableDictionary *newDic = [NSMutableDictionary new];
        [((NSDictionary *)object) enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            NSString *stringKey = [key isKindOfClass:[NSString class]] ? key : key.description;
            if (!stringKey) return;
            id jsonObj = objectToJsonObjectRecursive(obj);
            if (!jsonObj) jsonObj = @"";
            newDic[stringKey] = jsonObj;
        }];
        return newDic;
    }
    return nil;
}
@implementation NSObject (XPTool)
- (NSString *)xp_string{
    NSData *data = [self xp_jsonData];
    if (!data)  return nil;

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
- (NSData *)xp_jsonData{
    id jsonObject = [self xp_jsonObject];
    if (!jsonObject) return nil;
    return [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:NULL];
}
- (id)xp_jsonObject{
    id jsonObject = objectToJsonObjectRecursive(self);
    if ([jsonObject isKindOfClass:[NSArray class]]) return jsonObject;
    if ([jsonObject isKindOfClass:[NSDictionary class]]) return jsonObject;
    return nil;
}
@end
@implementation XPRequestTool
+ (NSStringEncoding)stringEncodingWithRequest:(XPBaseRequest *)request{
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    NSString *string = request.response.textEncodingName;
    if (string) {
        CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)string);
        if (encoding != kCFStringEncodingInvalidId) {
            stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
        }
    }
    return stringEncoding;
}
+ (NSString *)fullUrlPathWithRequest:(XPBaseRequest *)request{
    NSMutableString *url = [self urlPathWithRequest:request].mutableCopy;
    [url appendString:@"?"];
    NSDictionary *dic = [self paraConvetFromDic:request.params withConvert:request.parasConvert];
    for (NSString *key in dic.allKeys) {
        [url appendFormat:@"%@=%@&",key,[dic valueForKey:key]];
    }
    [url deleteCharactersInRange:NSMakeRange(url.length - 1, 1)];
    return url.copy;
}
+ (NSString *)jsonURLStringWithRequest:(XPBaseRequest *)request{
    NSMutableString *string = [NSMutableString string];
    if (request.uploadObjects.allKeys.count > 0) {
        [string appendString:[request.uploadObjects xp_string]];
    }
    if (request.params.allKeys.count > 0) {
       NSDictionary * dic = [self paraConvetFromDic:request.params withConvert:request.parasConvert];
       [string appendString:[dic xp_string]];
    }
    if (request.downloadPath.length > 0) {
         [string appendString:request.downloadPath];
    }
    return [[self urlPathWithRequest:request] stringByAppendingString:string];
}

+ (NSDictionary *)paraConvetFromDic:(NSDictionary *)parameters withConvert:(NSDictionary *)convertDic{
    if (!convertDic) {
        return parameters;
    }
    NSDictionary * paraConvert = convertDic;
    NSArray *convertKeys = paraConvert.allKeys;
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    for (NSString *key in convertKeys) {
        
        NSString *paraKey = [paraConvert objectForKey:key];
        if (key.length == 0) {
            [mutableParameters removeObjectForKey:paraKey];
            continue;
        }
        NSString *value = [parameters objectForKey:paraKey];
        
        [mutableParameters setObject:value forKey:key];
    }
    return mutableParameters.copy;
}
+ (NSString *)urlPathWithRequest:(XPBaseRequest *)request{
    NSMutableString *string = [NSMutableString string];
    if (request.baseUrl.length > 0) {
        [string appendString:request.baseUrl];
    }
    if (request.route.length > 0) {
        if (request.baseUrl.length > 0) {
            [string appendString:@"/"];
        }
        [string appendString:request.route];
    }
    if (request.path.length > 0) {
        if (request.route.length > 0 || request.baseUrl.length > 0) {
            [string appendString:@"/"];
        }
        [string appendString:request.path];
    }
    return string.copy;
}

+ (NSString *)md5StringFromString:(NSString *)string{
    NSParameterAssert(string != nil && [string length] > 0);
    
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }
    
    return outputString;
}
/**
 获取缓存key
 */
+ (NSString *)requestCacheKey:(XPBaseRequest *)request{
    NSMutableString *string = [NSMutableString string];
    if (request.cacheName.length > 0) {
        [string appendString:request.cacheName];
    }else{
        [string appendString:[XPRequestTool jsonURLStringWithRequest:request]];
    }
    return string.copy;
}

+ (BOOL)validateResumeData:(NSData *)data {
    // From http://stackoverflow.com/a/22137510/3562486
    if (!data || [data length] < 1) return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;
    
    // Before iOS 9 & Mac OS X 10.11
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000)\
|| (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED < 101100)
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
#endif
    // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
    // complicated structue. Besides, the plist structure is different between iOS 9 and iOS 10.
    // We can only assume that the plist being successfully parsed means the resume data is valid.
    return YES;
}

+ (BOOL)isBlank:(id)obj{
    if([obj isEqual: [NSNull null]]|| obj == nil)return YES;
    if([obj isKindOfClass:[NSArray class]])
        return [obj count]==0;
    if([obj isKindOfClass:[NSMutableArray class]])
        return [obj count]==0;
    if([obj isKindOfClass:[NSDictionary class]])
        return [obj count]==0;
    if([obj isKindOfClass:[NSMutableDictionary class]])
        return [obj count]==0;
    if([obj isKindOfClass:[NSData class]])
        return [obj length]==0;
    if([obj isKindOfClass:[NSString class]])
        return [obj length]==0;
    return NO;
}
@end


//
//  XPBaseRequest.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/4/30.
//

#import <Foundation/Foundation.h>
#import "XPRequestDefines.h"
#import "AFNetworking.h"

NS_ASSUME_NONNULL_BEGIN
/*
 请求的基本信息
 */
@class XPBaseRequest, AFSecurityPolicy, XPRequestUniquePackage;
@protocol AFMultipartFormData;

#pragma mark - Protocol -
@protocol XPRequestDelegate <NSObject>
@optional

/**
 单个请求
 
 request 为对象本身
 */

- (void)requestSuccessed:(__kindof XPBaseRequest *)request;

- (void)requestFailed:(__kindof XPBaseRequest *)request;

- (void)requestCancelled:(__kindof XPBaseRequest *)request;

- (void)requestFirstCacheLoaded:(__kindof XPBaseRequest *)request;

@end



@protocol XPRequestUniqueDelegate <XPRequestDelegate>
@optional

@end

typedef void(^XPReuqestUploadDataDeal)(NSString * key , id obj, id <AFMultipartFormData>formata);

/**
 进度，速度 b每秒
 */
typedef void (^XPURLSessionTaskProgressBlock)(NSProgress *progress, CGFloat speed);
typedef void(^XPBaseRequestCompletionBlock)(XPBaseRequest *request);

@interface XPBaseRequest : NSObject
#pragma mark - 参数 -
/**
 请求host
 */
@property (nonatomic, copy) NSString * baseUrl;

/**
 代理
 */
@property (nonatomic, weak) id <XPRequestDelegate> delegate;

/**
 requestTask.currentRequest
 */
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;

/**
 requestTask.originalRequest
 */
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;

/**
 requestTask.response
 */
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

/**
 The response header fields.
 */
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;

/**
 请求超时时长
 */
@property (nonatomic, assign) NSTimeInterval  requestTimeOut;

#pragma mark - 缓存 -
/**
 1.若只设置memoryCacheTime则只会存在内存中
 2.若只设置diskCacheTime，则内存与磁盘都会有，当磁盘过期时都消失
 3.若两个都设置，则当memory过期或disk过期时时才能发起下一次网络请求
 4.当设置isClearWhenDiskTimeOut为Yes时，当数据过期时diskCache会清除，为NO时则会保留
 */
/**
 磁盘保存过期时间
 */
@property (nonatomic, assign) NSTimeInterval  diskCacheTime;

/**
 当磁盘缓存过期时是否保存,默认保存
 */
@property (nonatomic, assign) BOOL  isClearWhenDiskTimeOut;

/**
 是否缓存
 */
@property (nonatomic, assign) XPCacheType  cacheType;

/**
 内存缓存过期时间
 */
@property (nonatomic, assign) NSTimeInterval  memoryCacheTime;

/**
 缓存的名字
 */
@property (nonatomic, copy) NSString  *cacheName;


/**
 合法的缓存状态
 */
@property (nonatomic, assign) XPCacheResultStatus  cacheStatus;


/**
 缓存的key值,若改变请先手动清空之前key值
 */
@property (nonatomic, copy, readonly) NSString * cacheKey;

/**
 第一次请求时是否先取缓存
 */
@property (nonatomic, assign) BOOL  loadCacheWhenFirstStart;


/**
 是否为缓存数据
 */
@property (nonatomic, assign, readonly) BOOL  isCacheData;


@property (nonatomic, copy) id (^customData) (id responseObject);

#pragma mark - 基础设置 -
/**
 是否允许4G网络，默认允许
 */
@property (nonatomic, assign) BOOL  allowsCellularAccess;

/**
 首路径
 拼接： baseUrl + route + path
 */
@property (nonatomic, copy) NSString * route;

/**
 路径
 */
@property (nonatomic, copy) NSString * path;

/**
 参数
 */
@property (nonatomic, strong) NSMutableDictionary * params;


/**
 运行状态
 */
@property (nonatomic, assign, readonly) XPRequestRunningStatus  runningStaus;
/**
 是否取消
 */
@property (nonatomic, assign, readonly) BOOL  isCancelled;

/**
 是否运行中
 */
@property (nonatomic, assign, readonly) BOOL  isExecuting;

/**
 是否已经结束
 */
@property (nonatomic, assign, readonly) BOOL  isFinshed;

@property (nonatomic, assign, readonly) BOOL  isUnstart;
/**
 是否是请求失败
 */
@property (nonatomic, assign, readonly) BOOL  isFail;
/**
 请求方法
 */
@property (nonatomic, assign) XPRequestMethod  method;

/**
  本次请求的状态码
 */
@property (nonatomic, assign, readonly) NSInteger  requestStatus;

/**
 验证状态是否成功
 */
@property (nonatomic, assign, readonly) BOOL  isValidReult;

/**
 有效的验证码
 */
@property (nonatomic, strong) NSArray <NSNumber *>* validStatus;

/**
 请求结果二进制
 */
@property (nonatomic, strong, readonly, nullable) NSData *responseData;


/**
 请求结果字符串
 */
@property (nonatomic, strong, readonly, nullable) NSString *responseString;

/**
 请求的结果
 */
@property (nonatomic, strong, readonly) id responseObject;

/**
 请求原始
 */
@property (nonatomic, strong, readonly) id originalResponseObject;
/**
 请求结果的json对象
 */
@property (nonatomic, strong, readonly, nullable) id responseJSONObject;
/**
 网络请求
 */
@property (nonatomic, strong, readonly) NSURLSessionTask * requestTask;

@property (nonatomic, strong, readonly) NSURLSessionTask * currentRequestTask;
/**
 网络请求错误信息
 */
@property (nonatomic, strong, readonly) NSError * error;


@property (nonatomic, strong) dispatch_queue_t queue;

#pragma mark - 下载 -
/**
 下载文件的地址
 */
@property (nonatomic, copy) NSString * downloadPath;

/**
 下载进度
 */
@property (nonatomic, copy) XPURLSessionTaskProgressBlock  downloadProgress;


#pragma mark - 上传 -
/**
 上传图片等
 NSData *data = UIImageJPEGRepresentation(_image, 0.9);
 NSString *name = @"image";
 NSString *formKey = @"image";
 NSString *type = @"image/jpeg";
 [formData appendPartWithFileData:data name:formKey fileName:name mimeType:type];
 
 value 上传的对像 key ：上传的文件名
 */
@property (nonatomic, strong) NSDictionary * uploadObjects;

/**
 上传进度
 */
@property (nonatomic, copy) XPURLSessionTaskProgressBlock  uploadProgress;

//上传或下载速度,字节为单位
@property (nonatomic, assign, readonly) CGFloat  speed;

/**
 是否允许后台下载
 */
@property (nonatomic, assign) BOOL  shouldContinueWhenAppEntersBackground;
/**
 请求格式
 */
@property (nonatomic, strong) NSSet * acceptableContentTypes;
/**
 上传数据处理
 */
@property (nonatomic, strong) XPReuqestUploadDataDeal uploadDataDeal;
/**
 请求类型
 */
@property (nonatomic, assign) XPRequestSerializerType requestSerializerType;

/**
 返回类型
 */
@property (nonatomic, assign) XPResponseSerializerType responseSerializerType;

/**
 请求成功回调
 */
@property (nonatomic, copy) XPBaseRequestCompletionBlock sucess;

/**
 请求失败回调
 */
@property (nonatomic, copy) XPBaseRequestCompletionBlock failure;


/**
 请求取消回调
 */
@property (nonatomic, copy) XPBaseRequestCompletionBlock cancel;

/**
 设置安全验证
 */
@property (nonatomic, strong) AFSecurityPolicy * securityPolicy;


/**
 请求的用户和密码
 */
@property (nonatomic, strong) NSArray <NSString *> * requestAuthorizationHeaderFieldArray;

/**
 请求头信息
 */
@property (nonatomic, strong) NSDictionary <NSString *, NSString *>* headerFieldValueDictionary;


/**
 参数转换
 */
@property (nonatomic, strong) NSDictionary * parasConvert;
#pragma mark - 去重 -

/**
 相同的Key值如果有一个正在请求则其他的不能请求
 */
@property (nonatomic, copy) NSString * heavyTag;

/**
 去重标记,若同一时间多次请求则只返回一次
 */
@property (nonatomic, assign) NSUInteger  uniqueIdentity;

/**
 去重标记过期时间
 */
@property (nonatomic, assign) NSTimeInterval  uniqueTimeOut;

- (BOOL)isUnique;
/**
 fullUrl
 */
@property (nonatomic, copy, readonly) NSString * fullUrl;

@property (nonatomic, weak) XPRequestUniquePackage <XPRequestUniqueDelegate>* uniqueDelegate;
#pragma mark - Methods -
/**
 开始
 */
- (void)start;

/**
 停止
 */
- (void)stop;


/**
 请求将要开始
 */
- (void)requestWillStart;


/**
 json数据是否合法
 */
- (BOOL)validateJson;
#pragma mark - 回调 -
/**
 清楚返回block
 */
- (void)clearCompletionBlock;

/**
 请求成功，在后台进程进行的操作
 */
- (void)requestSuccessPreprocessor:(XPBaseRequest *)request;

/**
 请求成功回调， 在主线程完成
 */
- (void)requsetSuccessFilter:(XPBaseRequest *)request;

/**
 请求失败，在后台进程进行的操作
 */
- (void)requestFailedPreprocessor:(XPBaseRequest *)request;

/**
 请求失败回调， 在主线程完成
 */
- (void)requestFailedFilter:(XPBaseRequest *)request;

/**
 请求取消，在后台进程进行的操作
 */
- (void)requestCancelledPreprocessor:(XPBaseRequest *)request;

/**
 请求取消回调， 在主线程完成
 */
- (void)requestCancelledFilter:(XPBaseRequest *)request;
/**
 完成回调

 @param success 成功回调
 @param failure 失败回调
 */
- (void)setCompletionBlockWithSuccess:(XPBaseRequestCompletionBlock)success
                              failure:(XPBaseRequestCompletionBlock)failure;


- (void)startCompletionBlockWithSuccess:(XPBaseRequestCompletionBlock)success
                                failure:(XPBaseRequestCompletionBlock)failure;


- (NSURLSessionDataTask *)loadCustomRequest:(void (^ ) (NSURLResponse *response, id responseObject, NSError *error))request manager:(AFHTTPSessionManager *)manager;

@end

NS_ASSUME_NONNULL_END

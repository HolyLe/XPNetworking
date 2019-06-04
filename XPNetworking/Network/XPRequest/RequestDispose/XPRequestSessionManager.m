//
//  XPRequestSessionManager.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/4.
//

#import "XPRequestCategory.h"
#import <pthread/pthread.h>
#import "AFNetworking.h"
#import <objc/runtime.h>
#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)
#define XPDownLoadCache @"Incomplete"
static  NSString *const XPRequestValidationErrorDomain = @"com.rh.network";
@interface XPRequestSessionManager ()<XPRequestDelegate>{
    pthread_mutex_t _lock;
    dispatch_queue_t _queue;
}

/**
 请求队列
 */
@property (nonatomic, strong) NSMutableDictionary * requestList;

@property (nonatomic, strong) AFHTTPSessionManager * manager;

@property (nonatomic, strong) AFHTTPResponseSerializer * httpResponseSerializer;

@property (nonatomic, strong) AFJSONResponseSerializer * jsonResponseSerializer;

@property (nonatomic, strong) AFXMLParserResponseSerializer * xmlResponseSerializer;

@property (nonatomic, strong) NSSet * acceptableContentTypes;
@end
static const char * queueString = "com.rhhorse.queue";
static XPRequestSessionManager *_shareManager = nil;
@implementation XPRequestSessionManager
#pragma mark - 初始化 -

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
#pragma mark - 方法 -

- (NSURLSessionTask *)startWithRequest:(XPBaseRequest *)request{

    NSLog(@"网络请求开始 ===== %@", request.fullUrl);
    //构建时发生错误
    NSError * __autoreleasing requestSerializationError = nil;
    request.requestTask = [self sessionTaskWithRequest:request error:&requestSerializationError];
    
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        
    }else{
        [self addRequestToRecord:request task:request.requestTask];
        
    }
    
    if ([request respondsToSelector:sel_registerName("loadCustomRequest")]) {
        return request.requestTask;
    }
    [request.requestTask resume];
    return request.requestTask;
}

- (void)cancelWithRequest:(XPBaseRequest *)request{
    if (request.downloadPath.length) {
        Weak;
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.requestTask;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [weakSelf incompleteDownloadTempPathForDownloadPath:request.downloadPath];
            [resumeData writeToURL:localUrl atomically:YES];
            
        }];
    }else{
        [request.requestTask cancel];
    }
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}
#pragma mark - 配置工程 -

- (void)setup{
    pthread_mutex_init(&_lock, NULL);
    _queue = dispatch_queue_create(queueString, DISPATCH_QUEUE_CONCURRENT);
    self.manager.completionQueue = _queue;
    self.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", @"text/json" ,@"text/javascript",@"text/plain",@"application/xml",@"text/xml", nil];
    
}
- (void)setConfiguration:(XPRequestConfiguration *)configuration{
    _configuration = configuration;
    if (_configuration.managerConfiguration) {
        _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration.managerConfiguration];
    }
}


- (NSURLSessionTask *)sessionTaskWithRequest: (XPBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    XPRequestMethod method = request.method;
    AFHTTPRequestSerializer *serializer = [self configRequestSerializerByRequset:request];
    self.manager.responseSerializer = [self confiResponseSerializerByRequest:request];
    NSURLSessionTask *task = nil;
    NSString * urlString = [XPRequestTool urlPathWithRequest:request];
    NSDictionary *parameters = request.params;
    
    parameters = [XPRequestTool paraConvetFromDic:parameters withConvert:request.parasConvert];
    [request requestWillStart];
    
    if ([request respondsToSelector:@selector(loadCustomRequest:manager:)]) {
        __weak typeof (self)weakSelf = self;
        __block NSURLSessionDataTask *dataTask = nil;
        dataTask = [request loadCustomRequest:^(NSURLResponse *response, id responseObject, NSError *error) {
            [weakSelf handleRequestResult:dataTask responseObject:responseObject error:error];
        } manager:self.manager];
        return dataTask;
    }
    switch (method) {
        case XPRequestGet:{
            if (request.downloadPath) {
                __weak typeof(request)weakRequest = request;
                task = [self downloadTaskWithDownloadPath:request.downloadPath requestSerializer:serializer URLString:urlString parameters:parameters progress:^(NSProgress *downloadProgress) {
                    [weakRequest.uniqueDelegate setProgress:downloadProgress];
                } error:error];
            }else{
                task = [self dataTaskWithHttpMehod:@"GET" requestSerialozer:serializer urlString:urlString parameters:parameters error:error];
            }
        }
            break;
        case XPRequestPost:{
            __weak typeof(request)weakRequest = request;
            task = [self dataTaskWithHttpMehod:@"POST" requestSerialozer:serializer urlString:urlString parameters:parameters uploadObjects:request.uploadObjects constructingBodyWithBlock:request.uploadDataDeal progress:^(NSProgress * _Nonnull progress) {
                [weakRequest.uniqueDelegate setProgress:progress];
            } error:error];
        }
            break;
        case XPRequestDelete:{
            task = [self dataTaskWithHttpMehod:@"DELETE" requestSerialozer:serializer urlString:urlString  parameters:parameters error:error];
        }
            break;
        case XPRequestHead:{
            task = [self dataTaskWithHttpMehod:@"HEAD" requestSerialozer:serializer urlString:urlString parameters:parameters error:error];
            
        }
            break;
        case XPRequestPut:{
            task = [self dataTaskWithHttpMehod:@"PUT" requestSerialozer:serializer urlString:urlString parameters:parameters error:error];
        }
            break;
        case XPRequestPatch:{
            task = [self dataTaskWithHttpMehod:@"PATCH" requestSerialozer:serializer urlString:urlString parameters:parameters error:error];
        }
            break;
    }
    return task;
}

#pragma mark - Network -
- (NSURLSessionDataTask *)dataTaskWithHttpMehod:(NSString *)method
                              requestSerialozer:(AFHTTPRequestSerializer *)requestSerializer
                                      urlString:(NSString *)urlString
                                     parameters:(id)parameters
                                          error:(NSError * _Nullable __autoreleasing * )error{
    return [self dataTaskWithHttpMehod:method requestSerialozer:requestSerializer urlString:urlString parameters:parameters uploadObjects:nil constructingBodyWithBlock:nil progress:nil error:error];;
}

- (NSURLSessionDataTask *)dataTaskWithHttpMehod:(NSString *)method
                              requestSerialozer:(AFHTTPRequestSerializer *)requestSerializer
                                      urlString:(NSString *)urlString
                                     parameters:(id)parameters
                                  uploadObjects:(NSDictionary *)uploadObjects
                      constructingBodyWithBlock:(XPReuqestUploadDataDeal)block
                                       progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
                                          error:(NSError * _Nullable __autoreleasing * )error{
    NSMutableURLRequest *request = nil;
    
    if (uploadObjects) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            if (block) {
                NSArray *keys = uploadObjects.allKeys;
                for (NSString *key in keys) {
                    block(key, uploadObjects[key], formData);
                }
            }
        } error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:urlString parameters:parameters error:error];
    }
    __block NSURLSessionDataTask *dataTask = nil;
    if (uploadProgress) {
        dataTask = [self.manager uploadTaskWithStreamedRequest:request progress:uploadProgress completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [self handleRequestResult:dataTask responseObject:responseObject error:error];
        }];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dataTask = [self.manager dataTaskWithRequest:request
                                   completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
                                       [self handleRequestResult:dataTask responseObject:responseObject error:_error];
                                   }];
#pragma clang diagnostic pop
        
    }
    return dataTask;
}
#pragma mark - 下载 -
- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error{
    
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];
    
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // If targetPath is a directory, use the file name we got from the urlRequest.
    // Make sure downloadTargetPath is always a file, not directory.
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }
    
    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So we remove the exist file before we start the download task.
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self incompleteDownloadTempPathForDownloadPath:downloadPath].path];
    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadPath]];
    BOOL resumeDataIsValid = [XPRequestTool validateResumeData:data];
    
    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *task = nil;
    // Try to resume with resumeData.
    // Even though we try to validate the resumeData, this may still fail and raise excecption.
    if (canBeResumed) {
        @try {
            task = [_manager downloadTaskWithResumeData:data progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
            } completionHandler:
                    ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                        [self handleRequestResult:task responseObject:filePath error:error];
                    }];
            resumeSucceeded = YES;
        } @catch (NSException *exception) {
            
            resumeSucceeded = NO;
        }
    }
    if (!resumeSucceeded) {
        task = [_manager downloadTaskWithRequest:urlRequest progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:
                ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    [self handleRequestResult:task responseObject:filePath error:error];
                }];
    }
    return task;
}
- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        cacheFolder = [cacheDir stringByAppendingPathComponent:XPDownLoadCache];
    }
    
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        
        cacheFolder = nil;
    }
    return cacheFolder;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSMutableString *string = [NSMutableString stringWithString:downloadPath];
    NSString *homeString = NSHomeDirectory();
    NSRange range = [string rangeOfString:homeString];
    if (range.location != NSNotFound) {
        [string deleteCharactersInRange:range];
    }
    NSArray *array = [string componentsSeparatedByString:@"/"];
    NSMutableArray *absolutes = [NSMutableArray array];
    NSArray *paths = @[@"Documents", @"Library", @"SystemData", @"temp"];
    NSInteger index = -1;
    for (NSString *path in paths) {
        index = [array indexOfObject:path];
        if (index != NSNotFound) {
            break;
        }
    }
    if (index != NSNotFound) {
        for (NSInteger i = index; i < array.count; i++) {
            [absolutes addObject:array[i]];
        }
        downloadPath = [absolutes componentsJoinedByString:@"/"];
    }
    NSString *md5URLString = [XPRequestTool md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
}

#pragma mark - 数据处理 -
- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    
    Lock();
    XPBaseRequest *request = _requestList[@(task.taskIdentifier)];
    Unlock();
    if (!request) {
        return;
    }
    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;
    
    NSError *requestError = nil;
    BOOL succeed = NO;
    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[XPRequestTool stringEncodingWithRequest:request]];
        XPResponseSerializerType responseSeriType = request.responseSerializerType;
        switch (responseSeriType) {
            case XPResponseSerializerTypeHTTP:{
                
            }
                break;
            case XPResponseSerializerTypeJSON:{
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:responseObject error:&serializationError];
                request.responseJSONObject = request.responseObject;
            }
                break;
            case XPResponseSerializerTypeXMLParser:{
                request.responseObject = [self.xmlResponseSerializer responseObjectForResponse:task.response data:responseObject error:&serializationError];
            }
                break;
            default:
                break;
        }
    }
    request.originalResponseObject = responseObject;
    if (error) {
        succeed = NO;
        requestError = error;
        if (request.downloadPath.length > 0) {
            NSData *resumeData = error.userInfo[@"NSURLSessionDownloadTaskResumeData"];
            if (resumeData) {
                NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.downloadPath];
                [resumeData writeToURL:localUrl atomically:YES];
            }
        }
    } else if (serializationError){
        succeed = NO;
        requestError = serializationError;
    }else{
        succeed = [self valideResult:request error:&validationError];
        requestError = validationError;
    }
    
    if (succeed) {
        if (request.downloadPath.length > 0) {
            NSURL *url = [self incompleteDownloadTempPathForDownloadPath:request.downloadPath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];
            }
        }
        [request.uniqueDelegate setRequestData];
        [self requestDidSucceedWithRequest:request];
    }else{
        [self requestDidFailWithRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
    });
}
- (BOOL)valideResult:(XPBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error{
    BOOL success = [request isValidReult];
    if (!success) {
        if (error) {
            * error = [NSError errorWithDomain:XPRequestValidationErrorDomain code:XPRequestValidErrorStatusCode userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code"}];
        }
        return success;
    }
    success = [request validateJson];
    if (!success) {
        if (error) {
            * error = [NSError errorWithDomain:XPRequestValidationErrorDomain code:XPRequestValidErrorJsonFormat userInfo:@{NSLocalizedDescriptionKey : @"Invalid JSON format"}];
        }
        return success;
    }
    return YES;
}
- (void)requestDidSucceedWithRequest:(XPBaseRequest *)request{
    [request requestDidSuccess];
}
- (void)requestDidFailWithRequest:(XPBaseRequest *)request error:(NSError *)error{
    request.error = error;
    [request requestDidError];
}


/**
 获取缓存key
 */
- (NSString *)requestCacheKey:(XPBaseRequest *)request{
    NSString *cahceName = request.cacheName;
    if (cahceName.length == 0) {
        cahceName = [XPRequestTool jsonURLStringWithRequest:request];
    }
    return cahceName;
}
#pragma mark - 通用方法 -

- (AFHTTPRequestSerializer *)configRequestSerializerByRequset:(XPBaseRequest *)request{
    AFHTTPRequestSerializer * serializer = [self requestSerializerWithRequestSerializerType:request.requestSerializerType];
    NSArray *requestAuthorizationHeaderFieldArray = request.requestAuthorizationHeaderFieldArray;
    if (request.requestAuthorizationHeaderFieldArray) {
        [serializer setAuthorizationHeaderFieldWithUsername:[requestAuthorizationHeaderFieldArray firstObject] password:[requestAuthorizationHeaderFieldArray lastObject]];
    }
    serializer.allowsCellularAccess = request.allowsCellularAccess;
    NSDictionary *headerFieldValueDictionary = request.headerFieldValueDictionary?request.headerFieldValueDictionary:self.configuration.headerFieldValueDictionary;
    if (headerFieldValueDictionary) {
        for (NSString * httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = [request.headerFieldValueDictionary objectForKey:httpHeaderField];
            [serializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    serializer.timeoutInterval = request.requestTimeOut == 0?self.configuration.timeOut:request.requestTimeOut;
    self.manager.requestSerializer = serializer;
    if (request.securityPolicy) {
        self.manager.securityPolicy = request.securityPolicy;
    }else{
        self.manager.securityPolicy = self.configuration.securityPolicy;
    }
    return serializer;
}
- (AFHTTPResponseSerializer *)confiResponseSerializerByRequest:(XPBaseRequest *)request{
    XPResponseSerializerType type = request.responseSerializerType;
    switch (type) {
        case XPResponseSerializerTypeHTTP:
            
            return self.httpResponseSerializer;
            break;
        case XPResponseSerializerTypeJSON:{
            NSSet *set = [request.acceptableContentTypes allObjects].count > 0?request.acceptableContentTypes : self.acceptableContentTypes;
            self.jsonResponseSerializer.acceptableContentTypes = set;
            return self.jsonResponseSerializer;
            break;
        }
        case XPResponseSerializerTypeXMLParser:{
            NSSet *set = [request.acceptableContentTypes allObjects].count > 0?request.acceptableContentTypes : self.acceptableContentTypes;
            self.xmlResponseSerializer.acceptableContentTypes = set;
            return self.xmlResponseSerializer;
            break;
        }
        default:
            break;
    }
}
- (AFHTTPRequestSerializer *)requestSerializerWithRequestSerializerType:(XPRequestSerializerType )requestSerializerType{
    AFHTTPRequestSerializer *requestSerializer;
    switch (requestSerializerType) {
        case XPRequestSerializerTypeHTTP:{
            //mid=10&method=userInfo&dateInt=20160818
            requestSerializer = [AFHTTPRequestSerializer serializer];
        }
            break;
            ////{"mid":"11","method":"userInfo","dateInt":"20160818"}
        case XPRequestSerializerTypeJSON:{
            requestSerializer = [AFJSONRequestSerializer serializer];
        }
            break;
        default:
            break;
    }
    return requestSerializer;
}
- (void)addRequestToRecord:(XPBaseRequest *)request task:(NSURLSessionTask *)task{
    Lock();
    self.requestList[@(task.taskIdentifier)] = request;
    Unlock();
}
- (void)removeRequestFromRecord:(XPBaseRequest *)request{
    
    Lock();
    [_requestList removeObjectForKey:@(request.requestTask.taskIdentifier)];
    Unlock();
    NSLog(@"数量 session ::::::  %ld", self.requestList.count);
}







#pragma mark - 懒加载 -

+ (XPRequestSessionManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareManager = [XPRequestSessionManager new];
    });
    return _shareManager;
}
- (AFHTTPSessionManager *)manager{
    if (!_manager) {
        _manager = [AFHTTPSessionManager manager];
        
    }
    return _manager;
}
- (NSMutableDictionary *)requestList{
    if (!_requestList) {
        _requestList = [NSMutableDictionary dictionary];
    }
    return _requestList;
}
- (AFJSONResponseSerializer *)jsonResponseSerializer{
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableContentTypes = self.acceptableContentTypes;
        _jsonResponseSerializer.acceptableStatusCodes = self.configuration.validStatusCodes;
    }
    return _jsonResponseSerializer;
}
- (AFXMLParserResponseSerializer *)xmlResponseSerializer{
    if (!_xmlResponseSerializer) {
        _xmlResponseSerializer = [AFXMLParserResponseSerializer serializer];
        _xmlResponseSerializer.acceptableContentTypes = self.acceptableContentTypes;
        _xmlResponseSerializer.acceptableStatusCodes = self.configuration.validStatusCodes;
    }
    return _xmlResponseSerializer;
}
- (AFHTTPResponseSerializer *)httpResponseSerializer{
    if (!_httpResponseSerializer) {
        _httpResponseSerializer = [AFHTTPResponseSerializer serializer];
        _httpResponseSerializer.acceptableStatusCodes = self.configuration.validStatusCodes;
    }
    return _httpResponseSerializer;
}
@synthesize configuration = _configuration;
- (XPRequestConfiguration *)configuration{
    if (!_configuration) {
        _configuration = [XPRequestConfiguration new];
    }
    return _configuration;
}
@end

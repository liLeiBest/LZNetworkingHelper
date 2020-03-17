//
//  LZNetworkingHelper.m
//  Pods
//
//  Created by Dear.Q on 16/7/22.
//
//

#import "LZNetworkingHelper.h"
#import "AFNetworking.h"

@interface LZNetworkingHelper()

@property (strong, nonatomic) AFHTTPSessionManager *httpSessionManager;
@property (strong, nonatomic) AFURLSessionManager *urlSessionManager;

@end

@implementation LZNetworkingHelper{
    NSDateFormatter *_dateFmt;
}

#pragma mark - -> initialization
- (instancetype)init {
	
    self = [super init];
    if (self){
        _timeoutInterval = 15;
    }
    return self;
}

+ (instancetype)sharedNetworkingHelper {
	
    static LZNetworkingHelper *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		_instance = [[LZNetworkingHelper alloc] init];
	});
    
    return _instance;
}

#pragma mark - -> LazyLoading
- (AFHTTPSessionManager *)httpSessionManager {
	
    /**
     要使用常规的AFN网络访问
     
     1. AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
     
     所有的网络请求,均有manager发起
     
     2. 需要注意的是,默认提交请求的数据是二进制的,返回格式是JSON
     
     1> 如果提交数据是JSON的,需要将请求格式设置为AFJSONRequestSerializer
     2> 如果返回格式不是JSON的,
     
     3. 请求格式
     
     AFHTTPRequestSerializer            二进制格式
     AFJSONRequestSerializer            JSON
     AFPropertyListRequestSerializer    PList(是一种特殊的XML,解析起来相对容易)
     
     4. 返回格式
     
     AFHTTPResponseSerializer           二进制格式
     AFJSONResponseSerializer           JSON
     AFXMLParserResponseSerializer      XML,只能返回XMLParser,还需要自己通过代理方法解析
     AFXMLDocumentResponseSerializer (Mac OS X)
     AFPropertyListResponseSerializer   PList
     AFImageResponseSerializer          Image
     AFCompoundResponseSerializer       组合
     */
    
    if (_httpSessionManager == nil) {
		
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _httpSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://xxx.xx"] sessionConfiguration:sessionConfiguration];
        _httpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _httpSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _httpSessionManager.requestSerializer.timeoutInterval = self.timeoutInterval;
    }
    
    return _httpSessionManager;
}

- (AFURLSessionManager *)urlSessionManager {
	
    if (_urlSessionManager == nil) {
		
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
		_urlSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
		
        __weak typeof(self) weakSelf = self;
        [_urlSessionManager setTaskWillPerformHTTPRedirectionBlock:
		 ^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
			 
			 if (weakSelf.taskWillPerformHTTPRedirection) {
				 return weakSelf.taskWillPerformHTTPRedirection(session, task, response, request);
			 }
             return request;
         }];
        
        [_urlSessionManager setDataTaskDidReceiveDataBlock:
		 ^(NSURLSession *session,  NSURLSessionDataTask *dataTask, NSData *data) {
			 
			 if (weakSelf.dataTaskDidReceiveData) {
				 weakSelf.dataTaskDidReceiveData(session, dataTask, data);
			 }
         }];
        
        [_urlSessionManager setDataTaskDidReceiveResponseBlock:
		 ^NSURLSessionResponseDisposition(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response) {
			 
			 if (weakSelf.dataTaskDidReceiveResponse) {
				 return weakSelf.dataTaskDidReceiveResponse(session, dataTask, response);
			 }
             return NSURLSessionResponseAllow;
         }];
        
        [_urlSessionManager setTaskDidCompleteBlock:
		 ^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
			 
			 if (weakSelf.taskDidComplete) {
				 weakSelf.taskDidComplete(session, task, error);
			 }
		 }];
    }
    
    return _urlSessionManager;
}

- (void)setCerFilePath:(NSString *)cerFilePath {
    _cerFilePath = cerFilePath;
    
    [self configSecurityPolicy];
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
    
    self.httpSessionManager.requestSerializer.timeoutInterval = _timeoutInterval;
}

- (void)setCustomRequestHeader:(NSDictionary *)customRequestHeader {
	
	if (nil == customRequestHeader || 0 == customRequestHeader.count) {
		[_customRequestHeader enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
			[self.httpSessionManager.requestSerializer setValue:nil forHTTPHeaderField:key];
		}];
	}
    _customRequestHeader = customRequestHeader;
	
	if (customRequestHeader) {
		[_customRequestHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[self.httpSessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
		}];
	}
}

#pragma mark - -> AFHTTPSessionManager
/** http请求 */
- (NSURLSessionDataTask *)requestWithHttpMethod:(HttpMethodType)httpMethod
                                            url:(NSString *)urlString
                                         params:(NSDictionary *)params
                                        success:(LZNetworkSuccessBlock)success
                                        failure:(LZNetworkFailureBlock)failure {
	
    switch (httpMethod) {
        case HttpMethodTypePOST:
            return [self POST:urlString params:params success:success failure:failure];
            break;
        case HttpMethodTypeDELETE:
            return [self DELETE:urlString params:params success:success failure:failure];
            break;
        case HttpMethodTypePUT:
            return [self PUT:urlString params:params success:success failure:failure];
            break;
        case HttpMethodTypeGET:
            return [self GET:urlString params:params success:success failure:failure];
            break;
    }
}

/** POST(multipart) */
- (NSURLSessionDataTask *)POST:(NSString *)urlString
                        params:(NSDictionary *)params
                          data:(NSArray *)dataArrI
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
                      progress:(LZNetworkProgressBlock)progress
                       success:(LZNetworkSuccessBlock)success
                       failure:(LZNetworkFailureBlock)failure {
    
    return [[self httpSessionManager]
            POST:urlString
            parameters:params
            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [dataArrI enumerateObjectsUsingBlock:^(id  _Nonnull data, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([data isKindOfClass:[NSURL class]]) {
                [formData appendPartWithFileURL:data name:name fileName:fileName mimeType:mimeType error:NULL];
            } else if ([data isKindOfClass:[NSString class]]) {
                
                NSURL *fileURL = [NSURL fileURLWithPath:data];
                [formData appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:NULL];
            } else if ([data isKindOfClass:[NSData class]]) {
                [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
            }
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if ([NSThread isMainThread]) {
            if (progress) {
                progress(uploadProgress);
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progress) {
                    progress(uploadProgress);
                }
            });
        }
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (NSURLSessionDataTask *)POSTMultipartFormData:(NSString *)urlString
                                         params:(NSDictionary *)params
                                           data:(NSArray *)dataArrI
                                           name:(NSString *)name
                                       mimeType:(NSString *)mimeType
                                       progress:(LZNetworkProgressBlock)progress
                                        success:(LZNetworkSuccessBlock)success
                                        failure:(LZNetworkFailureBlock)failure {
    return [[self httpSessionManager]
            POST:urlString
            parameters:params
            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [dataArrI enumerateObjectsUsingBlock:^(id  _Nonnull data, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([data isKindOfClass:[NSURL class]]) {
                
                NSString *fileName = [(NSURL *)data lastPathComponent];
                [formData appendPartWithFileURL:data name:name fileName:fileName mimeType:mimeType error:NULL];
            } else if ([data isKindOfClass:[NSString class]]) {
                
                NSURL *fileURL = [NSURL fileURLWithPath:data];
                NSString *fileName = [(NSURL *)data lastPathComponent];
                [formData appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:NULL];
            } else if ([data isKindOfClass:[NSData class]]) {
                if (nil == self->_dateFmt) {
                    
                    self->_dateFmt = [[NSDateFormatter alloc] init];
                    self->_dateFmt.dateFormat = @"yyyy-MM-ddHH:mm:ss:SSS";
                }
                NSString *fileName = [self->_dateFmt stringFromDate:[NSDate date]];
                fileName = [NSString stringWithFormat:@"%@.png", fileName];
                [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
            }
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if ([NSThread isMainThread]) {
            if (progress) {
                progress(uploadProgress);
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progress) {
                    progress(uploadProgress);
                }
            });
        }
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

/** HEAD */
- (NSURLSessionDataTask *)HEAD:(NSString *)urlString
                        params:(NSDictionary *)params
                       success:(LZNetworkSuccessBlock)success
                       failure:(LZNetworkFailureBlock)failure {
    
    return [[self httpSessionManager]
            HEAD:urlString
            parameters:params
            success:^(NSURLSessionDataTask *task) {
        if (success) {
            success(task);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

/** PATCH */
- (NSURLSessionDataTask *)PATCH:(NSString *)urlString
                         params:(NSDictionary *)params
                        success:(LZNetworkSuccessBlock)success
                        failure:(LZNetworkFailureBlock)failure {
    
    return [[self httpSessionManager]
            PATCH:urlString
            parameters:params
            success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark Private
/** POST */
- (NSURLSessionDataTask *)POST:(NSString *)urlString
                        params:(NSDictionary *)params
                       success:(LZNetworkSuccessBlock)success
                       failure:(LZNetworkFailureBlock)failure {
    
    return [[self httpSessionManager]
            POST:urlString
            parameters:params
            progress:^(NSProgress *uploadProgress) {}
            success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

/** DELETE */
- (NSURLSessionDataTask *)DELETE:(NSString *)urlString
                          params:(NSDictionary *)params
                         success:(LZNetworkSuccessBlock)success
                         failure:(LZNetworkFailureBlock)failure {
    
    return [[self httpSessionManager]
            DELETE:urlString
            parameters:params
            success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

/** PUT */
- (NSURLSessionDataTask *)PUT:(NSString *)urlString
                       params:(NSDictionary *)params
                      success:(LZNetworkSuccessBlock)success
                      failure:(LZNetworkFailureBlock)failure {
    
    return [[self httpSessionManager] PUT:urlString
                               parameters:params
                                  success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

/** GET */
- (NSURLSessionDataTask *)GET:(NSString *)urlString
     params:(NSDictionary *)params
    success:(LZNetworkSuccessBlock)success
    failure:(LZNetworkFailureBlock)failure {
    
    return [[self httpSessionManager]
            GET:urlString
            parameters:params
            progress:^(NSProgress *downloadProgress) {}
            success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - -> AFURLSessionManager
/** DataTask，有上传或下载进度 */
- (NSURLSessionDataTask *)dataTaskRequest:(NSURLRequest *)request
                           uploadProgress:(LZNetworkProgressBlock)uploadProgressBlock
                         downloadProgress:(LZNetworkProgressBlock)downloadProgressBlock
                                  success:(LZNetworkSuccessBlock)success
                                  failure:(LZNetworkFailureBlock)failure {
	
    NSURLSessionDataTask *dataTask =
    [[self urlSessionManager] dataTaskWithRequest:request uploadProgress:
	 ^(NSProgress *uploadProgress) {
		 
		 if ([NSThread isMainThread]) {
			 if (uploadProgressBlock) {
				 uploadProgressBlock(uploadProgress);
			 }
		 } else {
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 if (uploadProgressBlock) {
					 uploadProgressBlock(uploadProgress);
				 }
			 });
		 }
     } downloadProgress:^(NSProgress *downloadProgress) {
		 
		 if ([NSThread isMainThread]) {
			 if (downloadProgressBlock) {
				 downloadProgressBlock(downloadProgress);
			 }
		 } else {
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 if (downloadProgressBlock) {
					 downloadProgressBlock(downloadProgress);
				 }
			 });
		 }
     } completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
         if (!error) {
			 if (success) {
				 success(responseObject);
			 }
         } else {
			 if (failure) {
				 failure(error);
			 }
         }
     }];
    [dataTask resume];
    
    return dataTask;
}

/** DataTask */
- (NSURLSessionUploadTask *)uploadTaskRequest:(NSURLRequest *)request
                                   fromSource:(id)source
                                     progress:(LZNetworkProgressBlock)uploadProgress
                                      success:(LZNetworkSuccessBlock)success
                                      failure:(LZNetworkFailureBlock)failure {
	
    if ([source isKindOfClass:[NSData class]])  {
        return [self uploadTaskRequest:request
                              fromData:source
                              progress:uploadProgress
                               success:success
                               failure:failure];
    } else if ([source isKindOfClass:[NSURL class]]) {
        return [self uploadTaskRequest:request
                              fromFile:source
                              progress:uploadProgress
                               success:success
                               failure:failure];
    } else if ([source isKindOfClass:[NSString class]]) {
        NSURL *fileUrl = [NSURL fileURLWithPath:source];
        return [self uploadTaskRequest:request
                              fromFile:fileUrl
                              progress:uploadProgress
                               success:success
                               failure:failure];
    } else {
        return [self uploadTaskRequest:request
                              progress:uploadProgress
                               success:success
                               failure:failure];
    }
}

/** downloadTask */
- (NSURLSessionDownloadTask *)downloadTaskRequest:(NSURLRequest *)request
                                         progress:(void (^)(NSProgress *))downloadProgressBlock
                                          success:(LZNetworkSuccessBlock)success
                                          failure:(LZNetworkFailureBlock)failure {
	
    NSURLSessionDownloadTask *downloadTask =
    [[self urlSessionManager] downloadTaskWithRequest:request progress:
	 ^(NSProgress * downloadProgress) {
		 
		 if ([NSThread isMainThread]) {
			 if (downloadProgressBlock) {
				 downloadProgressBlock(downloadProgress);
			 }
		 } else {
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 if (downloadProgressBlock) {
					 downloadProgressBlock(downloadProgress);
				 }
			 });
		 }
     } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		 
         NSFileManager *fileM = [NSFileManager defaultManager];
         NSString *doucumentDirectory =
         [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
          lastObject];
         NSString *fullPath =
         [doucumentDirectory stringByAppendingPathComponent:[response suggestedFilename]];
		 if ([fileM fileExistsAtPath:fullPath]) {
			 [fileM removeItemAtPath:fullPath error:NULL];
		 }
         NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
         
         return fileURL;
     } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		 
         LZNetworkingLog(@"<%@>文件保存到:%@", [response suggestedFilename], filePath);
         if (!error) {
			 if (success) {
				 success(filePath);
			 }
         } else {
			 if (failure) {
				 failure(error);
			 }
         }
	 }];
	[downloadTask resume];
    
    return downloadTask;
}

#pragma mark Private
/** UploadTask(NSURL) */
- (NSURLSessionUploadTask *)uploadTaskRequest:(NSURLRequest *)request
                                     fromFile:(NSURL *)fileUrl
                                     progress:(LZNetworkProgressBlock)uploadProgressBlock
                                      success:(LZNetworkSuccessBlock)success
                                      failure:(LZNetworkFailureBlock)failure {
	
    NSURLSessionUploadTask *uploadTask =
    [[self urlSessionManager] uploadTaskWithRequest:request fromFile:fileUrl progress:
	 ^(NSProgress *uploadProgress) {
		 
		 if ([NSThread isMainThread]) {
			 if (uploadProgressBlock) {
				 uploadProgressBlock(uploadProgress);
			 }
		 } else {
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 if (uploadProgressBlock) {
					 uploadProgressBlock(uploadProgress);
				 }
			 });
		 }
     } completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		 
         if (!error) {
             if (success) success(responseObject);
         } else {
             if (failure) failure(error);
         }
     }];
    [uploadTask resume];
    
    return uploadTask;
}

/** UploadTask(NSData)  */
- (NSURLSessionUploadTask *)uploadTaskRequest:(NSURLRequest *)request
                                     fromData:(NSData *)bodyData
                                     progress:(void (^)(NSProgress *))uploadProgressBlock
                                      success:(LZNetworkSuccessBlock)success
                                      failure:(LZNetworkFailureBlock)failure {
	
    NSURLSessionUploadTask *uploadTask =
    [[self urlSessionManager] uploadTaskWithRequest:request fromData:bodyData progress:
	 ^(NSProgress *uploadProgress) {
		 
		 if ([NSThread isMainThread]) {
			 if (uploadProgressBlock) {
				 uploadProgressBlock(uploadProgress);
			 }
		 } else {
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 if (uploadProgressBlock) {
					 uploadProgressBlock(uploadProgress);
				 }
			 });
		 }
     } completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		 
         if (!error) {
             if (success) success(responseObject);
         } else {
             if (failure) failure(error);
         }
     }];
    [uploadTask resume];
    
    return uploadTask;
}

/** UploadTask */
- (NSURLSessionUploadTask *)uploadTaskRequest:(NSURLRequest *)request
                                     progress:(LZNetworkProgressBlock)uploadProgressBlock
                                      success:(LZNetworkSuccessBlock)success
                                      failure:(LZNetworkFailureBlock)failure {
	
    NSURLSessionUploadTask *uploadTask =
    [[self urlSessionManager] uploadTaskWithStreamedRequest:request progress:
	 ^(NSProgress *uploadProgress) {
		 
		 if ([NSThread isMainThread]) {
			 if (uploadProgressBlock) {
				 uploadProgressBlock(uploadProgress);
			 }
		 } else {
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 if (uploadProgressBlock) {
					 uploadProgressBlock(uploadProgress);
				 }
			 });
		 }
     } completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		 
		 if (!error) {
			 if (success) success(responseObject);
		 } else {
			 if (failure) failure(error);
		 }
     }];
    [uploadTask resume];
    
    return uploadTask;
}

#pragma mark - -> AFNetworkingReachabilityManager
/** 开启网络状态监听 */
- (void)networkStatusStartMonitoring:(void (^)(NetworkStatus))finishHandler {
	
    /**
     AFNetworkReachabilityStatusUnknown          = -1,  // 未知
     AFNetworkReachabilityStatusNotReachable     = 0,   // 无连接
     AFNetworkReachabilityStatusReachableViaWWAN = 1,   // 3G 花钱
     AFNetworkReachabilityStatusReachableViaWiFi = 2,   // 局域网络,不花钱
     */
    
    AFNetworkReachabilityManager *networkMgr = [AFNetworkReachabilityManager sharedManager];
    [networkMgr setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
		
        NSString *network = nil;
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                network = @"未知网络";
                break;
            case AFNetworkReachabilityStatusNotReachable:
                network = @"无网络";
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                network = @"移动网络";
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                network = @"WIFI";
                break;
        }
        
         LZNetworkingLog(@"当前网络类型:%@", network);
         if (finishHandler) finishHandler((NSInteger)status);
     }];
    
    [networkMgr startMonitoring];
}

/** 关闭网络状态监听 */
- (void)networkStatusStopMonitoring {
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];;
}

/** 当前网络状态 */
- (NetworkStatus)networkStatus {
	
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    
    return (NetworkStatus)status;
}

/** 开启网络可达性监听 */
- (void)networkReachabilityStartMonitoring:(void (^)(BOOL))finishHandler {
	
    [self networkStatusStartMonitoring:^(NetworkStatus status) {
        BOOL isReachable = YES;
        switch (status) {
            case NetworkStatusUnkonw:
            case NetworkStatusMobile:
            case NetworkStatusWIFI:
                isReachable = YES;
                break;
            case NetworkStatusNone:
                isReachable = NO;
                break;
        }
        
		if (finishHandler) {
			finishHandler(isReachable);
		}
    }];
}

/** 关闭网络可达性监听 */
- (void)networkReachabilityStopMonitoring {
    [self networkStatusStopMonitoring];
}

/** 当前网络是否可用 */
- (BOOL)networkReachability {
	
    BOOL reachability = [AFNetworkReachabilityManager sharedManager].reachable;
    
    return reachability;
}

#pragma mark - Other
/** 暂停所有请求任务 */
- (void)pauseAllRequestTask {
	
    NSMutableArray *tasksArrM = [NSMutableArray array];
    [tasksArrM addObjectsFromArray:self.httpSessionManager.tasks];
    [tasksArrM addObjectsFromArray:self.urlSessionManager.tasks];
    
    [tasksArrM enumerateObjectsUsingBlock:
	 ^(NSURLSessionTask *dataTask, NSUInteger idx, BOOL * _Nonnull stop) {
         [dataTask suspend];
     }];
}

/**
 @author Lilei
 
 @brief 恢复所有请求任务
 */
- (void)resumeAllRequestTask {
	
    NSMutableArray *tasksArrM = [NSMutableArray array];
    [tasksArrM addObjectsFromArray:self.httpSessionManager.tasks];
    [tasksArrM addObjectsFromArray:self.urlSessionManager.tasks];
    
    [tasksArrM enumerateObjectsUsingBlock:
	 ^(NSURLSessionTask *dataTask, NSUInteger idx, BOOL * _Nonnull stop) {
         [dataTask resume];
     }];
}

/** 设置网络请求拦截类 */
- (void)setURLProtocol:(Class)customUrlProtocol {
	
    if ([customUrlProtocol isKindOfClass:[NSURLProtocol class]]) {
        
    }
}

#pragma mark - -> Private
/**
 配置请求的安全策略
 */
- (void)configSecurityPolicy {
	
    if (self.cerFilePath && self.cerFilePath.length) {
        
        LZNetworkingLog(@"certificate path:%@", self.cerFilePath);
        NSData *caCert = [NSData dataWithContentsOfFile:self.cerFilePath];
        NSAssert(caCert != nil, @"certificate is not exist.");
        NSSet *certSet = [NSSet setWithObject:caCert];
        AFSecurityPolicy *securityPolicy =
        [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                         withPinnedCertificates:certSet];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = YES;
        
        self.httpSessionManager.securityPolicy = securityPolicy;
        self.urlSessionManager.securityPolicy = securityPolicy;
        
        [self sessionDidReceiveAuthenticationChallengeBlock:self.httpSessionManager];
        [self sessionDidReceiveAuthenticationChallengeBlock:self.urlSessionManager];
    }
}

/**
 会话身份验证设置
 
 @param sessionManager AFURLSessionManager
 */
- (void)sessionDidReceiveAuthenticationChallengeBlock:(AFURLSessionManager *)sessionManager {
    
    typedef NSURLSessionAuthChallengeDisposition (^AFURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);
    __weak typeof(self) weakSelf = self;
    AFURLSessionDidReceiveAuthenticationChallengeBlock block = ^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable _credential) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            // 获取服务器的 trust object
            SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
            
            // 导入自签名证书
            NSData* caCert = [NSData dataWithContentsOfFile:strongSelf.cerFilePath];
            NSAssert(caCert != nil, @"certificate is not exist.");
            // NSSet *certSet = [NSSet setWithObject:caCert];
            // strongSelf.httpSessionManager.securityPolicy.pinnedCertificates = certSet;
            SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCert);
            NSCAssert(caRef != nil, @"caRef is nil");
            NSArray *caArray = @[(__bridge_transfer id)(caRef)];
            NSCAssert(caArray != nil, @"caArray is nil");
            
            // 设置锚点证书
            OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)caArray);
            SecTrustSetAnchorCertificatesOnly(serverTrust,NO);
            NSCAssert(errSecSuccess == status, @"SecTrustSetAnchorCertificates failed");
            if (errSecSuccess == status) {
                LZNetworkingLog(@"SecTrustSetAnchorCertificates success");
            }
        });
        
        // 选择质询认证的处理方式
        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        __autoreleasing NSURLCredential *credential = nil;
        
        // NSURLAuthenticationMethodServerTrust 质询认证方式
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            
            // 基于客户端的安全策略来决定是否信任该服务器，不信任则不响应质询
            if ([strongSelf.httpSessionManager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust
                                                                        forDomain:challenge.protectionSpace.host]) {
                
                // 创建质询证书
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                // 确认质询方式
                if (credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                // 取消质询
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            
            if (!self.p12FilePath || !self.p12FilePath.length) return disposition;
            LZNetworkingLog(@"p12 path:%@", self.p12FilePath);
            NSFileManager *fileManager =[NSFileManager defaultManager];
            if(![fileManager fileExistsAtPath:self.p12FilePath]) {
                LZNetworkingLog(@"p12 is not exist.");
                return disposition;
            }
            
            SecIdentityRef identity = NULL;
            SecTrustRef trust = NULL;
            NSData *PKCS12Data = [NSData dataWithContentsOfFile:strongSelf.p12FilePath];
            if ([strongSelf extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data]) {
                
                SecCertificateRef certificate = NULL;
                SecIdentityCopyCertificate(identity, &certificate);
                const void *certs[] = {certificate};
                CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
                credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                CFRelease(certArray);
                if (credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            }
        }
        return disposition;
    };
    
    [sessionManager setSessionDidReceiveAuthenticationChallengeBlock:block];
}

/**
 从 P12 文件中提取身份

 @param outIdentity SecIdentityRef
 @param outTrust SecTrustRef
 @param inPKCS12Data NSData
 @return BOOL
 */
- (BOOL)extractIdentity:(SecIdentityRef *)outIdentity
               andTrust:(SecTrustRef *)outTrust
         fromPKCS12Data:(NSData *)inPKCS12Data {
    
    OSStatus securityError = errSecSuccess;
    NSDictionary *optionsDictionary =
    [NSDictionary dictionaryWithObject:self.p12Password
                                forKey:(__bridge id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError =
    SecPKCS12Import((__bridge CFDataRef)inPKCS12Data, (__bridge CFDictionaryRef)optionsDictionary, &items);
    
    if(securityError == 0) {
        
        CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
        const void*tempIdentity =NULL;
        tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void*tempTrust =NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    } else {
        LZNetworkingLog(@"Failedwith error code %d",(int)securityError);
        return NO;
    }
    CFRelease(items);
    return YES;
}

@end

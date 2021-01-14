//
//  LZNetworkingHelper.h
//  Pods
//
//  Created by Dear.Q on 16/7/22.
//
//

#import <Foundation/Foundation.h>
#import "LZNetworkingHelpConst.h"
@class LZMultipartDataModel;

NS_ASSUME_NONNULL_BEGIN

#define LZNetworking [LZNetworkingHelper sharedNetworkingHelper]

/** 成功回调Block */
typedef void (^ _Nullable LZNetworkSuccessBlock)(id responseObject);
/** 失败回调Block */
typedef void (^ _Nullable LZNetworkFailureBlock)(NSError *error);
/** 进度回调Block */
typedef void (^ _Nullable LZNetworkProgressBlock)(NSProgress *progress);

/** 重定向回调Block*/
typedef NSURLRequest * _Nullable (^LZURLSessionTaskWillPerformHTTPRedirectionBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request);
/** 接收到数据回调Block */
typedef void (^LZURLSessionDataTaskDidReceiveDataBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
/** 接收到响应回调Block*/
typedef NSURLSessionResponseDisposition (^LZURLSessionDataTaskDidReceiveResponseBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response);
/** 请求成功回调Block */
typedef void (^LZURLSessionTaskDidCompleteBlock)(NSURLSession *session, NSURLSessionTask *task, NSError *error);


/// 网络请求工具类
@interface LZNetworkingHelper : NSObject

/** cer 路径 */
@property (nonatomic, copy) NSString *cerFilePath;
/** p12 证书路径 */
@property (nonatomic, copy) NSString *p12FilePath;
/** p12 证书密码 */
@property (nonatomic, copy) NSString *p12Password;

/** 请求超时时间 单位：秒 默认：15 秒 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/** 自定义 headers，如果为 nil，则删除已有所有字段 */
@property (nonatomic, strong) NSDictionary *customRequestHeader;

@property (readwrite, nonatomic, copy) LZURLSessionTaskWillPerformHTTPRedirectionBlock taskWillPerformHTTPRedirection;
@property (readwrite, nonatomic, copy) LZURLSessionDataTaskDidReceiveDataBlock dataTaskDidReceiveData;
@property (readwrite, nonatomic, copy) LZURLSessionDataTaskDidReceiveResponseBlock dataTaskDidReceiveResponse;
@property (readwrite, nonatomic, copy) LZURLSessionTaskDidCompleteBlock taskDidComplete;

// MARK: - 实例 -

/// 单例
+ (instancetype)sharedNetworkingHelper;

// MARK: - AFHTTPSessionManager -

/// HTTP Request
/// @param requestMethod 请求方法，LZHTTPRequestMethod
/// @param urlString 请求地址
/// @param parameters 请求 Body
/// @param headers 请求 Header
/// @param successHandler 成功回调
/// @param failureHandler 失败回调
- (NSURLSessionDataTask *)requestMethod:(LZHTTPRequestMethod)requestMethod
                              urlString:(NSString *)urlString
                             parameters:(nullable id)parameters
                                headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                                success:(LZNetworkSuccessBlock)successHandler
                                failure:(LZNetworkFailureBlock)failureHandler;

/// 多表单 POST
/// @param urlString 请求地址
/// @param parameters 请求 Body
/// @param headers 请求 Header
/// @param multipartForms 数据列表
/// @param progressHandler 进度回调
/// @param successHandler 成功回调
/// @param failureHandler 失败回调
- (NSURLSessionDataTask *)POST:(NSString *)urlString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                multipartForms:(NSArray<LZMultipartDataModel *> *)multipartForms
                      progress:(LZNetworkProgressBlock)progressHandler
                       success:(LZNetworkSuccessBlock)successHandler
                       failure:(LZNetworkFailureBlock)failureHandler;

// MARK: - AFURLSessionManager -

/// DataTask
/// @param request 请求体
/// @param uploadProgress 上传进度回调
/// @param downloadProgress 下载进度回调
/// @param successHandler 请求成功回调
/// @param failureHandler 请求失败回调
- (NSURLSessionDataTask *)dataTaskRequest:(NSURLRequest *)request
                           uploadProgress:(LZNetworkProgressBlock)uploadProgress
                         downloadProgress:(LZNetworkProgressBlock)downloadProgress
                                  success:(LZNetworkSuccessBlock)successHandler
                                  failure:(LZNetworkFailureBlock)failureHandler;

/// UploadTask
/// @param request 请求体
/// @param source 资源
/// @param progressHandler 上传进度回调
/// @param successHandler 请求成功回调
/// @param failureHandler 请求失败回调
- (NSURLSessionUploadTask *)uploadTaskRequest:(NSURLRequest *)request
                                   fromSource:(id)source
                                     progress:(LZNetworkProgressBlock)progressHandler
                                      success:(LZNetworkSuccessBlock)successHandler
                                      failure:(LZNetworkFailureBlock)failureHandler;

/// downloadTask
/// @param request 请求体
/// @param progressHandler 下载进度回调
/// @param successHandler 请求成功回调
/// @param failureHandler 请求失败回调
- (NSURLSessionDownloadTask *)downloadTaskRequest:(NSURLRequest *)request
                                         progress:(LZNetworkProgressBlock)progressHandler
                                          success:(LZNetworkSuccessBlock)successHandler
                                          failure:(LZNetworkFailureBlock)failureHandler;

// MARK: - AFNetworkingReachabilityManager -

/// 开启网络状态变化监听
/// @param changeHandler 变更回调
- (void)networkStatusStartMonitoring:(void (^)(NetworkStatus status))changeHandler;

/// 关闭网络状态变化监听
- (void)networkStatusStopMonitoring;

/// 当前网络状态
- (NetworkStatus)networkStatus;

/// 开启网络可达性监听
/// @param changeHandler 变更回调
- (void)networkReachabilityStartMonitoring:(void (^)(BOOL reachable))changeHandler;

/// 关闭网络可达性监听
- (void)networkReachabilityStopMonitoring;

/// 当前网络是否可用
- (BOOL)networkReachability;

// MARK: - Other -

/// 暂停所有请求任务
- (void)pauseAllRequestTask;

/// 恢复所有请求任务
- (void)resumeAllRequestTask;

/// 是否是代理的状态
/// @param urlString 请求地址
- (BOOL)isProxyStatus:(NSString *)urlString;

/// 设置网络请求拦截类
/// @param customUrlProtocol NSURLProtocol 子类
- (void)setURLProtocol:(Class)customUrlProtocol;

// MARK: - Deprecated
- (NSURLSessionDataTask *)requestWithHttpMethod:(HttpMethodType)httpMethod
                                            url:(NSString *)urlString
                                         params:(NSDictionary *)params
                                        success:(LZNetworkSuccessBlock)success
                                        failure:(LZNetworkFailureBlock)failure;

- (NSURLSessionDataTask *)HEAD:(NSString *)urlString
                        params:(NSDictionary *)params
                       success:(LZNetworkSuccessBlock)success
                       failure:(LZNetworkFailureBlock)failure;

- (NSURLSessionDataTask *)PATCH:(NSString *)urlString
                         params:(NSDictionary *)params
                        success:(LZNetworkSuccessBlock)success
                        failure:(LZNetworkFailureBlock)failure;

- (NSURLSessionDataTask *)POST:(NSString *)urlString
                        params:(NSDictionary *)params
                          data:(NSArray *)dataArrI
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
                      progress:(LZNetworkProgressBlock)progress
                       success:(LZNetworkSuccessBlock)success
                       failure:(LZNetworkFailureBlock)failure;

- (NSURLSessionDataTask *)POSTMultipartFormData:(NSString *)urlString
                                         params:(NSDictionary *)params
                                           data:(NSArray *)dataArrI
                                           name:(NSString *)name
                                       mimeType:(NSString *)mimeType
                                       progress:(LZNetworkProgressBlock)progress
                                        success:(LZNetworkSuccessBlock)success
                                        failure:(LZNetworkFailureBlock)failure;


@end

@interface LZMultipartDataModel : NSObject

/// key
@property (nonatomic, copy) NSString *name;
/// 文件名
@property (nonatomic, copy, nullable) NSString *fileName;
/// 扩展名，默认 png
@property (nonatomic, copy, nullable) NSString *extensionName;
/// MimeType
@property (nonatomic, copy, nullable) NSString *mimeType;
/// 数据
@property (nonatomic) id data;
/// data 为 NSInputStream，长度
@property (nonatomic, assign) NSUInteger length;

@end

NS_ASSUME_NONNULL_END

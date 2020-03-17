//
//  LZNetworkingHelper.h
//  Pods
//
//  Created by Dear.Q on 16/7/22.
//
//

#import <Foundation/Foundation.h>
#import "LZNetworkingHelpConst.h"

#define LZNetworking [LZNetworkingHelper sharedNetworkingHelper]

/** 成功回调Block */
typedef void (^LZNetworkSuccessBlock)(id responseObject);
/** 失败回调Block */
typedef void (^LZNetworkFailureBlock)(NSError *error);
/** 进度回调Block */
typedef void (^LZNetworkProgressBlock)(NSProgress *progress);

/** 重定向回调Block*/
typedef NSURLRequest * (^LZURLSessionTaskWillPerformHTTPRedirectionBlock)(NSURLSession *session,
                                                                          NSURLSessionTask *task,
                                                                          NSURLResponse *response,
                                                                          NSURLRequest *request);
/** 接收到数据回调Block */
typedef void (^LZURLSessionDataTaskDidReceiveDataBlock)(NSURLSession *session,
                                                        NSURLSessionDataTask *dataTask,
                                                        NSData *data);
/** 接收到响应回调Block*/
typedef NSURLSessionResponseDisposition (^LZURLSessionDataTaskDidReceiveResponseBlock)(NSURLSession *session,
                                                                                       NSURLSessionDataTask *dataTask,
                                                                                       NSURLResponse *response);
/** 请求成功回调Block */
typedef void (^LZURLSessionTaskDidCompleteBlock)(NSURLSession *session,
                                                 NSURLSessionTask *task,
                                                 NSError *error);

/**
 @author Lilei
 
 @brief 网络请求工具类
 */
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


/**
 @author Lilei
 @brief 单例

 @return LZNetworkingHelper
 */
+ (instancetype)sharedNetworkingHelper;

#pragma mark - AFHTTPSessionManager
/**
 @author Lilei
 
 @brief HTTP Request
 
 @param httpMethod  HttpMethod
 @param urlString   请求地址
 @param params      请求参数
 @param success     请求成功回调
 @param failure     请求失败回调
 
 @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)requestWithHttpMethod:(HttpMethodType)httpMethod
                                            url:(NSString *)urlString
                                         params:(NSDictionary *)params
                                        success:(LZNetworkSuccessBlock)success
                                        failure:(LZNetworkFailureBlock)failure;

/**
 @author Lilei
 
 @brief a multipart POST
 
 @param urlString   请求地址
 @param params      请求参数
 @param dataArrI    要发送的二进制文件列表
 @param name        请求参数中二进制文件的名字
 @param fileName    请求参数中二进制文件的文件名
 @param mimeType    告诉服务器上传文件的类型
 @param progress    进度回调
 @param success     请求成功回调
 @param failure     请求失败回调
 
 @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)POST:(NSString *)urlString
                        params:(NSDictionary *)params
                          data:(NSArray *)dataArrI
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
                      progress:(LZNetworkProgressBlock)progress
                       success:(LZNetworkSuccessBlock)success
                       failure:(LZNetworkFailureBlock)failure;

/**
 @author Lilei
 
 @brief a multipart POST
 
 @param urlString   请求地址
 @param params      请求参数
 @param dataArrI    要发送的二进制文件列表
 @param name        请求参数中二进制文件的名字
 @param mimeType    告诉服务器上传文件的类型
 @param progress    进度回调
 @param success     请求成功回调
 @param failure     请求失败回调
 
 @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)POSTMultipartFormData:(NSString *)urlString
                                         params:(NSDictionary *)params
                                           data:(NSArray *)dataArrI
                                           name:(NSString *)name
                                       mimeType:(NSString *)mimeType
                                       progress:(LZNetworkProgressBlock)progress
                                        success:(LZNetworkSuccessBlock)success
                                        failure:(LZNetworkFailureBlock)failure;

/**
 @author Lilei
 
 @brief HEAD
 
 @param urlString   请求地址
 @param params      请求参数
 @param success     请求成功回调
 @param failure     请求失败回调
 
 @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)HEAD:(NSString *)urlString
                        params:(NSDictionary *)params
                       success:(LZNetworkSuccessBlock)success
                       failure:(LZNetworkFailureBlock)failure;

/**
 @author Lilei
 
 @brief PATCH
 
 @param urlString   请求地址
 @param params      请求参数
 @param success     请求成功回调
 @param failure     请求失败回调
 
 @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)PATCH:(NSString *)urlString
                         params:(NSDictionary *)params
                        success:(LZNetworkSuccessBlock)success
                        failure:(LZNetworkFailureBlock)failure;

#pragma mark - AFURLSessionManager
/**
 @author Lilei
 
 @brief DataTask
 
 @param request             请求
 @param uploadProgress      上传进度
 @param downloadProgress    下载进度
 @param success             请求成功回调
 @param failure             请求失败回调
 
 @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)dataTaskRequest:(NSURLRequest *)request
                           uploadProgress:(LZNetworkProgressBlock)uploadProgress
                         downloadProgress:(LZNetworkProgressBlock)downloadProgress
                                  success:(LZNetworkSuccessBlock)success
                                  failure:(LZNetworkFailureBlock)failure;

/**
 @author Lilei
 
 @brief UploadTask
 
 @param request     请求
 @param source      NSData Or NSURL
 @param progress    上传进度
 @param success     请求成功回调
 @param failure     请求失败回调
 
 @return    NSURLSessionUploadTask
 */
- (NSURLSessionUploadTask *)uploadTaskRequest:(NSURLRequest *)request
                                   fromSource:(id)source
                                     progress:(LZNetworkProgressBlock)progress
                                      success:(LZNetworkSuccessBlock)success
                                      failure:(LZNetworkFailureBlock)failure;

/**
 @author Lilei
 
 @brief downloadTask
 
 @param request     请求
 @param progress    下载进度
 @param success     请求成功回调
 @param failure     请求失败回调
 */
- (NSURLSessionDownloadTask *)downloadTaskRequest:(NSURLRequest *)request
                                         progress:(LZNetworkProgressBlock)progress
                                          success:(LZNetworkSuccessBlock)success
                                          failure:(LZNetworkFailureBlock)failure;

#pragma mark - AFNetworkingReachabilityManager
/**
 @author Lilei
 
 @brief 开启网络状态变化监听

 @param finishHandler 完成回调
 */
- (void)networkStatusStartMonitoring:(void (^)(NetworkStatus status))finishHandler;

/**
 @author Lilei
 
 @brief 关闭网络状态变化监听
 */
- (void)networkStatusStopMonitoring;

/**
 @author Lilei
 
 @brief 当前网络状态

 @return NetworkStatus
 */
- (NetworkStatus)networkStatus;

/**
 @author Lilei
 
 @brief 开启网络可达性监听

 @param finishHandler 完成回调
 */
- (void)networkReachabilityStartMonitoring:(void (^)(BOOL reachable))finishHandler;

/**
 @author Lilei
 
 @brief 关闭网络可达性监听
 */
- (void)networkReachabilityStopMonitoring;

/**
 @author Lilei
 
 @brief 当前网络是否可用

 @return BOOL
 */
- (BOOL)networkReachability;

#pragma mark - Other
/**
 @author Lilei
 
 @brief 暂停所有请求任务
 */
- (void)pauseAllRequestTask;

/**
 @author Lilei
 
 @brief 恢复所有请求任务
 */
- (void)resumeAllRequestTask;

/**
 @author Lilei
 
 @brief 设置网络请求拦截类
 
 @param customUrlProtocol NSURLProtocol
 */
- (void)setURLProtocol:(Class)customUrlProtocol;

@end

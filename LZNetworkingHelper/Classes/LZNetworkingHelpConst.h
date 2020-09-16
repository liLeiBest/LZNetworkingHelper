//
//  LZNetworkingHelpConst.h
//  Pods
//
//  Created by Dear.Q on 2017/4/24.
//
//

#ifndef LZNetworkingHelpConst_h
#define LZNetworkingHelpConst_h

/// Http 请求方法
typedef NS_ENUM(NSUInteger, LZHTTPRequestMethod) {
    /// GET
    LZHTTPRequestGET = 0,
    /// HEAD
    LZHTTPRequestHEAD,
    /// PATCH
    LZHTTPRequestPATCH,
    /// POST
    LZHTTPRequestPOST,
    /// PUT
    LZHTTPRequestPUT,
    /// DELETE
    LZHTTPRequestDELETE,
};
typedef NS_ENUM(NSInteger, HttpMethodType) {
    HttpMethodTypeGET = LZHTTPRequestGET,
    HttpMethodTypePOST = LZHTTPRequestPOST,
    HttpMethodTypePUT = LZHTTPRequestPUT,
    HttpMethodTypeDELETE = LZHTTPRequestDELETE,
};

/// 网络状态类型
typedef NS_ENUM(NSInteger, LZNetworkStatus) {
    /// 未知
    LZNetworkStatusUnkonw = -1,
    /// 无网络
    LZNetworkStatusNone = 0,
    /// 移动网络
    LZNetworkStatusMobile = 1,
    /// WIFI
    LZNetworkStatusWIFI = 2,
};
typedef NS_ENUM(NSInteger, NetworkStatus) {
    NetworkStatusUnkonw = LZNetworkStatusUnkonw,
    NetworkStatusNone = LZNetworkStatusNone,
    NetworkStatusMobile = LZNetworkStatusMobile,
    NetworkStatusWIFI = LZNetworkStatusWIFI,
};

#endif /* LZNetworkingHelpConst_h */

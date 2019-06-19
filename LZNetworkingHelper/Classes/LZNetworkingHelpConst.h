//
//  LZNetworkingHelpConst.h
//  Pods
//
//  Created by Dear.Q on 2017/4/24.
//
//

#ifndef LZNetworkingHelpConst_h
#define LZNetworkingHelpConst_h

/** Http请求方法 */
typedef NS_ENUM(NSInteger, HttpMethodType) {
    HttpMethodTypeGET = 0,         // GET
    HttpMethodTypePOST,            // POST
    HttpMethodTypePUT,             // PUT
    HttpMethodTypeDELETE           // DELETE
};

/** 网络类型 */
typedef NS_ENUM(NSInteger, NetworkStatus) {
    NetworkStatusUnkonw = -1,       // 未知
    NetworkStatusNone = 0,          // 无
    NetworkStatusMobile = 1,        // 移动网络
    NetworkStatusWIFI = 2,          // WIFI
};

#endif /* LZNetworkingHelpConst_h */

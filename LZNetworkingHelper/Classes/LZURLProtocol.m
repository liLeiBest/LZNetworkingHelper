//
//  LZURLProtocol.m
//  Pods
//
//  Created by Dear.Q on 16/7/22.
//
//

#import "LZURLProtocol.h"
#import "LZNetworkingHelper.h"

@interface NSURLRequest (MutableCopyWorkaround)

- (id)mutableCopyWorkaround;

@end

@implementation NSURLRequest (MutableCopyWorkaround)

- (id)mutableCopyWorkaround {
	
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                          cachePolicy:[self cachePolicy]
                                                                      timeoutInterval:[self timeoutInterval]];
    [mutableURLRequest setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    if ([self HTTPBodyStream]) {
        [mutableURLRequest setHTTPBodyStream:[self HTTPBodyStream]];
    } else {
        [mutableURLRequest setHTTPBody:[self HTTPBody]];
    }
    
    [mutableURLRequest setHTTPMethod:[self HTTPMethod]];
    
    return mutableURLRequest;
}

@end

static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";

@interface LZURLProtocol()

@property (nonatomic, strong) NSMutableData *cacheData;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) LZNetworkingHelper *networkHelper;

@end

@implementation LZURLProtocol

#pragma mark - LzayLoading
- (LZNetworkingHelper *)networkHelper {
	
    if (nil == _networkHelper ) {
        _networkHelper = [[LZNetworkingHelper alloc] init];
    }
    
    return _networkHelper;
}

#pragma mark - <NSURLProtocol>
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	
    // 只处理http和https请求
    NSString *scheme = [[request URL] scheme];
    if ([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame ||
        [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame) {
		
        // 看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey
                                inRequest:request]) {
            return NO;
        }
        
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return [self redirectHostInRequset:request];
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
	
    id cachedResponse = [self cachedResponseForCurrentRequest];
    if (cachedResponse)  {
		
        LZNetworkingLog(@"serving response from cache");
#if 0
        NSData *data = cachedResponse.data;
        NSString *mimeType = cachedResponse.mimeType;
        NSString *encoding = cachedResponse.encoding;
        // 直接返回缓存的结果，构建一个NSURLResponse对象
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                            MIMEType:mimeType
                                               expectedContentLength:data.length
                                                    textEncodingName:encoding];
        
        [self.client URLProtocol:self
              didReceiveResponse:response
              cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self
                     didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
#endif
    } else {
		
        LZNetworkingLog(@"serving response from remote");
        
        // 打标签，防止无限循环
        NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
        [NSURLProtocol setProperty:@YES
                            forKey:URLProtocolHandledKey
                         inRequest:mutableReqeust];
        
        __weak typeof(self) weakSelf = self;
        self.networkHelper.taskWillPerformHTTPRedirection =
        ^(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
			
            // 处理重定向问题
            if (response != nil) {
				
                NSMutableURLRequest *redirectableRequest = [request mutableCopyWorkaround];
                // 存储
                [weakSelf saveCachedResponse];
                
                [weakSelf.client URLProtocol:weakSelf
                  wasRedirectedToRequest:redirectableRequest
                        redirectResponse:response];
                
                return request;
            } else {
                return request;
            }
        };
        
        self.networkHelper.dataTaskDidReceiveResponse =
        ^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response) {
			
            [weakSelf.client URLProtocol:weakSelf
                  didReceiveResponse:response
                  cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            
            weakSelf.response = response;
            weakSelf.cacheData = [[NSMutableData alloc] init];
            
            return NSURLSessionResponseAllow;
        };
        
        self.networkHelper.dataTaskDidReceiveData =
        ^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
			
            [weakSelf.client URLProtocol:weakSelf
                         didLoadData:data];
            
            [weakSelf.cacheData appendData:data];
        };
        
        self.networkHelper.taskDidComplete =
        ^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
			
            if (error) {
                [weakSelf.client URLProtocol:weakSelf
                        didFailWithError:error];
            } else {
				
                // 存储
                [weakSelf saveCachedResponse];
                
                [weakSelf.client URLProtocolDidFinishLoading:weakSelf];
            }
        };
        
        [self.networkHelper dataTaskRequest:self.request
                             uploadProgress:nil
                           downloadProgress:nil
                                    success:nil
                                    failure:nil];
    }
}

- (void)stopLoading {
	
    self.cacheData = nil;
    self.response = nil;
}

#pragma mark <Private>
/**
 @author Lilei
 
 @brief 重定向或修改网络请求
 
 @param request 原始的请求
 
 @return 处理后的请求
 */
+ (NSURLRequest *)redirectHostInRequset:(NSURLRequest *)request {
	
    if (request.URL.host.length == 0) return request;
    
    NSString *originSchemeString = [request.URL scheme];
    if ([originSchemeString caseInsensitiveCompare:@"hxkid"] == NSOrderedSame) {
		
        NSString *originUrlString = [request.URL absoluteString];
        
        // scheme
        NSRange schemeRange = [originUrlString rangeOfString:originSchemeString];
        originUrlString = [originUrlString stringByReplacingCharactersInRange:schemeRange
                                                                   withString:@"http"];
        // redirectHost
        NSString *originHostString = [request.URL host];
        NSRange hostRange = [originUrlString rangeOfString:originHostString];
		if (hostRange.location == NSNotFound) {
			return [request copy];
		}
        NSString *ip = @"mail.hxkid.com";
        NSString *urlString = [originUrlString stringByReplacingCharactersInRange:hostRange
                                                                       withString:ip];
        NSMutableURLRequest *mutableReqeust = [request mutableCopy];
        mutableReqeust.URL = [NSURL URLWithString:urlString];;
        
        return [mutableReqeust copy];
    } else {
        return request;
    }
}

/**
 @author Lilei
 
 @brief 保存缓存
 */
- (void)saveCachedResponse {
    
}

/**
 @author Lilei
 
 @brief 获取当前请求的缓存
 
 @return Response
 */
- (id )cachedResponseForCurrentRequest {
    return nil;
}

@end

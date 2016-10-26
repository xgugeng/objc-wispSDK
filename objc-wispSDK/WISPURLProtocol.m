//
//  WISPURLProtol.m
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/8/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSWeakTimer.h"
#import "QNNetworkInfo.h"
#import "QNResolver.h"
#import "QNDnsManager.h"

#import "WISPURLProtocol.h"
#import "WISPURLProtocol+report.h"
#import "WISPURLModel.h"
#import "WISPURLSessionConfiguration.h"
#import "WISPURLModelMgr.h"

NSString *const WISPEnabled = @"WISPEnable";
NSString *const NetDiagSite = @"http://fusion-netdiag.qiniu.io";
NSInteger const WISPSuccStatusCode = 200;

static BOOL sWISPConfigLoaded = NO;
static int sWISPConfigVersion = 0;
static int sWISPFreq = 0;
static BOOL sWISPDns = NO;
static NSString *sAppID;
static NSString *sAppKey;
static NSMutableArray *sWISPPermitDomains;
static NSMutableArray *sWISPForbidDomains;
static MSWeakTimer *sWISPTimer;

@interface WISPURLProtocol ()<NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{}
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic,strong) WISPURLModel *URLModel;
@end

@implementation WISPURLProtocol
@synthesize URLModel;

#pragma mark - public
+ (NSString*)appID {
    return sAppID;
}

+ (NSString*)appKey {
    return sAppKey;
}

+ (void)rePullConfigifNeeded:(int)newConfigVersion {
    if (newConfigVersion > sWISPConfigVersion) {
        [self requestForConfig:sAppID];
    }
}

+ (void)enableWithAppID:(NSString *)appID
              andAppKey:(NSString *)appKey {
    sAppID = [[NSString alloc] initWithString:appID];
    sAppKey = [[NSString alloc] initWithString:appKey];
    
    [[NSUserDefaults standardUserDefaults] setDouble:YES forKey:WISPEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    WISPURLSessionConfiguration * sessionConfiguration=[WISPURLSessionConfiguration defaultConfiguration];
    
    [NSURLProtocol registerClass:[WISPURLProtocol class]];
    if (![sessionConfiguration isSwizzle]) {
        [sessionConfiguration load];
    }
    
    // request for config
    [self requestForConfig:appID];
}

+ (void)disable {
    [[NSUserDefaults standardUserDefaults] setDouble:NO forKey:WISPEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    WISPURLSessionConfiguration * sessionConfiguration=[WISPURLSessionConfiguration defaultConfiguration];
    
    [NSURLProtocol unregisterClass:[WISPURLProtocol class]];
    if ([sessionConfiguration isSwizzle]) {
        [sessionConfiguration unload];
    }
    
    sWISPPermitDomains = nil;
    sWISPForbidDomains = nil;
    [sWISPTimer invalidate];
    sWISPTimer = nil;
    sAppID = nil;
}

+ (BOOL)isEnabled {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:WISPEnabled] boolValue];
}

#pragma mark - superclass methods
+ (void)load {
    
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 配置尚未加载
    if (!sWISPConfigLoaded) {
        return NO;
    }
    
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    // SDK主动发送的数据
    if ([NSURLProtocol propertyForKey:@"WISPURLProtocol" inRequest:request] ) {
        return NO;
    }
    
    NSString *host = request.URL.host;
    
    // 检查黑名单
    for (NSString *domain in sWISPForbidDomains) {
        if ([domain hasPrefix:@"*."]) { // 泛域名
            // 去掉开头星号
            NSString *suffixDomain = [domain substringFromIndex:1];
            if ([host hasSuffix:suffixDomain]) {
                return NO;
            }
        }
        else {  // 域名
            if ([host isEqualToString:domain]) {
                return NO;
            }
        }
    }
    
    // 检查白名单
    for (NSString *domain in sWISPPermitDomains) {
        if ([domain hasPrefix:@"*."]) { // 泛域名
            // 去掉开头星号
            NSString *suffixDomain = [domain substringFromIndex:1];
            if ([host hasSuffix:suffixDomain]) {
                return YES;
            }
        }
        else {  // 域名
            if ([host isEqualToString:domain]) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setValue:mutableRequest.URL.host forHTTPHeaderField:@"Host"];
    [NSURLProtocol setProperty:mutableRequest.URL.absoluteString
                        forKey:@"WISPOrigURL"
                     inRequest:mutableRequest];
    [NSURLProtocol setProperty:@YES
                        forKey:@"WISPURLProtocol"
                     inRequest:mutableRequest];
    
    if (sWISPDns && [mutableRequest.URL.scheme isEqualToString:@"http"]) {
        NSMutableArray *resolvers = [[NSMutableArray alloc] init];
        [resolvers addObject:[QNResolver systemResolver]];
        [resolvers addObject:[[QNResolver alloc] initWithAddress:@"119.29.29.29"]];
        QNDnsManager *dns = [[QNDnsManager alloc] init:resolvers networkInfo:[QNNetworkInfo normal]];
        UInt64 dnsStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
        NSURL *replacedURL = [dns queryAndReplaceWithIP:mutableRequest.URL];
        UInt64 dnsEndTime = [[NSDate date] timeIntervalSince1970] * 1000;
        [NSURLProtocol setProperty:[NSString stringWithFormat:@"%llu", dnsEndTime - dnsStartTime]
                            forKey:@"WISPDNSTime"
                         inRequest:mutableRequest];
        [NSURLProtocol setProperty:replacedURL.host
                            forKey:@"WISPHostIP"
                         inRequest:mutableRequest];
        mutableRequest.URL = replacedURL;
    }
    
    return [mutableRequest copy];
}

- (void)startLoading {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                      delegate:self
                                              startImmediately:YES];
#pragma clang diagnostic pop
    
    URLModel = [[WISPURLModel alloc] init];
    URLModel.request = self.request;
    URLModel.startTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    URLModel.responseTimeStamp = 0;
    URLModel.responseDataLength = 0;
    
    NSTimeInterval myID = [[NSDate date] timeIntervalSince1970];
    double randomNum = ((double)(arc4random() % 100))/10000;
    URLModel.myID = myID + randomNum;
}

- (void)stopLoading {
    [self.connection cancel];
    URLModel.response = (NSHTTPURLResponse *)self.response;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
    URLModel.responseStatusCode = (int)error.code;
    URLModel.errMsg = error.localizedDescription;
    [[WISPURLModelMgr defaultManager] addModel:URLModel];
    [[self client] URLProtocol:self didFailWithError:error];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [[self client] URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection
didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [[self client] URLProtocol:self didCancelAuthenticationChallenge:challenge];
}

#pragma mark - NSURLConnectionDataDelegate
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)response {
    if (response != nil){
        self.response = response;
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    self.response = response;
    URLModel.responseTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
}

// 一次请求数据，会多次触发这个函数
// 所以endTimeStamp和responseDataLength也会多次更新
- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data {
    URLModel.endTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    URLModel.responseDataLength += data.length;
    
    [[self client] URLProtocol:self didLoadData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[WISPURLModelMgr defaultManager] addModel:URLModel];
    
    [[self client] URLProtocolDidFinishLoading:self];
}

#pragma mark - Utils
+ (void)requestForConfig:(NSString *)appID {
    sWISPConfigLoaded = NO;
    
    sWISPForbidDomains = [NSMutableArray arrayWithCapacity:1];
    sWISPPermitDomains = [NSMutableArray arrayWithCapacity:1];
    
    NSString *site = [NetDiagSite mutableCopy];
    NSString *urlString = [site stringByAppendingFormat:@"/webapi/fusion/app?id=%@", appID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    [mutableRequest setHTTPMethod:@"GET"];
    [NSURLProtocol setProperty:@YES
                        forKey:@"WISPURLProtocol"
                     inRequest:mutableRequest];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionTask * task = [session dataTaskWithRequest:mutableRequest
                                         completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            return;
        }
        
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSInteger responseStatusCode = [httpResponse statusCode];
        if (responseStatusCode == WISPSuccStatusCode) {
            NSDictionary *resDict = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:NSJSONReadingMutableContainers
                                  error:&error];
            if (error) {
                return;
            }
            NSDictionary *appDict = [resDict valueForKey:@"app"];
            sWISPConfigVersion = [[appDict valueForKey:@"version"] intValue];
            sWISPFreq = [[appDict valueForKey:@"freq"] intValue];
            sWISPDns = [[appDict valueForKey:@"dns"] boolValue];
            NSArray *permitDomains = [appDict valueForKey:@"permitDomains"];
            for (id item in permitDomains) {
                [sWISPPermitDomains addObject:[(NSDictionary*)item valueForKey:@"domain"]];
            }
            
            NSArray *forbidDomains = [appDict valueForKey:@"forbidDomains"];
            for (id item in forbidDomains) {
                [sWISPForbidDomains addObject:[(NSDictionary*)item valueForKey:@"domain"]];
            }

            sWISPTimer = [MSWeakTimer scheduledTimerWithTimeInterval:sWISPFreq * 60
                                                              target:self
                                                            selector:@selector(sendReport)
                                                            userInfo:nil
                                                             repeats:YES
                                                       dispatchQueue:dispatch_get_main_queue()];
            sWISPConfigLoaded = YES;
        }
    }];
    [task resume];
}

@end

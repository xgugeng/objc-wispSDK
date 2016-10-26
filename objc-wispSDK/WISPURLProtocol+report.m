//
//  WISPURLProtocol+report.m
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/9/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#import "WISPSysDetector.h"
#import "WISPURLProtocol.h"
#import "WISPURLProtocol+report.h"
#import "WISPSysDetector.h"
#import "WISPURLModelMgr.h"
#import "WISPURLModel.h"
#import "NSData+GZIP.h"

NSString *const WISPSite = @"https://wisp.qiniu.io";
NSString *const WISPSDKVersion = @"0.0.3";

@implementation WISPURLProtocol (report)

+ (void)sendReport {
    NSMutableArray *requests = [[WISPURLModelMgr defaultManager] allModels];
    if (requests == nil || [requests count] == 0) {
        return;
    }
    
    NSMutableArray *reports = [NSMutableArray arrayWithCapacity:[requests count]];
    
    WISPSysDetector *sysDetector = [WISPSysDetector defaultDetector];
    NSString *sysName = [sysDetector systemName];
    NSString *sysVersion = [sysDetector systemVersion];
    NSString *machineName = [sysDetector machineName];
    NSString *deviceID = [sysDetector UUIDString];
    NSString *netStatus = [sysDetector netStatus];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    NSString *appID = [self appID];
    for (WISPURLModel *req in requests) {
        NSString *url = req.requestURLString;
        NSString *domain = req.requestDomain;
        NSString *hostIP = req.requestHostIP;
        UInt64 sendTime = req.startTimestamp;
        UInt64 dnsTime = req.dnsTime;
        
        SInt64 firstResTime = (req.responseTimeStamp > sendTime) ? (req.responseTimeStamp - sendTime) : -1;
        SInt64 dataLen = req.responseDataLength;
        SInt64 dlTime = (req.endTimestamp > sendTime) ? (req.endTimestamp - sendTime) : -1;
        int statusCode = req.responseStatusCode;
        NSString *msg = req.errMsg;
        if (msg == nil) {
            msg = @"";
        }
       
        BOOL reachable = YES;
        if (statusCode != 200 || ![msg isEqualToString:@""])
            reachable = NO;
        
        NSDictionary *report = @{
                                 @"Os": sysName,
                                 @"SysVersion": sysVersion,
                                 @"DeviceProvider": machineName,
                                 @"DeviceID": deviceID,
                                 @"NetType": netStatus,
                                 @"Version": WISPSDKVersion,
                                 @"AppVersion": appVersion,
                                 @"AppID": appID,
                                 @"Url": url,
                                 @"Domain": domain,
                                 @"HostIp": hostIP,
                                 @"Stime": [NSNumber numberWithLongLong:sendTime],
                                 @"DnsTime": [NSNumber numberWithLongLong:dnsTime],
                                 @"FirstPacketTime": [NSNumber numberWithLongLong:firstResTime],
                                 @"Size": [NSNumber numberWithLongLong:dataLen],
                                 @"TotalTime": [NSNumber numberWithLongLong:dlTime],
                                 @"Code": [NSNumber numberWithInt:statusCode],
                                 @"Reachable": [NSNumber numberWithBool:reachable],
                                 @"Message": msg
                                 };
        [reports addObject:report];
    }
   
    NSDictionary *data = @{
                           @"data": reports
                           };
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&writeError];
    if (writeError != nil) {
        NSLog(@"Convent to JSON failed: %@", [writeError localizedDescription]);
        return;
    }
    
    NSData *gzippedData = [jsonData gzippedData];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)gzippedData.length];
   
    NSURL *url = [self reportURL];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    [mutableRequest setHTTPMethod:@"POST"];
    [mutableRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [mutableRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    [mutableRequest setValue:@"UTF-8" forHTTPHeaderField:@"Charset"];
    [mutableRequest setValue:@"*/*" forHTTPHeaderField:@"accept"];
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setHTTPBody:gzippedData];
    
    [NSURLProtocol setProperty:@YES
                        forKey:@"WISPURLProtocol"
                     inRequest:mutableRequest];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionTask * task = [session dataTaskWithRequest:mutableRequest
                                         completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                             if (error != nil) {
                                                 NSLog(@"send report failed: %@", error.localizedDescription);
                                                 return;
                                             }
                                             
                                             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                                             NSInteger responseStatusCode = [httpResponse statusCode];
                                             if (responseStatusCode == 200) {
                                                 NSDictionary *resDict = [NSJSONSerialization JSONObjectWithData:data
                                                                                                         options:NSJSONReadingMutableContainers error:&error];
                                                 if (error != nil) {
                                                     return;
                                                 }
                                                 
                                                 int configVersion = [[resDict valueForKey:@"version"] intValue];
                                                 [self rePullConfigifNeeded:configVersion];
                                             }
                                         }];
    [task resume];
  
    [[WISPURLModelMgr defaultManager] removeAllModels];
}

+ (NSURL*)reportURL {
    NSString *site = [WISPSite mutableCopy];
    NSString *path = @"/webapi/fusion/encodingLogs";
    UInt64 timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    NSString *tobeSigned = [path stringByAppendingFormat:@"%@%llu%@", [self appID], timeStamp, [self appKey]];
    NSString *sign = [self md5:tobeSigned];
    NSString *urlString = [site stringByAppendingFormat:@"%@?id=%@&time=%llu&sign=%@", path, [self appID], timeStamp, sign];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

+ (NSString*)md5:(NSString*)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (int)strlen(cStr), digest); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

@end

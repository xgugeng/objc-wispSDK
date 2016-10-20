//
//  WISPSysDetector.m
//  wisp-iOS
//
//  Created by Guoqing Geng on 9/29/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "SAMKeychain.h"
#import <sys/utsname.h>
#import "WISPSysDetector.h"
#import "Reachability.h"

@implementation WISPSysDetector

+ (WISPSysDetector *)defaultDetector {
    static WISPSysDetector *staticDetector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticDetector = [[WISPSysDetector alloc] init];
    });
    
    return staticDetector;
}

- (NSString *)systemName {
    return [[UIDevice currentDevice] systemName];
}

- (NSString *)systemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)machineName {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *machine = [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
    return machine;
}

- (NSString *)UUIDString {
    
    NSString *appName=[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    
    NSString *strApplicationUUID = [SAMKeychain passwordForService:appName account:@"incoding"];
    if (strApplicationUUID == nil)
    {
        strApplicationUUID  = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [SAMKeychain setPassword:strApplicationUUID forService:appName account:@"incoding"];
    }
    
    return strApplicationUUID;
}

- (NSString *)netStatus {
    Reachability *reach = [Reachability reachabilityWithHostName:@"My Iphone"];
    switch ([reach currentReachabilityStatus]) {
        case ReachableViaWiFi:
            return @"WIFI";
            break;
        case ReachableViaWWAN:
            return @"MOBILE";
            break;
            
        default:
            break;
    }
    
    return nil;
}

@end
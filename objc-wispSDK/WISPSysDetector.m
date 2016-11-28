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
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

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
    
    NSString *machineCode = [NSString stringWithCString:systemInfo.machine
                                           encoding:NSUTF8StringEncoding];
    static NSDictionary *machineNameByCode = nil;
    if (!machineNameByCode) {
        machineNameByCode = @{
                              @"i386"      :@"Simulator",
                              @"x86_64"    :@"Simulator",
                              @"iPod1,1"   :@"iPod Touch",        // (Original)
                              @"iPod2,1"   :@"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   :@"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   :@"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   :@"iPod Touch",        // (6th Generation)
                              @"iPhone1,1" :@"iPhone",            // (Original)
                              @"iPhone1,2" :@"iPhone",            // (3G)
                              @"iPhone2,1" :@"iPhone",            // (3GS)
                              @"iPad1,1"   :@"iPad",              // (Original)
                              @"iPad2,1"   :@"iPad 2",            //
                              @"iPad3,1"   :@"iPad",              // (3rd Generation)
                              @"iPhone3,1" :@"iPhone 4",          // (GSM)
                              @"iPhone3,3" :@"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" :@"iPhone 4S",         //
                              @"iPhone5,1" :@"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" :@"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   :@"iPad",              // (4th Generation)
                              @"iPad2,5"   :@"iPad Mini",         // (Original)
                              @"iPhone5,3" :@"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" :@"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" :@"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" :@"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" :@"iPhone 6 Plus",     //
                              @"iPhone7,2" :@"iPhone 6",          //
                              @"iPhone8,1" :@"iPhone 6S",         //
                              @"iPhone8,2" :@"iPhone 6S Plus",    //
                              @"iPhone8,4" :@"iPhone SE",         //
                              @"iPhone9,1" :@"iPhone 7",          //
                              @"iPhone9,3" :@"iPhone 7",          //
                              @"iPhone9,2" :@"iPhone 7 Plus",     //
                              @"iPhone9,4" :@"iPhone 7 Plus",     //
                              
                              @"iPad4,1"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   :@"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   :@"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,7"   :@"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad6,7"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
                              @"iPad6,8"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
                              @"iPad6,3"   :@"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   :@"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
                              };
    }
    NSString *readableMachine = [machineNameByCode objectForKey:machineCode];
    if (!readableMachine) {
        if ([machineCode rangeOfString:@"iPod"].location != NSNotFound) {
            readableMachine = @"iPod Touch";
        }
        else if([machineCode rangeOfString:@"iPad"].location != NSNotFound) {
            readableMachine = @"iPad";
        }
        else if([machineCode rangeOfString:@"iPhone"].location != NSNotFound){
            readableMachine = @"iPhone";
        }
        else {
            readableMachine = @"Unknown";
        }
    }
    
    return [readableMachine stringByReplacingOccurrencesOfString: @","
                                              withString: @"-"];
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
        case ReachableVia2G:
            return @"2G";
            break;
        case ReachableVia3G:
            return @"3G";
            break;
        case ReachableVia4G:
            return @"4G";
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (NSString *)simType {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mcc = [carrier mobileCountryCode];
    NSString *mnc = [carrier mobileNetworkCode];
    NSString *imsi = [NSString stringWithFormat:@"%@%@", mcc, mnc];
    NSDictionary *dict = @{
                           @"46000":@"中国移动",
                           @"46002":@"中国移动",
                           @"46007":@"中国移动",
                           @"46001":@"中国联通",
                           @"46006":@"中国联通",
                           @"46009":@"中国联通",
                           @"46003":@"中国电信",
                           @"46005":@"中国电信",
                           @"46011":@"中国电信",
                           };
    return [dict objectForKey:imsi];
}

@end
//
//  WISPURLProtocol.h
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/8/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#ifndef WISPURLProtocol_h
#define WISPURLProtocol_h

@interface WISPURLProtocol : NSURLProtocol

+ (void)enableWithAppID:(NSString*)appID
              andAppKey:(NSString*)appKey;
+ (void)disable;
+ (BOOL)isEnabled;
+ (NSString*)appID;
+ (NSString*)appKey;
+ (void)rePullConfigifNeeded:(int)newConfigVersion;

@end

#endif /* WISPURLProtocol_h */

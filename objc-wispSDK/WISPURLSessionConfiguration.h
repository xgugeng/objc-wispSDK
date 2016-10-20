//
//  WISPURLSessionConfiguration.h
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/8/16.
//  Copyright © 2016 qiniu. All rights reserved.
//
#ifndef WISPURLSessionConfiguration_h
#define WISPURLSessionConfiguration_h

@interface WISPURLSessionConfiguration : NSObject

@property (nonatomic, assign) BOOL isSwizzle;

+ (WISPURLSessionConfiguration *)defaultConfiguration;
- (void)load;
- (void)unload;

@end

#endif

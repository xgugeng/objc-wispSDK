//
//  WISPURLModelMgr.h
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/8/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#ifndef WISPURLModelMgr_h
#define WISPURLModelMgr_h

@class WISPURLModel;

@interface WISPGroupData : NSObject
@end

@interface WISPErrorData : NSObject
@end

@interface WISPURLModelMgr : NSObject
+ (WISPURLModelMgr *)defaultManager;
- (void)addModel:(WISPURLModel*)newModel;
- (void)removeAllModels;
- (NSString *)groupDataString;
- (NSString *)errorDataString;
@end


#endif /* WISPURLModelMgr_h */
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

@interface WISPURLModelMgr : NSObject
+ (WISPURLModelMgr *)defaultManager;
- (void)addModel:(WISPURLModel*)newModel;
- (void)removeAllModels;
- (NSMutableArray *)allModels;
@end


#endif /* WISPURLModelMgr_h */

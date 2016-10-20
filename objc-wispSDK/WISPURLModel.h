//
//  WISPURLModel.h
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/8/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#ifndef WISPURLModel_h
#define WISPURLModel_h

@interface WISPURLModel : NSObject

@property (nonatomic, strong, nonnull) NSURLRequest *request;
@property (nonatomic, strong, nonnull) NSHTTPURLResponse *response;
@property (nonatomic, assign) double myID;
@property (nonatomic, assign) UInt64 startTimestamp;
@property (nonatomic, assign) UInt64 endTimestamp;
@property (nonatomic, strong, nonnull) NSString *errMsg;

//request
@property (nonatomic, strong, nonnull) NSString *requestURLString;
@property (nonatomic, strong, nonnull) NSString *requestDomain;
@property (nonatomic, assign) double requestTimeoutInterval;
@property (nonatomic, strong, nonnull) NSString *requestHTTPMethod;
@property (nonatomic, strong, nonnull) NSString *requestHostIP;

//response
@property (nonatomic, assign) int responseStatusCode;
@property (nonatomic, assign) UInt64 responseTimeStamp;
@property (nonatomic, assign) UInt64 dnsTime;
@property (nonatomic, assign) NSInteger responseDataLength;

@end

#endif /* WISPURLModel_h */

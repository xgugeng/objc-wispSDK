//
//  WISPURLModelMgr.m
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/8/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WISPURLModelMgr.h"
#import "WISPURLModel.h"

NSInteger const REQUEST_LIMIT = 1000;

# pragma mark WISPGroupData
@interface WISPGroupData()
{}

@property (copy) NSString *domain;
@property (assign) UInt8 domainType;
@property (copy) NSMutableDictionary *ipHit;
@property (copy) NSString *groupPath;
@property (assign) UInt64 stime; // s
@property (assign) UInt64 totalNum;
@property (assign) UInt64 dnsTime;
@property (assign) UInt64 avail;
@property (assign) UInt64 firstPacketTime;
@property (assign) UInt64 size;
@property (assign) UInt64 totalTime;
@property (assign) UInt64 code2xx;
@property (assign) UInt64 code3xx;
@property (assign) UInt64 code4xx;
@property (assign) UInt64 code5xx;
@property (assign) UInt64 codeOther;

@end

@implementation WISPGroupData
- (id)init {
    self = [super init];
    if (self) {
        _ipHit = [NSMutableDictionary dictionary];
    }
    
    return self;
}
@end

# pragma mark WISPErrorData
@interface WISPErrorData()
{}

@property (copy) NSString *url;
@property (copy) NSString *domain;
@property (copy) NSString *mimeType;
@property (assign) UInt8 domainType;
@property (copy) NSString *ip;
@property (assign) UInt64 stime; // ms
@property (assign) UInt64 dnsTime;
@property (copy) NSString *reachable;
@property (assign) int code;
@property (copy) NSString *message;
@property (assign) UInt64 firstPacketTime;
@property (assign) UInt64 size;
@property (assign) UInt64 totalTime;

@end

@implementation WISPErrorData
@end



# pragma mark WISPURLModelMgr
@interface WISPURLModelMgr() {
    NSMutableArray *allGroupData;
    NSMutableArray *allErrorData;
}

@end

@implementation WISPURLModelMgr

- (id)init {
    self = [super init];
    if (self) {
        allGroupData = [NSMutableArray arrayWithCapacity:1];
        allErrorData = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

+ (WISPURLModelMgr *)defaultManager {
    
    static WISPURLModelMgr *staticManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticManager = [[WISPURLModelMgr alloc] init];
    });
    return staticManager;
    
}

- (void)addModel:(WISPURLModel *)newModel {
    if ([allGroupData count] > REQUEST_LIMIT) {
        return;
    }
    
    BOOL isExisted = NO;
    for (WISPGroupData *data in allGroupData) {
        if ([data.domain isEqualToString:newModel.requestDomain]
            && [data.groupPath isEqualToString:newModel.requestGroupPath]
            && data.stime == newModel.startTimestampViaMin) {
            
            isExisted = YES;
            if (newModel.requestHostIP != nil) {
                id hitValue = [data.ipHit objectForKey:newModel.requestHostIP];
                if (hitValue != nil) {
                    int hitCount = [hitValue intValue];
                    [data.ipHit setValue: [NSNumber numberWithInt: (hitCount+1)]
                                  forKey: newModel.requestHostIP];
                } else {
                    [data.ipHit setValue:[NSNumber numberWithInt:1] forKey:newModel.requestHostIP];
                }
            }
            
            data.totalNum++;
            data.dnsTime += newModel.dnsTime;
            data.firstPacketTime += ((newModel.responseTimeStamp > newModel.startTimestamp) ? (newModel.responseTimeStamp - newModel.startTimestamp) : 0);
            data.size += newModel.responseDataLength;
            data.totalTime += ((newModel.endTimestamp > newModel.startTimestamp) ? (newModel.endTimestamp - newModel.startTimestamp) : 0);
            
            if (newModel.responseStatusCode == 200) {
                data.avail++;
            }
            
            switch (newModel.responseStatusCode/100) {
                case 5:
                    data.code5xx++;
                    break;
                case 4:
                    data.code4xx++;
                    break;
                case 3:
                    data.code3xx++;
                    break;
                case 2:
                    data.code2xx++;
                    break;
                default:
                    data.codeOther++;
                    break;
            }
            
            break;
        }
    }
    
    if (!isExisted) {
        WISPGroupData *data = [[WISPGroupData alloc] init];
        data.domain = newModel.requestDomain;
        data.domainType = newModel.requestDomainType;
        if (newModel.requestHostIP != nil) {
            [data.ipHit setValue: [NSNumber numberWithInt:1]
                          forKey: newModel.requestHostIP];
        }
        data.groupPath = newModel.requestGroupPath;
        data.stime = newModel.startTimestampViaMin;
        data.totalNum = 1;
        data.dnsTime = newModel.dnsTime;
        data.firstPacketTime = ((newModel.responseTimeStamp > newModel.startTimestamp) ? (newModel.responseTimeStamp - newModel.startTimestamp) : 0);
        data.size = newModel.responseDataLength;
        data.totalTime = ((newModel.endTimestamp > newModel.startTimestamp) ? (newModel.endTimestamp - newModel.startTimestamp) : 0);
        
        if (newModel.responseStatusCode == 200) {
            data.avail = 1;
        }
        
        switch (newModel.responseStatusCode/100) {
            case 5:
                data.code5xx = 1;
                break;
            case 4:
                data.code4xx = 1;
                break;
            case 3:
                data.code3xx = 1;
                break;
            case 2:
                data.code2xx = 1;
                break;
            default:
                data.codeOther = 1;
                break;
        }
        
        [allGroupData addObject:data];
    }
    
    // Insert into Error Data
    if (newModel.responseStatusCode != 200) {
        WISPErrorData *data = [[WISPErrorData alloc] init];
        data.url = newModel.requestURLString;
        data.domain = newModel.requestDomain;
        data.domainType = newModel.requestDomainType;
        data.mimeType = newModel.responseMIME;
    
        data.ip = newModel.requestHostIP;
        data.stime = newModel.startTimestamp;
        data.dnsTime = newModel.dnsTime;
        data.reachable = @"false";
        data.code = newModel.responseStatusCode;
        data.message = newModel.errMsg;
        data.firstPacketTime = ((newModel.responseTimeStamp > newModel.startTimestamp) ? (newModel.responseTimeStamp - newModel.startTimestamp) : 0);
        data.size = newModel.responseDataLength;
        data.totalTime = ((newModel.endTimestamp > newModel.startTimestamp) ? (newModel.endTimestamp - newModel.startTimestamp) : 0);
        
        [allErrorData addObject:data];
    }
}

- (NSString *)groupDataString {
    NSString *dataString = @"";
    
    for (WISPGroupData *data in allGroupData) {
        dataString = [dataString stringByAppendingFormat:@"%@,%hhu,"
                      , [self formatString: data.domain]
                      , data.domainType];
        
        for (NSString *ip in data.ipHit) {
            int hitCount = [[data.ipHit valueForKey:ip] intValue];
            dataString = [dataString stringByAppendingFormat:@"%@:%d|", ip, hitCount];
        }
        if ([dataString hasSuffix:@"|"]) {
            dataString = [dataString substringToIndex:[dataString length] - 1];
        }
        
        dataString = [dataString stringByAppendingFormat:@",%@,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu\n"
                      , data.groupPath
                      , data.stime
                      , data.totalNum
                      , data.dnsTime
                      , data.avail
                      , data.firstPacketTime
                      , data.size
                      , data.totalNum
                      , data.code2xx
                      , data.code3xx
                      , data.code4xx
                      , data.code5xx
                      , data.codeOther];
    }
    
    return dataString;
}

- (NSString *)errorDataString {
    NSString *dataString = @"";
    
    for (WISPErrorData *data in allErrorData) {
        dataString = [dataString stringByAppendingFormat:@"%@,%@,%@,%hhu,%@,%llu,%llu,%@,%d,%@,%llu,%llu,%llu\n"
                      , [self formatString: data.url]
                      , data.mimeType
                      , [self formatString: data.domain]
                      , data.domainType
                      , data.ip
                      , data.stime
                      , data.dnsTime
                      , data.reachable
                      , data.code
                      , [self formatString: data.message]
                      , data.firstPacketTime
                      , data.size
                      , data.totalTime];
    }
    
    return dataString;
}

- (void)removeAllModels {
    [allGroupData removeAllObjects];
    [allErrorData removeAllObjects];
}


- (NSString *)formatString:(NSString *)str {
    NSString *exBackslash = [str stringByReplacingOccurrencesOfString: @"\\"
                                                           withString: @"\\\\"];
    NSString *exComma = [exBackslash stringByReplacingOccurrencesOfString: @","
                                                               withString:@"\\,"];
    return [exComma stringByReplacingOccurrencesOfString:@"\n"
                                              withString:@"\\n"];
}

@end
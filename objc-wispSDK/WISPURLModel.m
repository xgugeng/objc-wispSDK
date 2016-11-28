//
//  WISPURLModel.m
//  wisp-iOS
//
//  Created by Guoqing Geng on 10/8/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WISPURLModel.h"

@implementation WISPURLModel
@synthesize request, response;

- (void)setRequest:(NSURLRequest *)newRequest {
    request = newRequest;
    
    self.requestURLString = [NSURLProtocol propertyForKey:@"WISPOrigURL" inRequest:request];
    self.requestDomain = [request valueForHTTPHeaderField:@"Host"];
    
    self.requestTimeoutInterval = [[NSString stringWithFormat:@"%.1lf", request.timeoutInterval] doubleValue];
    self.requestHTTPMethod = request.HTTPMethod;
    
    self.dnsTime = [[NSURLProtocol propertyForKey:@"WISPDNSTime" inRequest:request] longLongValue];
    self.requestHostIP = [NSURLProtocol propertyForKey:@"WISPHostIP" inRequest:request];
}

- (void)setResponse:(NSHTTPURLResponse *)newResponse {
    response = newResponse;
}

@end

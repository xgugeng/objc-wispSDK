//
//  CLLocationManager+Simulator.m
//  wisp-iOS
//
//  Created by Guoqing Geng on 9/29/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLLocationManager+Simulator.h"

@implementation CLLocationManager (Simulator)

- (void)startUpdatingLocation
{
    CLLocationCoordinate2D coord;
    coord.latitude = 39.92f;
    coord.longitude = 116.46f;
    
    CLLocation *setLocation= [[CLLocation alloc] initWithCoordinate:coord
                                                            altitude:0
                                                  horizontalAccuracy:100
                                                    verticalAccuracy:100
                                                              course:1
                                                               speed:1
                                                           timestamp:[NSDate date]];
    
    NSArray *locations = [[NSArray alloc] initWithObjects:setLocation, nil];
    [self.delegate locationManager:self didUpdateLocations:locations];
}

@end
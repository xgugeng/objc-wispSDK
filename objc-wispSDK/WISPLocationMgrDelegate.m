//
//  WISPLocationManager.m
//  wisp-iOS
//
//  Created by Guoqing Geng on 9/28/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WISPLocationMgrDelegate.h"

@interface WISPLocationMgrDelegate () <CLLocationManagerDelegate>
{
    CLLocationManager *locationMgr;
    NSString *province;
    NSString *city;
}
@end

@implementation WISPLocationMgrDelegate

- (void)locate {
    if ([CLLocationManager locationServicesEnabled]) {
        locationMgr = [[CLLocationManager alloc] init];
        locationMgr.delegate = self;
        locationMgr.desiredAccuracy = kCLLocationAccuracyKilometer;
        locationMgr.distanceFilter = 1000.0f;
        
        province = [[NSString alloc] init];
        city = [[NSString alloc] init];
        
        [locationMgr startUpdatingLocation];
    }
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    // do nothing
}

//定位成功
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [locationMgr stopUpdatingLocation];
    CLLocation *currentLocation = [locations lastObject];
    if (currentLocation.verticalAccuracy < 0
        || currentLocation.horizontalAccuracy < 0) {
        // 无效精度
        return;
    }
    
    
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    
    //反编码
    [geoCoder reverseGeocodeLocation:currentLocation
                   completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count > 0) {
            CLPlacemark *placeMark = placemarks[0];
            province = placeMark.administrativeArea;
            city = placeMark.locality;
            if (!city) {
                city = @"无法定位当前城市";
            }
            NSLog(@"%@", province);
            NSLog(@"%@", city);
            NSLog(@"%@", placeMark.name);
        }
        else if (error == nil && placemarks.count == 0) {
            NSLog(@"No location and error return");
        }
        else if (error) {
            NSLog(@"location error: %@ ", error);
        }
        
    }];
}

@end

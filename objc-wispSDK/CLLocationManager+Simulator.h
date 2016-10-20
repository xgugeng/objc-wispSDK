//
//  CLLocationManager+Simulator.h
//  wisp-iOS
//
//  Created by Guoqing Geng on 9/29/16.
//  Copyright © 2016 qiniu. All rights reserved.
//

#ifndef CLLocationManager_Simulator_h
#define CLLocationManager_Simulator_h

#import <CoreLocation/CoreLocation.h>

#ifdef TARGET_IPHONE_SIMULATOR
@interface CLLocationManager (Simulator)
@end
#endif // TARGET_IPHONE_SIMULATOR

#endif /* CLLocationManager_Simulator_h */

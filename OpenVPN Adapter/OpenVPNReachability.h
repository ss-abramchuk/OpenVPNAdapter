//
//  OpenVPNReachability.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#import <Foundation/Foundation.h>
#import "OpenVPNReachabilityStatus.h"

@interface OpenVPNReachability : NSObject

@property (readonly, nonatomic) BOOL isTracking;
@property (readonly, nonatomic) OpenVPNReachabilityStatus reachabilityStatus;

- (nonnull instancetype)init;

- (void)startTrackingWithCallback:(nonnull void (^)(OpenVPNReachabilityStatus))callback;
- (void)stopTracking;

@end

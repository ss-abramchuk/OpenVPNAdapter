//
//  OpenVPNReachability.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#import <Foundation/Foundation.h>
#import "OpenVPNReachabilityStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNReachability : NSObject

@property (readonly, nonatomic) BOOL isTracking;
@property (readonly, nonatomic) OpenVPNReachabilityStatus reachabilityStatus;

- (instancetype)init;

- (void)startTrackingWithCallback:(nullable void (^)(OpenVPNReachabilityStatus))callback;
- (void)stopTracking;

@end

NS_ASSUME_NONNULL_END

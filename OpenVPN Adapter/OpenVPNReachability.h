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

@property (readonly, nonatomic) OpenVPNReachabilityStatus reachabilityStatus;

- (nonnull instancetype)initWatchingWWAN:(BOOL)watchWWAN watchingWiFi:(BOOL)watchWiFi;

- (void)startTracking;
- (void)stopTracking;

@end

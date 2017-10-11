//
//  OpenVPNReachability.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#import <openvpn/apple/reachable.hpp>

#import "OpenVPNReachability.h"
#import "OpenVPNReachability+Internal.h"

@interface OpenVPNReachability () {
    BOOL _isTracking;
}

@property (assign, nonatomic) OpenVPNReachabilityTracker *tracker;
@property (assign, nonatomic) Reachability *reachability;

@property (copy, nonatomic) void (^ reachabilityStatusChangedBlock)(OpenVPNReachabilityStatus);

@end

@implementation OpenVPNReachability (Internal)

- (void)updateReachabilityStatus:(OpenVPNReachabilityStatus)status {
    if (self.reachabilityStatusChangedBlock) { self.reachabilityStatusChangedBlock(status); }
}

@end

@implementation OpenVPNReachability

- (BOOL)isTracking {
    return _isTracking;
}

- (OpenVPNReachabilityStatus)reachabilityStatus {
    ReachabilityInterface::Status status = self.reachability->reachable();
    switch (status) {
        case ReachabilityInterface::NotReachable: return OpenVPNReachabilityStatusNotReachable;
        case ReachabilityInterface::ReachableViaWiFi: return OpenVPNReachabilityStatusReachableViaWiFi;
        case ReachabilityInterface::ReachableViaWWAN: return OpenVPNReachabilityStatusReachableViaWWAN;
    }
}

- (nonnull instancetype)init {
    self = [super init];
    if (self) {
        _isTracking = NO;

        self.tracker = new OpenVPNReachabilityTracker(true, false, (__bridge void *)self);
        self.reachability = new Reachability(true, true);
    }
    return self;
}

- (void)startTrackingWithCallback:(void (^)(OpenVPNReachabilityStatus))callback {
    self.reachabilityStatusChangedBlock = callback;
    
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_async(main, ^{
        self.tracker->reachability_tracker_schedule();
    });
    
    _isTracking = YES;
}

- (void)stopTracking {
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_async(main, ^{
        self.tracker->reachability_tracker_cancel();
    });
    
    _isTracking = NO;
}

- (void)dealloc {
    delete self.tracker;
    delete self.reachability;
}

@end

//
//  OpenVPNReachability.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#import "OpenVPNReachability.h"
#import "OpenVPNReachability+Internal.h"

@interface OpenVPNReachability () {
    OpenVPNReachabilityStatus _reachabilityStatus;
}

@property (assign, nonatomic) OpenVPNReachabilityTracker *reachabilityTracker;

@end

@implementation OpenVPNReachability (Internal)

- (void)updateReachabilityStatus:(OpenVPNReachabilityStatus)status {
    _reachabilityStatus = status;
    if (self.reachabilityStatusChangedBlock) {
        self.reachabilityStatusChangedBlock(status);
    }
}

@end

@implementation OpenVPNReachability

- (OpenVPNReachabilityStatus)reachabilityStatus {
    return _reachabilityStatus;
}

- (nonnull instancetype)init {
    self = [super init];
    if (self) {
        self.reachabilityTracker = new OpenVPNReachabilityTracker(true, false, (__bridge void *)self);
    }
    return self;
}

- (void)startTracking {
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_sync(main, ^{
        self.reachabilityTracker->reachability_tracker_schedule();
    });
}

- (void)stopTracking {
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_sync(main, ^{
        self.reachabilityTracker->reachability_tracker_cancel();
    });
}

- (void)dealloc {
    delete self.reachabilityTracker;
}

@end

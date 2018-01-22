//
//  OpenVPNReachabilityTracker.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#import "OpenVPNReachabilityTracker.h"

#import "OpenVPNReachability+Internal.h"
#import "OpenVPNReachabilityStatus.h"

OpenVPNReachabilityTracker::OpenVPNReachabilityTracker(const bool enable_internet, const bool enable_wifi, void* handler) :
    ReachabilityTracker(enable_internet, enable_wifi)
{
    this->handler = handler;
}

void OpenVPNReachabilityTracker::reachability_tracker_event(const ReachabilityBase& rb, SCNetworkReachabilityFlags flags) {
    OpenVPNReachability* handler = (__bridge OpenVPNReachability* )this->handler;
    
    ReachabilityInterface::Status status = rb.status();
    switch (status) {
        case ReachabilityInterface::NotReachable:
            [handler updateReachabilityStatus:OpenVPNReachabilityStatusNotReachable];
            break;
            
        case ReachabilityInterface::ReachableViaWiFi:
            [handler updateReachabilityStatus:OpenVPNReachabilityStatusReachableViaWiFi];
            break;
            
        case ReachabilityInterface::ReachableViaWWAN:
            [handler updateReachabilityStatus:OpenVPNReachabilityStatusReachableViaWWAN];
            break;
    }
}

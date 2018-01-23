//
//  OpenVPNReachabilityTracker.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#include <openvpn/apple/reachable.hpp>

using namespace openvpn;

class OpenVPNReachabilityTracker : public ReachabilityTracker {
public:
    OpenVPNReachabilityTracker(const bool enable_internet, const bool enable_wifi, void* handler);
    
    virtual void reachability_tracker_event(const ReachabilityBase& rb, SCNetworkReachabilityFlags flags) override;
    
private:
    void* handler;
    
};

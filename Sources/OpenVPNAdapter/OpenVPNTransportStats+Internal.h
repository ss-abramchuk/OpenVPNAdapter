//
//  OpenVPNTransportStats+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNTransportStats.h"

#include <client/ovpncli.hpp>

using namespace openvpn;

@interface OpenVPNTransportStats (Internal)

- (instancetype)initWithTransportStats:(ClientAPI::TransportStats)stats;

@end

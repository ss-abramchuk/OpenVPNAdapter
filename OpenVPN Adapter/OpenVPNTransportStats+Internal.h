//
//  OpenVPNTransportStats+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <client/ovpncli.hpp>

#import <OpenVPNAdapter/OpenVPNAdapter.h>

using namespace openvpn;

@interface OpenVPNTransportStats (Internal)

- (instancetype)initWithTransportStats:(ClientAPI::TransportStats)stats;

@end

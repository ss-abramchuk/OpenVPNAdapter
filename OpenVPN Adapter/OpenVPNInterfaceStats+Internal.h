//
//  OpenVPNInterfaceStats+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNInterfaceStats.h"

using namespace openvpn;

@interface OpenVPNInterfaceStats (Internal)

- (instancetype)initWithInterfaceStats:(ClientAPI::InterfaceStats)stats;

@end

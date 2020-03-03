//
//  OpenVPNInterfaceStats+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNInterfaceStats.h"

#include <ovpnapi.hpp>

using namespace openvpn;

@interface OpenVPNInterfaceStats (Internal)

- (instancetype)initWithInterfaceStats:(ClientAPI::InterfaceStats)stats;

@end

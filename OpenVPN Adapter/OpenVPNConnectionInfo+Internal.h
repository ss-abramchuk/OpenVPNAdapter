//
//  OpenVPNConnectionInfo+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNConnectionInfo.h"

using namespace openvpn;

@interface OpenVPNConnectionInfo (Internal)

- (instancetype)initWithConnectionInfo:(ClientAPI::ConnectionInfo)info;

@end

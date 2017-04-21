//
//  OpenVPNConfiguration+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNConfiguration.h"

using namespace openvpn;

@interface OpenVPNConfiguration (Internal)

@property (readonly) ClientAPI::Config config;

@end

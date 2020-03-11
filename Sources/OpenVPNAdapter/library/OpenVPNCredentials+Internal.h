//
//  OpenVPNCredentials+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 24.04.17.
//
//
#import "OpenVPNCredentials.h"

#include <ovpnapi.hpp>

using namespace openvpn;

@interface OpenVPNCredentials (Internal)

@property (readonly) ClientAPI::ProvideCreds credentials;

@end

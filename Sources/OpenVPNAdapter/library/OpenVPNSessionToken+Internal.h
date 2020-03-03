//
//  OpenVPNSessionToken+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.04.17.
//
//

#import "OpenVPNSessionToken.h"

#include <ovpnapi.hpp>

using namespace openvpn;

@interface OpenVPNSessionToken (Internal)

- (instancetype)initWithSessionToken:(ClientAPI::SessionToken)token;

@end

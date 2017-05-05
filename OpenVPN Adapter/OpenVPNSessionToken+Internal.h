//
//  OpenVPNSessionToken+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.04.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNSessionToken.h"

using namespace openvpn;

@interface OpenVPNSessionToken (Internal)

- (instancetype)initWithSessionToken:(ClientAPI::SessionToken)token;

@end

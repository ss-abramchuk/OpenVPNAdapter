//
//  OpenVPNServerEntry+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNServerEntry.h"

#include <client/ovpncli.hpp>

using namespace openvpn;

@interface OpenVPNServerEntry (Internal)

- (instancetype)initWithServerEntry:(ClientAPI::ServerEntry)entry;

@end

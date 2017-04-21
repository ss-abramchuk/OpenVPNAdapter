//
//  OpenVPNAdapter+Client.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNAdapter.h"

using namespace openvpn;

@interface OpenVPNAdapter (Client)

- (void)handleEvent:(const ClientAPI::Event *)event;
- (void)handleLog:(const ClientAPI::LogInfo *)log;

@end

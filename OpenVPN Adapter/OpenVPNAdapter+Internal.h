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

@interface OpenVPNAdapter (Internal)

- (void)handleEvent:(const ClientAPI::Event *)event;
- (void)handleLog:(const ClientAPI::LogInfo *)log;
- (void)tick;

@end

//
//  OpenVPNAdapter+Client.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <openvpn/client/ovpncli.hpp>

#import "OpenVPNAdapter.h"


using namespace openvpn;

@interface OpenVPNAdapter (Client)

- (BOOL)configureSockets;

- (void)setRemoteAddress:(NSString *)address;

- (void)addLocalAddress:(NSString *)address subnet:(NSString *)subnet gateway:(NSString *)gateway;

- (void)addRoute:(NSString *)route subnet:(NSString *)subnet;
- (void)excludeRoute:(NSString *)route subnet:(NSString *)subnet;

- (void)addDNSAddress:(NSString *)address;
- (void)addSearchDomain:(NSString *)domain;

- (void)setMTU:(NSInteger)mtu;

- (NSInteger)establishTunnel;

- (void)handleEvent:(const ClientAPI::Event *)event;
- (void)handleLog:(const ClientAPI::LogInfo *)log;

@end

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

- (BOOL)setRemoteAddress:(NSString *)address;

- (BOOL)addLocalAddress:(NSString *)address subnet:(NSString *)subnet gateway:(NSString *)gateway;

- (BOOL)addRoute:(NSString *)route subnet:(NSString *)subnet;
- (BOOL)excludeRoute:(NSString *)route subnet:(NSString *)subnet;

- (BOOL)addDNSAddress:(NSString *)address;
- (BOOL)addSearchDomain:(NSString *)domain;

- (BOOL)setMTU:(NSInteger)mtu;

- (NSInteger)establishTunnel;

- (void)handleEvent:(const ClientAPI::Event *)event;
- (void)handleLog:(const ClientAPI::LogInfo *)log;

@end

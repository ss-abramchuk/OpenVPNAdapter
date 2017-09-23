//
//  OpenVPNAdapter+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNAdapter.h"

using namespace openvpn;

@interface OpenVPNAdapter (Internal)

- (BOOL)configureSockets;

- (BOOL)setRemoteAddress:(NSString *)address isIPv6:(BOOL)isIPv6;

- (BOOL)addLocalAddress:(NSString *)address prefixLength:(NSNumber *)prefixLength gateway:(NSString *)gateway isIPv6:(BOOL)isIPv6;

- (BOOL)defaultGatewayRerouteIPv4:(BOOL)rerouteIPv4 rerouteIPv6:(BOOL)rerouteIPv6;
- (BOOL)addRoute:(NSString *)route prefixLength:(NSNumber *)prefixLength isIPv6:(BOOL)isIPv6;
- (BOOL)excludeRoute:(NSString *)route prefixLength:(NSNumber *)prefixLength isIPv6:(BOOL)isIPv6;

- (BOOL)addDNSAddress:(NSString *)address isIPv6:(BOOL)isIPv6;
- (BOOL)addSearchDomain:(NSString *)domain;

- (BOOL)setMTU:(NSNumber *)mtu;

- (CFSocketNativeHandle)establishTunnel;
- (void)teardownTunnel:(BOOL)disconnect;

- (void)handleEvent:(const ClientAPI::Event *)event;
- (void)handleLog:(const ClientAPI::LogInfo *)log;

- (void)tick;

@end

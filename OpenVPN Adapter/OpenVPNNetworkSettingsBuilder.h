//
//  OpenVPNNetworkSettingsBuilder.h
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 12/10/2017.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NEIPv4Route;
@class NEIPv6Route;
@class NEProxyServer;
@class NEPacketTunnelNetworkSettings;

@interface OpenVPNNetworkSettingsBuilder : NSObject

@property (nonatomic, copy, nullable) NSString *remoteAddress;

@property (nonatomic, copy, nullable) NSString *ipv4DefaultGateway;
@property (nonatomic, copy, nullable) NSString *ipv6DefaultGateway;

@property (nonatomic, copy, nullable) NSNumber *mtu;

@property (nonatomic, readonly) NSMutableArray<NSString *> *ipv4LocalAddresses;
@property (nonatomic, readonly) NSMutableArray<NSString *> *ipv4SubnetMasks;
@property (nonatomic, readonly) NSMutableArray<NEIPv4Route *> *ipv4IncludedRoutes;
@property (nonatomic, readonly) NSMutableArray<NEIPv4Route *> *ipv4ExcludedRoutes;

@property (nonatomic, readonly) NSMutableArray<NSString *> *ipv6LocalAddresses;
@property (nonatomic, readonly) NSMutableArray<NSNumber *> *ipv6NetworkPrefixLengths;
@property (nonatomic, readonly) NSMutableArray<NEIPv6Route *> *ipv6IncludedRoutes;
@property (nonatomic, readonly) NSMutableArray<NEIPv6Route *> *ipv6ExcludedRoutes;

@property (nonatomic, readonly) NSMutableArray<NSString *> *dnsServers;
@property (nonatomic, readonly) NSMutableArray<NSString *> *searchDomains;

@property (nonatomic, readonly) NSMutableArray<NSString *> *proxyExceptionList;

@property (nonatomic) BOOL autoProxyConfigurationEnabled;
@property (nonatomic, copy, nullable) NSURL *proxyAutoConfigurationURL;
@property (nonatomic) BOOL httpProxyServerEnabled;
@property (nonatomic, copy, nullable) NEProxyServer *httpProxyServer;
@property (nonatomic) BOOL httpsProxyServerEnabled;
@property (nonatomic, copy, nullable) NEProxyServer *httpsProxyServer;

- (nullable NEPacketTunnelNetworkSettings *)networkSettings;

@end

NS_ASSUME_NONNULL_END

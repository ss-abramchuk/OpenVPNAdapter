//
//  OpenVPNNetworkSettingsBuilder.m
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 12/10/2017.
//

#import "OpenVPNNetworkSettingsBuilder.h"

#import <NetworkExtension/NetworkExtension.h>

#import "NSArray+OpenVPNAdditions.h"

@interface OpenVPNNetworkSettingsBuilder ()

@property (nonatomic) NSMutableArray<NSString *> *ipv4LocalAddresses;
@property (nonatomic) NSMutableArray<NSString *> *ipv4SubnetMasks;
@property (nonatomic) NSMutableArray<NEIPv4Route *> *ipv4IncludedRoutes;
@property (nonatomic) NSMutableArray<NEIPv4Route *> *ipv4ExcludedRoutes;

@property (nonatomic) NSMutableArray<NSString *> *ipv6LocalAddresses;
@property (nonatomic) NSMutableArray<NSNumber *> *ipv6NetworkPrefixLengths;
@property (nonatomic) NSMutableArray<NEIPv6Route *> *ipv6IncludedRoutes;
@property (nonatomic) NSMutableArray<NEIPv6Route *> *ipv6ExcludedRoutes;

@property (nonatomic) NSMutableArray<NSString *> *dnsServers;
@property (nonatomic) NSMutableArray<NSString *> *searchDomains;

@property (nonatomic) NSMutableArray<NSString *> *proxyExceptionList;

@end

@implementation OpenVPNNetworkSettingsBuilder

#pragma mark - NEPacketTunnelNetworkSettings Generation

- (NEPacketTunnelNetworkSettings *)networkSettings {
    NSAssert(self.remoteAddress != nil && self.remoteAddress.length > 0, @"Remote address is nil or empty.");
    
    NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:self.remoteAddress];
    
    if (self.ipv4LocalAddresses.ovpn_isNotEmpty) {
        NSAssert(self.ipv4LocalAddresses.count == self.ipv4SubnetMasks.count, @"Number of IPv4 addresses is not equal to number of IPv4 subnet masks.");
        
        NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:self.ipv4LocalAddresses
                                                                     subnetMasks:self.ipv4SubnetMasks];
        
        ipv4Settings.includedRoutes = self.ipv4IncludedRoutes;
        ipv4Settings.excludedRoutes = self.ipv4ExcludedRoutes;
        
        networkSettings.IPv4Settings = ipv4Settings;
    }
    
    if (self.ipv6LocalAddresses.ovpn_isNotEmpty) {
        NSAssert(self.ipv6LocalAddresses.count == self.ipv6NetworkPrefixLengths.count, @"Number of IPv6 addresses is not equal to number of IPv6 prefixes.");
        
        NEIPv6Settings *ipv6Settings = [[NEIPv6Settings alloc] initWithAddresses:self.ipv6LocalAddresses
                                                            networkPrefixLengths:self.ipv6NetworkPrefixLengths];
        
        ipv6Settings.includedRoutes = self.ipv6IncludedRoutes;
        ipv6Settings.excludedRoutes = self.ipv6ExcludedRoutes;
        
        networkSettings.IPv6Settings = ipv6Settings;
    }
    
    if (self.dnsServers.ovpn_isNotEmpty) {
        NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:self.dnsServers];
        dnsSettings.searchDomains = self.searchDomains;
        networkSettings.DNSSettings = dnsSettings;
    }
    
    if (self.autoProxyConfigurationEnabled || self.httpProxyServerEnabled || self.httpsProxyServerEnabled) {
        NEProxySettings *proxySettings = [[NEProxySettings alloc] init];
        
        proxySettings.autoProxyConfigurationEnabled = self.autoProxyConfigurationEnabled;
        proxySettings.proxyAutoConfigurationURL = self.proxyAutoConfigurationURL;
        proxySettings.exceptionList = self.proxyExceptionList;
        proxySettings.HTTPServer = self.httpProxyServer;
        proxySettings.HTTPEnabled = self.httpProxyServerEnabled;
        proxySettings.HTTPSServer = self.httpsProxyServer;
        proxySettings.HTTPSEnabled = self.httpsProxyServerEnabled;
        
        networkSettings.proxySettings = proxySettings;
    }
    
    networkSettings.MTU = self.mtu;
    
    return networkSettings;
}

#pragma mark - Lazy Initializers

- (NSMutableArray<NSString *> *)ipv4LocalAddresses {
    if (!_ipv4LocalAddresses) { _ipv4LocalAddresses = [[NSMutableArray alloc] init]; }
    return _ipv4LocalAddresses;
}

- (NSMutableArray<NSString *> *)ipv4SubnetMasks {
    if (!_ipv4SubnetMasks) { _ipv4SubnetMasks = [[NSMutableArray alloc] init]; }
    return _ipv4SubnetMasks;
}

- (NSMutableArray<NEIPv4Route *> *)ipv4IncludedRoutes {
    if (!_ipv4IncludedRoutes) { _ipv4IncludedRoutes = [[NSMutableArray alloc] init]; }
    return _ipv4IncludedRoutes;
}

- (NSMutableArray<NEIPv4Route *> *)ipv4ExcludedRoutes {
    if (!_ipv4ExcludedRoutes) { _ipv4ExcludedRoutes = [[NSMutableArray alloc] init]; }
    return _ipv4ExcludedRoutes;
}

- (NSMutableArray<NSString *> *)ipv6LocalAddresses {
    if (!_ipv6LocalAddresses) { _ipv6LocalAddresses = [[NSMutableArray alloc] init]; }
    return _ipv6LocalAddresses;
}

- (NSMutableArray<NSNumber *> *)ipv6NetworkPrefixLengths {
    if (!_ipv6NetworkPrefixLengths) { _ipv6NetworkPrefixLengths = [[NSMutableArray alloc] init]; }
    return _ipv6NetworkPrefixLengths;
}

- (NSMutableArray<NEIPv6Route *> *)ipv6IncludedRoutes {
    if (!_ipv6IncludedRoutes) { _ipv6IncludedRoutes = [[NSMutableArray alloc] init]; }
    return _ipv6IncludedRoutes;
}

- (NSMutableArray<NEIPv6Route *> *)ipv6ExcludedRoutes {
    if (!_ipv6ExcludedRoutes) { _ipv6ExcludedRoutes = [[NSMutableArray alloc] init]; }
    return _ipv6ExcludedRoutes;
}

- (NSMutableArray<NSString *> *)dnsServers {
    if (!_dnsServers) { _dnsServers = [[NSMutableArray alloc] init]; }
    return _dnsServers;
}

- (NSMutableArray<NSString *> *)searchDomains {
    if (!_searchDomains) { _searchDomains = [[NSMutableArray alloc] init]; }
    return _searchDomains;
}

- (NSMutableArray<NSString *> *)proxyExceptionList {
    if (!_proxyExceptionList) { _proxyExceptionList = [[NSMutableArray alloc] init]; }
    return _proxyExceptionList;
}

@end

//
//  OpenVPNTunnelSettings.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.02.17.
//
//

#import "OpenVPNTunnelSettings.h"

@implementation OpenVPNTunnelSettings

- (instancetype)init
{
    self = [super init];
    if (self) {
        _initialized = NO;
        
        _localAddresses = [NSMutableArray new];
        _prefixLengths = [NSMutableArray new];
        
        _includedRoutes = [NSMutableArray new];
        _excludedRoutes = [NSMutableArray new];
        
        _dnsAddresses = [NSMutableArray new];
    }
    return self;
}

@end

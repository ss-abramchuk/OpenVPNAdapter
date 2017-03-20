//
//  TUNConfiguration.m
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 26.02.17.
//
//

#import "TUNConfiguration.h"

@implementation TUNConfiguration

- (instancetype)init
{
    self = [super init];
    if (self) {
        _localAddresses = [NSMutableArray new];
        _prefixLengths = [NSMutableArray new];
        
        _includedRoutes = [NSMutableArray new];
        _excludedRoutes = [NSMutableArray new];
        
        _dnsAddresses = [NSMutableArray new];
    }
    return self;
}

@end

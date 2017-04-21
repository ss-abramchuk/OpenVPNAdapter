//
//  OpenVPNConfiguration.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import "OpenVPNConfiguration.h"
#import "OpenVPNConfiguration+Internal.h"

@interface OpenVPNConfiguration () {
    ClientAPI::Config _config;
}

@end

@implementation OpenVPNConfiguration (Internal)

- (ClientAPI::Config)config {
    return _config;
}

@end

@implementation OpenVPNConfiguration


@end

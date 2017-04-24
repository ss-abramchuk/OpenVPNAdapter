//
//  OpenVPNCredentials.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 24.04.17.
//
//

#import "OpenVPNCredentials.h"
#import "OpenVPNCredentials+Internal.h"

using namespace openvpn;

@interface OpenVPNCredentials () {
    ClientAPI::ProvideCreds _credentials;
}

@end

@implementation OpenVPNCredentials (Internal)
    
- (ClientAPI::ProvideCreds)credentials {
    return _credentials;
}

@end

@implementation OpenVPNCredentials



@end

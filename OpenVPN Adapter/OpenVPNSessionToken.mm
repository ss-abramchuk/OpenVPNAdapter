//
//  OpenVPNSessionToken.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.04.17.
//
//

#import "OpenVPNSessionToken+Internal.h"

using namespace openvpn;

@implementation OpenVPNSessionToken

- (instancetype)initWithSessionToken:(ClientAPI::SessionToken)token {
    self = [super init];
    if (self) {
        _username = !token.username.empty() ? [NSString stringWithUTF8String:token.username.c_str()] : nil;
        _session = !token.session_id.empty() ? [NSString stringWithUTF8String:token.session_id.c_str()] : nil;
    }
    return self;
}

@end

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

- (NSString *)username {
    return !_credentials.username.empty() ? [NSString stringWithUTF8String:_credentials.username.c_str()] : nil;
}

- (void)setUsername:(NSString *)username {
    _credentials.username = username ? std::string([username UTF8String]) : "";
}

- (NSString *)password {
    return !_credentials.password.empty() ? [NSString stringWithUTF8String:_credentials.password.c_str()] : nil;
}

- (void)setPassword:(NSString *)password {
    _credentials.password = password ? std::string([password UTF8String]) : "";
}

- (NSString *)response {
    return !_credentials.response.empty() ? [NSString stringWithUTF8String:_credentials.response.c_str()] : nil;
}

- (void)setResponse:(NSString *)response {
    _credentials.response = response ? std::string([response UTF8String]) : "";
}

- (NSString *)dynamicChallengeCookie {
    return !_credentials.dynamicChallengeCookie.empty() ?
        [NSString stringWithUTF8String:_credentials.dynamicChallengeCookie.c_str()] : nil;
}

- (void)setDynamicChallengeCookie:(NSString *)dynamicChallengeCookie {
    _credentials.dynamicChallengeCookie = dynamicChallengeCookie ? std::string([dynamicChallengeCookie UTF8String]) : "";
}

- (BOOL)replacePasswordWithSessionID {
    return _credentials.replacePasswordWithSessionID;
}

- (void)setReplacePasswordWithSessionID:(BOOL)replacePasswordWithSessionID {
    _credentials.replacePasswordWithSessionID = replacePasswordWithSessionID;
}

- (BOOL)cachePassword {
    return _credentials.cachePassword;
}

- (void)setCachePassword:(BOOL)cachePassword {
    _credentials.cachePassword = cachePassword;
}

@end

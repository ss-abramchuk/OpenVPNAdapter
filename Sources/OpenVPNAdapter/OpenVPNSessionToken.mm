//
//  OpenVPNSessionToken.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.04.17.
//
//

#import "OpenVPNSessionToken.h"
#import "OpenVPNSessionToken+Internal.h"

using namespace openvpn;

@interface OpenVPNSessionToken ()
@property (nullable, readwrite, nonatomic) NSString *username;
@property (nullable, readwrite, nonatomic) NSString *session;
@end

@implementation OpenVPNSessionToken

- (instancetype)initWithSessionToken:(ClientAPI::SessionToken)token {
    if (self = [super init]) {
        self.username = !token.username.empty() ? [NSString stringWithUTF8String:token.username.c_str()] : nil;
        self.session = !token.session_id.empty() ? [NSString stringWithUTF8String:token.session_id.c_str()] : nil;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    OpenVPNSessionToken *token = [[OpenVPNSessionToken allocWithZone:zone] init];
    token.username = [self.username copyWithZone:zone];
    token.session = [self.session copyWithZone:zone];
    return token;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.username forKey:NSStringFromSelector(@selector(username))];
    [aCoder encodeObject:self.session forKey:NSStringFromSelector(@selector(session))];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [self init]) {
        self.username = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(username))];
        self.session = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(session))];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

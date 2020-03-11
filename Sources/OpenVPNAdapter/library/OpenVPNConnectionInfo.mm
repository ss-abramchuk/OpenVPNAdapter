//
//  OpenVPNConnectionInfo.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNConnectionInfo.h"
#import "OpenVPNConnectionInfo+Internal.h"

using namespace openvpn;

@interface OpenVPNConnectionInfo ()
@property (nullable, readwrite, nonatomic) NSString *user;
@property (nullable, readwrite, nonatomic) NSString *serverHost;
@property (nullable, readwrite, nonatomic) NSString *serverPort;
@property (nullable, readwrite, nonatomic) NSString *serverProto;
@property (nullable, readwrite, nonatomic) NSString *serverIP;
@property (nullable, readwrite, nonatomic) NSString *vpnIPv4;
@property (nullable, readwrite, nonatomic) NSString *vpnIPv6;
@property (nullable, readwrite, nonatomic) NSString *gatewayIPv4;
@property (nullable, readwrite, nonatomic) NSString *gatewayIPv6;
@property (nullable, readwrite, nonatomic) NSString *clientIP;
@property (nullable, readwrite, nonatomic) NSString *tunName;
@end

@implementation OpenVPNConnectionInfo

- (instancetype)initWithConnectionInfo:(ClientAPI::ConnectionInfo)info {
    if (self = [super init]) {
        self.user = !info.user.empty() ? [NSString stringWithUTF8String:info.user.c_str()] : nil;
        self.serverHost = !info.serverHost.empty() ? [NSString stringWithUTF8String:info.serverHost.c_str()] : nil;
        self.serverPort = !info.serverPort.empty() ? [NSString stringWithUTF8String:info.serverPort.c_str()] : nil;
        self.serverProto = !info.serverProto.empty() ? [NSString stringWithUTF8String:info.serverProto.c_str()] : nil;
        self.serverIP = !info.serverIp.empty() ? [NSString stringWithUTF8String:info.serverIp.c_str()] : nil;
        self.vpnIPv4 = !info.vpnIp4.empty() ? [NSString stringWithUTF8String:info.vpnIp4.c_str()] : nil;
        self.vpnIPv6 = !info.vpnIp6.empty() ? [NSString stringWithUTF8String:info.vpnIp6.c_str()] : nil;
        self.gatewayIPv4 = !info.gw4.empty() ? [NSString stringWithUTF8String:info.gw4.c_str()] : nil;
        self.gatewayIPv6 = !info.gw6.empty() ? [NSString stringWithUTF8String:info.gw6.c_str()] : nil;
        self.clientIP = !info.clientIp.empty() ? [NSString stringWithUTF8String:info.clientIp.c_str()] : nil;
        self.tunName = !info.tunName.empty() ? [NSString stringWithUTF8String:info.tunName.c_str()] : nil;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    OpenVPNConnectionInfo *info = [[OpenVPNConnectionInfo allocWithZone:zone] init];
    info.user = [self.user copyWithZone:zone];
    info.serverHost = [self.serverHost copyWithZone:zone];
    info.serverPort = [self.serverPort copyWithZone:zone];
    info.serverProto = [self.serverProto copyWithZone:zone];
    info.serverIP = [self.serverIP copyWithZone:zone];
    info.vpnIPv4 = [self.vpnIPv4 copyWithZone:zone];
    info.vpnIPv6 = [self.vpnIPv6 copyWithZone:zone];
    info.gatewayIPv4 = [self.gatewayIPv4 copyWithZone:zone];
    info.gatewayIPv6 = [self.gatewayIPv6 copyWithZone:zone];
    info.clientIP = [self.clientIP copyWithZone:zone];
    info.tunName = [self.tunName copyWithZone:zone];
    return info;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.user forKey:NSStringFromSelector(@selector(user))];
    [aCoder encodeObject:self.serverHost forKey:NSStringFromSelector(@selector(serverHost))];
    [aCoder encodeObject:self.serverPort forKey:NSStringFromSelector(@selector(serverPort))];
    [aCoder encodeObject:self.serverProto forKey:NSStringFromSelector(@selector(serverProto))];
    [aCoder encodeObject:self.serverIP forKey:NSStringFromSelector(@selector(serverIP))];
    [aCoder encodeObject:self.vpnIPv4 forKey:NSStringFromSelector(@selector(vpnIPv4))];
    [aCoder encodeObject:self.vpnIPv6 forKey:NSStringFromSelector(@selector(vpnIPv6))];
    [aCoder encodeObject:self.gatewayIPv4 forKey:NSStringFromSelector(@selector(gatewayIPv4))];
    [aCoder encodeObject:self.gatewayIPv6 forKey:NSStringFromSelector(@selector(gatewayIPv6))];
    [aCoder encodeObject:self.clientIP forKey:NSStringFromSelector(@selector(clientIP))];
    [aCoder encodeObject:self.tunName forKey:NSStringFromSelector(@selector(tunName))];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [self init]) {
        self.user = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(user))];
        self.serverHost = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(serverHost))];
        self.serverPort = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(serverPort))];
        self.serverProto = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(serverProto))];
        self.serverIP = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(serverIP))];
        self.vpnIPv4 = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(vpnIPv4))];
        self.vpnIPv6 = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(vpnIPv6))];
        self.gatewayIPv4 = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(gatewayIPv4))];
        self.gatewayIPv6 = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(gatewayIPv6))];
        self.clientIP = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(clientIP))];
        self.tunName = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(tunName))];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

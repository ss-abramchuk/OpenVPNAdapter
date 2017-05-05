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

@implementation OpenVPNConnectionInfo

- (instancetype)initWithConnectionInfo:(ClientAPI::ConnectionInfo)info
{
    self = [super init];
    if (self) {
        _user = !info.user.empty() ? [NSString stringWithUTF8String:info.user.c_str()] : nil;
        _serverHost = !info.serverHost.empty() ? [NSString stringWithUTF8String:info.serverHost.c_str()] : nil;
        _serverPort = !info.serverPort.empty() ? [NSString stringWithUTF8String:info.serverPort.c_str()] : nil;
        _serverProto = !info.serverProto.empty() ? [NSString stringWithUTF8String:info.serverProto.c_str()] : nil;
        _serverIP = !info.serverIp.empty() ? [NSString stringWithUTF8String:info.serverIp.c_str()] : nil;
        _vpnIPv4 = !info.vpnIp4.empty() ? [NSString stringWithUTF8String:info.vpnIp4.c_str()] : nil;
        _vpnIPv6 = !info.vpnIp6.empty() ? [NSString stringWithUTF8String:info.vpnIp6.c_str()] : nil;
        _gatewayIPv4 = !info.gw4.empty() ? [NSString stringWithUTF8String:info.gw4.c_str()] : nil;
        _gatewayIPv6 = !info.gw6.empty() ? [NSString stringWithUTF8String:info.gw6.c_str()] : nil;
        _clientIP = !info.clientIp.empty() ? [NSString stringWithUTF8String:info.clientIp.c_str()] : nil;
        _tunName = !info.tunName.empty() ? [NSString stringWithUTF8String:info.tunName.c_str()] : nil;
    }
    return self;
}

@end

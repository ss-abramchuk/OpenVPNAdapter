//
//  OpenVPNConfiguration.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import "OpenVPNConfiguration.h"
#import "OpenVPNConfiguration+Internal.h"

using namespace openvpn;

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

- (NSData *)fileContent {
    return _config.content.size() != 0 ? [NSData dataWithBytes:_config.content.data() length:_config.content.size()] : nil;
}

- (void)setFileContent:(NSData *)fileContent {
    _config.content = fileContent ? std::string((const char *)fileContent.bytes) : "";
}

- (NSDictionary<NSString *,NSString *> *)settings {
    if (_config.contentList.size() == 0) {
        return nil;
    }
    
    NSMutableDictionary *settings = [NSMutableDictionary new];
    
    for (ClientAPI::KeyValue param : _config.contentList) {
        NSString *key = [NSString stringWithCString:param.key.c_str() encoding:NSUTF8StringEncoding];
        NSString *value = [NSString stringWithCString:param.value.c_str() encoding:NSUTF8StringEncoding];
        
        settings[key] = value;
    }
    
    return [settings copy];
}

- (void)setSettings:(NSDictionary<NSString *,NSString *> *)settings {
    _config.contentList.clear();
    
    if (!settings) {
        return;
    }
    
    [settings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        ClientAPI::KeyValue param = ClientAPI::KeyValue(std::string([key UTF8String]), std::string([obj UTF8String]));
        _config.contentList.push_back(param);
    }];
}

- (NSString *)guiVersion {
    return _config.guiVersion.size() != 0 ? [NSString stringWithUTF8String:_config.guiVersion.c_str()] : nil;
}

- (void)setGuiVersion:(NSString *)guiVersion {
    _config.guiVersion = guiVersion ? std::string([guiVersion UTF8String]) : "";
}

- (NSString *)server {
    return _config.serverOverride.size() != 0 ? [NSString stringWithUTF8String:_config.serverOverride.c_str()] : nil;
}

- (void)setServer:(NSString *)serverOverride {
    _config.serverOverride = serverOverride ? std::string([serverOverride UTF8String]) : "";
}

- (OpenVPNTransportProtocol)proto {
    NSDictionary *options = @{
        @"udp": @(OpenVPNTransportProtocolUDP),
        @"tcp": @(OpenVPNTransportProtocolTCP),
        @"adaptive": @(OpenVPNTransportProtocolAdaptive),
        @"": @(OpenVPNTransportProtocolDefault)
    };
    
    NSString *currentValue = [NSString stringWithUTF8String:_config.protoOverride.c_str()];
    
    NSNumber *transportProtocol = options[currentValue];
    NSAssert(transportProtocol != nil, @"Incorrect ipv6 value");
    
    return (OpenVPNTransportProtocol)[transportProtocol integerValue];
}

- (void)setProto:(OpenVPNTransportProtocol)proto {
    switch (proto) {
        case OpenVPNTransportProtocolUDP:
            _config.protoOverride = "udp";
            break;
            
        case OpenVPNTransportProtocolTCP:
            _config.protoOverride = "tcp";
            break;
            
        case OpenVPNTransportProtocolAdaptive:
            _config.protoOverride = "adaptive";
            break;
            
        default:
            _config.protoOverride = "";
            break;
    }
}

- (OpenVPNIPv6Preference)ipv6 {
    NSDictionary *options = @{
        @"yes": @(OpenVPNIPv6PreferenceEnabled),
        @"no": @(OpenVPNIPv6PreferenceDisabled),
        @"default": @(OpenVPNIPv6PreferenceDefault),
        @"": @(OpenVPNIPv6PreferenceDefault)
    };
    
    NSString *currentValue = [NSString stringWithUTF8String:_config.ipv6.c_str()];
    
    NSNumber *preference = options[currentValue];
    NSAssert(preference != nil, @"Incorrect ipv6 value");
    
    return (OpenVPNIPv6Preference)[preference integerValue];
}

- (void)setIpv6:(OpenVPNIPv6Preference)ipv6 {
    switch (ipv6) {
        case OpenVPNIPv6PreferenceEnabled:
            _config.ipv6 = "yes";
            break;
        
        case OpenVPNIPv6PreferenceDisabled:
            _config.ipv6 = "no";
            break;
            
        case OpenVPNIPv6PreferenceDefault:
            _config.ipv6 = "default";
            break;
            
        default:
            NSAssert(NO, @"Incorrect IPv6Preference value");
            break;
    }
}

- (NSInteger)connectionTimeout {
    return _config.connTimeout;
}

- (void)setConnectionTimeout:(NSInteger)connectionTimeout {
    _config.connTimeout = connectionTimeout;
}

- (BOOL)tunPersist {
    return _config.tunPersist;
}

- (void)setTunPersist:(BOOL)tunPersist {
    _config.tunPersist = tunPersist;
}

- (BOOL)googleDNSFallback {
    return _config.googleDnsFallback;
}

- (void)setGoogleDNSFallback:(BOOL)googleDNSFallback {
    _config.googleDnsFallback = googleDNSFallback;
}

- (BOOL)autologinSessions {
    return _config.autologinSessions;
}

- (void)setAutologinSessions:(BOOL)autologinSessions {
    _config.autologinSessions = autologinSessions;
}

@end

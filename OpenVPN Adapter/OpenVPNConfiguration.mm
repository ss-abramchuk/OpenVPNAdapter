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
    return !_config.content.empty() ? [NSData dataWithBytes:_config.content.data() length:_config.content.size()] : nil;
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
    return !_config.guiVersion.empty() ? [NSString stringWithUTF8String:_config.guiVersion.c_str()] : nil;
}

- (void)setGuiVersion:(NSString *)guiVersion {
    _config.guiVersion = guiVersion ? std::string([guiVersion UTF8String]) : "";
}

- (NSString *)server {
    return !_config.serverOverride.empty() ? [NSString stringWithUTF8String:_config.serverOverride.c_str()] : nil;
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
            
        case OpenVPNTransportProtocolDefault:
            _config.protoOverride = "";
            break;
            
        default:
            NSAssert(NO, @"Incorrect OpenVPNTransportProtocol value");
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
            NSAssert(NO, @"Incorrect OpenVPNIPv6Preference value");
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

- (BOOL)disableClientCert {
    return _config.disableClientCert;
}

- (void)setDisableClientCert:(BOOL)disableClientCert {
    _config.disableClientCert = disableClientCert;
}

- (NSInteger)sslDebugLevel {
    return _config.sslDebugLevel;
}

- (void)setSslDebugLevel:(NSInteger)sslDebugLevel {
    _config.sslDebugLevel = sslDebugLevel;
}

- (OpenVPNCompressionMode)compressionMode {
    NSDictionary *options = @{
        @"yes": @(OpenVPNCompressionModeEnabled),
        @"no": @(OpenVPNCompressionModeDisabled),
        @"asym": @(OpenVPNCompressionModeAsym),
        @"": @(OpenVPNCompressionModeDefault)
    };
    
    NSString *currentValue = [NSString stringWithUTF8String:_config.compressionMode.c_str()];
    
    NSNumber *preference = options[currentValue];
    NSAssert(preference != nil, @"Incorrect compressionMode value");
    
    return (OpenVPNCompressionMode)[preference integerValue];
}

- (void)setCompressionMode:(OpenVPNCompressionMode)compressionMode {
    switch (compressionMode) {
        case OpenVPNCompressionModeEnabled:
            _config.compressionMode = "yes";
            break;
            
        case OpenVPNCompressionModeDisabled:
            _config.compressionMode = "no";
            break;
            
        case OpenVPNCompressionModeAsym:
            _config.compressionMode = "asym";
            break;
            
        case OpenVPNCompressionModeDefault:
            _config.compressionMode = "";
            break;
            
        default:
            NSAssert(NO, @"Incorrect OpenVPNCompressionMode value");
            break;
    }
}

- (NSString *)privateKeyPassword {
    return !_config.privateKeyPassword.empty() ? [NSString stringWithUTF8String:_config.privateKeyPassword.c_str()] : nil;
}

- (void)setPrivateKeyPassword:(NSString *)privateKeyPassword {
    _config.privateKeyPassword = privateKeyPassword ? std::string([privateKeyPassword UTF8String]) : "";
}

- (NSInteger)keyDirection {
    return _config.defaultKeyDirection;
}

- (void)setKeyDirection:(NSInteger)keyDirection {
    _config.defaultKeyDirection = keyDirection;
}

- (BOOL)forceCiphersuitesAESCBC {
    return _config.forceAesCbcCiphersuites;
}

-(void)setForceCiphersuitesAESCBC:(BOOL)forceCiphersuitesAESCBC {
    _config.forceAesCbcCiphersuites = forceCiphersuitesAESCBC;
}

- (OpenVPNMinTLSVersion)minTLSVersion {
    NSDictionary *options = @{
        @"disabled": @(OpenVPNMinTLSVersionDisabled),
        @"tls_1_0": @(OpenVPNMinTLSVersion10),
        @"tls_1_1": @(OpenVPNMinTLSVersion11),
        @"tls_1_2": @(OpenVPNMinTLSVersion12),
        @"default": @(OpenVPNMinTLSVersionDefault),
        @"": @(OpenVPNMinTLSVersionDefault)
    };
    
    NSString *currentValue = [NSString stringWithUTF8String:_config.tlsVersionMinOverride.c_str()];
    
    NSNumber *preference = options[currentValue];
    NSAssert(preference != nil, @"Incorrect minTLSVersion value");
    
    return (OpenVPNMinTLSVersion)[preference integerValue];
}

- (void)setMinTLSVersion:(OpenVPNMinTLSVersion)minTLSVersion {
    switch (minTLSVersion) {
        case OpenVPNMinTLSVersionDisabled:
            _config.tlsVersionMinOverride = "disabled";
            break;
            
        case OpenVPNMinTLSVersion10:
            _config.tlsVersionMinOverride = "tls_1_0";
            break;
            
        case OpenVPNMinTLSVersion11:
            _config.tlsVersionMinOverride = "tls_1_1";
            break;
            
        case OpenVPNMinTLSVersion12:
            _config.tlsVersionMinOverride = "tls_1_2";
            break;
            
        case OpenVPNMinTLSVersionDefault:
            _config.tlsVersionMinOverride = "default";
            break;
            
        default:
            NSAssert(NO, @"Incorrect OpenVPNMinTLSVersion value");
            break;
    }
}

@end

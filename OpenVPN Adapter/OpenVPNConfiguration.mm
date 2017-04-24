//
//  OpenVPNConfiguration.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import "OpenVPNConfigurationValues.h"
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
    NSAssert(transportProtocol != nil, @"Incorrect protoOverride value");
    
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
        OpenVPNCompressionModeEnabledValue: @(OpenVPNCompressionModeEnabled),
        OpenVPNCompressionModeDisabledValue: @(OpenVPNCompressionModeDisabled),
        OpenVPNCompressionModeAsymValue: @(OpenVPNCompressionModeAsym),
        OpenVPNCompressionModeDefaultValue: @(OpenVPNCompressionModeDefault)
    };
    
    NSString *currentValue = _config.compressionMode.empty() ? OpenVPNCompressionModeDefaultValue :
        [NSString stringWithUTF8String:_config.compressionMode.c_str()];
    
    NSNumber *preference = options[currentValue];
    NSAssert(preference != nil, @"Incorrect compressionMode value: %@", currentValue);
    
    return (OpenVPNCompressionMode)[preference integerValue];
}

- (void)setCompressionMode:(OpenVPNCompressionMode)compressionMode {
    NSDictionary *options = @{
        @(OpenVPNCompressionModeEnabled): OpenVPNCompressionModeEnabledValue,
        @(OpenVPNCompressionModeDisabled): OpenVPNCompressionModeDisabledValue,
        @(OpenVPNCompressionModeAsym): OpenVPNCompressionModeAsymValue,
        @(OpenVPNCompressionModeDefault): OpenVPNCompressionModeDefaultValue
    };
    
    NSString *value = options[@(compressionMode)];
    NSAssert(value != nil, @"Incorrect compressionMode value: %li", (NSInteger)compressionMode);
    
    _config.compressionMode = [value UTF8String];
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
        OpenVPNMinTLSVersionDisabledValue: @(OpenVPNMinTLSVersionDisabled),
        OpenVPNMinTLSVersion10Value: @(OpenVPNMinTLSVersion10),
        OpenVPNMinTLSVersion11Value: @(OpenVPNMinTLSVersion11),
        OpenVPNMinTLSVersion12Value: @(OpenVPNMinTLSVersion12),
        OpenVPNMinTLSVersionDefaultValue: @(OpenVPNMinTLSVersionDefault)
    };
    
    NSString *currentValue = _config.tlsVersionMinOverride.empty() ? OpenVPNMinTLSVersionDefaultValue :
        [NSString stringWithUTF8String:_config.tlsVersionMinOverride.c_str()];
    
    NSNumber *preference = options[currentValue];
    NSAssert(preference != nil, @"Incorrect tlsVersionMinOverride value: %@", currentValue);
    
    return (OpenVPNMinTLSVersion)[preference integerValue];
}

- (void)setMinTLSVersion:(OpenVPNMinTLSVersion)minTLSVersion {
    NSDictionary *options = @{
        @(OpenVPNMinTLSVersionDisabled): OpenVPNMinTLSVersionDisabledValue,
        @(OpenVPNMinTLSVersion10): OpenVPNMinTLSVersion10Value,
        @(OpenVPNMinTLSVersion11): OpenVPNMinTLSVersion11Value,
        @(OpenVPNMinTLSVersion12): OpenVPNMinTLSVersion12Value,
        @(OpenVPNMinTLSVersionDefault): OpenVPNMinTLSVersionDefaultValue
    };
    
    NSString *value = options[@(minTLSVersion)];
    NSAssert(value != nil, @"Incorrect minTLSVersion value: %li", (NSInteger)minTLSVersion);
    
    _config.tlsVersionMinOverride = [value UTF8String];
}

- (OpenVPNTLSCertProfile)tlsCertProfile {
    NSDictionary *options = @{
        OpenVPNTLSCertProfileLegacyValue: @(OpenVPNTLSCertProfileLegacy),
        OpenVPNTLSCertProfilePreferredValue: @(OpenVPNTLSCertProfilePreferred),
        OpenVPNTLSCertProfileSuiteBValue: @(OpenVPNTLSCertProfileSuiteB),
        OpenVPNTLSCertProfileLegacyDefaultValue: @(OpenVPNTLSCertProfileLegacyDefault),
        OpenVPNTLSCertProfilePreferredDefaultValue: @(OpenVPNTLSCertProfilePreferredDefault),
        OpenVPNTLSCertProfileDefaultValue: @(OpenVPNTLSCertProfileDefault),
    };
    
    NSString *currentValue = _config.tlsCertProfileOverride.empty() ? OpenVPNTLSCertProfileDefaultValue :
        [NSString stringWithUTF8String:_config.tlsCertProfileOverride.c_str()];
    
    NSNumber *preference = options[currentValue];
    NSAssert(preference != nil, @"Incorrect tlsCertProfileOverride value: %@", currentValue);
    
    return (OpenVPNTLSCertProfile)[preference integerValue];
}

- (void)setTlsCertProfile:(OpenVPNTLSCertProfile)tlsCertProfile {
    NSDictionary *options = @{
        @(OpenVPNTLSCertProfileLegacy): OpenVPNTLSCertProfileLegacyValue,
        @(OpenVPNTLSCertProfilePreferred): OpenVPNTLSCertProfilePreferredValue,
        @(OpenVPNTLSCertProfileSuiteB): OpenVPNTLSCertProfileSuiteBValue,
        @(OpenVPNTLSCertProfileLegacyDefault): OpenVPNTLSCertProfileLegacyDefaultValue,
        @(OpenVPNTLSCertProfilePreferredDefault): OpenVPNTLSCertProfilePreferredDefaultValue,
        @(OpenVPNTLSCertProfileDefault): OpenVPNTLSCertProfileDefaultValue
    };
    
    NSString *value = options[@(tlsCertProfile)];
    NSAssert(value != nil, @"Incorrect tlsCertProfile value: %li", (NSInteger)tlsCertProfile);
    
    _config.tlsCertProfileOverride = [value UTF8String];
}

- (NSDictionary<NSString *,NSString *> *)peerInfo {
    if (_config.peerInfo.size() == 0) {
        return nil;
    }
    
    NSMutableDictionary *peerInfo = [NSMutableDictionary new];
    
    for (ClientAPI::KeyValue param : _config.peerInfo) {
        NSString *key = [NSString stringWithCString:param.key.c_str() encoding:NSUTF8StringEncoding];
        NSString *value = [NSString stringWithCString:param.value.c_str() encoding:NSUTF8StringEncoding];
        
        peerInfo[key] = value;
    }
    
    return [peerInfo copy];
}

- (void)setPeerInfo:(NSDictionary<NSString *,NSString *> *)peerInfo {
    _config.contentList.clear();
    
    if (!peerInfo) {
        return;
    }
    
    [peerInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        ClientAPI::KeyValue param = ClientAPI::KeyValue(std::string([key UTF8String]), std::string([obj UTF8String]));
        _config.peerInfo.push_back(param);
    }];
}

@end

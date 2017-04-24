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
        OpenVPNTransportProtocolUDPValue: @(OpenVPNTransportProtocolUDP),
        OpenVPNTransportProtocolTCPValue: @(OpenVPNTransportProtocolTCP),
        OpenVPNTransportProtocolAdaptiveValue: @(OpenVPNTransportProtocolAdaptive),
        OpenVPNTransportProtocolDefaultValue: @(OpenVPNTransportProtocolDefault)
    };
    
    NSString *currentValue = _config.protoOverride.empty() ? OpenVPNTransportProtocolDefaultValue :
        [NSString stringWithUTF8String:_config.protoOverride.c_str()];
    
    NSNumber *transportProtocol = options[currentValue];
    NSAssert(transportProtocol != nil, @"Incorrect protoOverride value: %@", currentValue);
    
    return (OpenVPNTransportProtocol)[transportProtocol integerValue];
}

- (void)setProto:(OpenVPNTransportProtocol)proto {
    NSDictionary *options = @{
        @(OpenVPNTransportProtocolUDP): OpenVPNTransportProtocolUDPValue,
        @(OpenVPNTransportProtocolTCP): OpenVPNTransportProtocolTCPValue,
        @(OpenVPNTransportProtocolAdaptive): OpenVPNTransportProtocolAdaptiveValue,
        @(OpenVPNTransportProtocolDefault): OpenVPNTransportProtocolDefaultValue
    };
    
    NSString *value = options[@(proto)];
    NSAssert(value != nil, @"Incorrect proto value: %li", (NSInteger)proto);
    
    _config.protoOverride = [value UTF8String];
}

- (OpenVPNIPv6Preference)ipv6 {
    NSDictionary *options = @{
        OpenVPNIPv6PreferenceEnabledValue: @(OpenVPNIPv6PreferenceEnabled),
        OpenVPNIPv6PreferenceDisabledValue: @(OpenVPNIPv6PreferenceDisabled),
        OpenVPNIPv6PreferenceDefaultValue: @(OpenVPNIPv6PreferenceDefault)
    };
    
    NSString *currentValue = _config.ipv6.empty() ? OpenVPNIPv6PreferenceDefaultValue :
        [NSString stringWithUTF8String:_config.ipv6.c_str()];
    
    NSNumber *ipv6 = options[currentValue];
    NSAssert(ipv6 != nil, @"Incorrect ipv6 value: %@", currentValue);
    
    return (OpenVPNIPv6Preference)[ipv6 integerValue];
}

- (void)setIpv6:(OpenVPNIPv6Preference)ipv6 {
    NSDictionary *options = @{
        @(OpenVPNIPv6PreferenceEnabled): OpenVPNIPv6PreferenceEnabledValue,
        @(OpenVPNIPv6PreferenceDisabled): OpenVPNIPv6PreferenceDisabledValue,
        @(OpenVPNIPv6PreferenceDefault): OpenVPNIPv6PreferenceDefaultValue
    };
    
    NSString *value = options[@(ipv6)];
    NSAssert(value != nil, @"Incorrect ipv6 value: %li", (NSInteger)ipv6);
    
    _config.ipv6 = [value UTF8String];
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
    
    NSNumber *compressionMode = options[currentValue];
    NSAssert(compressionMode != nil, @"Incorrect compressionMode value: %@", currentValue);
    
    return (OpenVPNCompressionMode)[compressionMode integerValue];
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

- (void)setForceCiphersuitesAESCBC:(BOOL)forceCiphersuitesAESCBC {
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
    
    NSNumber *minTLSVersion = options[currentValue];
    NSAssert(minTLSVersion != nil, @"Incorrect tlsVersionMinOverride value: %@", currentValue);
    
    return (OpenVPNMinTLSVersion)[minTLSVersion integerValue];
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
    
    NSNumber *tlsCertProfile = options[currentValue];
    NSAssert(tlsCertProfile != nil, @"Incorrect tlsCertProfileOverride value: %@", currentValue);
    
    return (OpenVPNTLSCertProfile)[tlsCertProfile integerValue];
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
    _config.peerInfo.clear();
    
    if (!peerInfo) {
        return;
    }
    
    [peerInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        ClientAPI::KeyValue param = ClientAPI::KeyValue(std::string([key UTF8String]), std::string([obj UTF8String]));
        _config.peerInfo.push_back(param);
    }];
}

- (BOOL)echo {
    return _config.echo;
}

- (void)setEcho:(BOOL)echo {
    _config.echo = echo;
}

- (BOOL)info {
    return _config.info;
}

- (void)setInfo:(BOOL)info {
    _config.info = info;
}

@end

//
//  OpenVPNConfiguration.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import "OpenVPNConfiguration.h"
#import "OpenVPNConfiguration+Internal.h"

#import "OpenVPNTransportProtocol.h"
#import "OpenVPNIPv6Preference.h"
#import "OpenVPNCompressionMode.h"
#import "OpenVPNMinTLSVersion.h"
#import "OpenVPNTLSCertProfile.h"

using namespace openvpn;

NSString *const OpenVPNTransportProtocolUDPValue = @"udp";
NSString *const OpenVPNTransportProtocolTCPValue = @"tcp";
NSString *const OpenVPNTransportProtocolAdaptiveValue = @"adaptive";
NSString *const OpenVPNTransportProtocolDefaultValue = @"";

NSString *const OpenVPNIPv6PreferenceEnabledValue = @"yes";
NSString *const OpenVPNIPv6PreferenceDisabledValue = @"no";
NSString *const OpenVPNIPv6PreferenceDefaultValue = @"default";

NSString *const OpenVPNCompressionModeEnabledValue = @"yes";
NSString *const OpenVPNCompressionModeDisabledValue = @"no";
NSString *const OpenVPNCompressionModeAsymValue = @"asym";
NSString *const OpenVPNCompressionModeDefaultValue = @"";

NSString *const OpenVPNMinTLSVersionDisabledValue = @"disabled";
NSString *const OpenVPNMinTLSVersion10Value = @"tls_1_0";
NSString *const OpenVPNMinTLSVersion11Value = @"tls_1_1";
NSString *const OpenVPNMinTLSVersion12Value = @"tls_1_2";
NSString *const OpenVPNMinTLSVersionDefaultValue = @"default";

NSString *const OpenVPNTLSCertProfileLegacyValue = @"legacy";
NSString *const OpenVPNTLSCertProfilePreferredValue = @"preferred";
NSString *const OpenVPNTLSCertProfileSuiteBValue = @"suiteb";
NSString *const OpenVPNTLSCertProfileLegacyDefaultValue = @"legacy-default";
NSString *const OpenVPNTLSCertProfilePreferredDefaultValue = @"preferred-default";
NSString *const OpenVPNTLSCertProfileDefaultValue = @"default";

@interface OpenVPNConfiguration () {
    ClientAPI::Config _config;
}

@end

@implementation OpenVPNConfiguration (Internal)

- (ClientAPI::Config)config {
    return _config;
}

+ (OpenVPNTransportProtocol)getTransportProtocolFromValue:(NSString *)value {
    NSDictionary *options = @{
        OpenVPNTransportProtocolUDPValue: @(OpenVPNTransportProtocolUDP),
        OpenVPNTransportProtocolTCPValue: @(OpenVPNTransportProtocolTCP),
        OpenVPNTransportProtocolAdaptiveValue: @(OpenVPNTransportProtocolAdaptive),
        OpenVPNTransportProtocolDefaultValue: @(OpenVPNTransportProtocolDefault)
    };
    
    NSString *currentValue = [value length] == 0 ? OpenVPNTransportProtocolDefaultValue : value;
    
    NSNumber *transportProtocol = options[currentValue];
    NSAssert(transportProtocol != nil, @"Incorrect protocol value: %@", currentValue);
    
    return (OpenVPNTransportProtocol)[transportProtocol integerValue];
}

+ (nonnull NSString *)getValueFromTransportProtocol:(OpenVPNTransportProtocol)protocol {
    NSDictionary *options = @{
        @(OpenVPNTransportProtocolUDP): OpenVPNTransportProtocolUDPValue,
        @(OpenVPNTransportProtocolTCP): OpenVPNTransportProtocolTCPValue,
        @(OpenVPNTransportProtocolAdaptive): OpenVPNTransportProtocolAdaptiveValue,
        @(OpenVPNTransportProtocolDefault): OpenVPNTransportProtocolDefaultValue
    };
    
    NSString *value = options[@(protocol)];
    NSAssert(value != nil, @"Incorrect protocol value: %li", (long)protocol);
    
    return value;
}

+ (OpenVPNIPv6Preference)getIPv6PreferenceFromValue:(nullable NSString *)value {
    NSDictionary *options = @{
        OpenVPNIPv6PreferenceEnabledValue: @(OpenVPNIPv6PreferenceEnabled),
        OpenVPNIPv6PreferenceDisabledValue: @(OpenVPNIPv6PreferenceDisabled),
        OpenVPNIPv6PreferenceDefaultValue: @(OpenVPNIPv6PreferenceDefault)
    };
    
    NSString *currentValue = [value length] == 0 ? OpenVPNIPv6PreferenceDefaultValue : value;
    
    NSNumber *ipv6 = options[currentValue];
    NSAssert(ipv6 != nil, @"Incorrect ipv6 value: %@", currentValue);
    
    return (OpenVPNIPv6Preference)[ipv6 integerValue];
}

+ (nonnull NSString *)getValueFromIPv6Preference:(OpenVPNIPv6Preference)preference {
    NSDictionary *options = @{
        @(OpenVPNIPv6PreferenceEnabled): OpenVPNIPv6PreferenceEnabledValue,
        @(OpenVPNIPv6PreferenceDisabled): OpenVPNIPv6PreferenceDisabledValue,
        @(OpenVPNIPv6PreferenceDefault): OpenVPNIPv6PreferenceDefaultValue
    };
    
    NSString *value = options[@(preference)];
    NSAssert(value != nil, @"Incorrect ipv6 value: %li", (long)preference);
    
    return value;
}

+ (OpenVPNCompressionMode)getCompressionModeFromValue:(nullable NSString *)value {
    NSDictionary *options = @{
        OpenVPNCompressionModeEnabledValue: @(OpenVPNCompressionModeEnabled),
        OpenVPNCompressionModeDisabledValue: @(OpenVPNCompressionModeDisabled),
        OpenVPNCompressionModeAsymValue: @(OpenVPNCompressionModeAsym),
        OpenVPNCompressionModeDefaultValue: @(OpenVPNCompressionModeDefault)
    };
    
    NSString *currentValue = [value length] == 0 ? OpenVPNCompressionModeDefaultValue : value;
    
    NSNumber *compressionMode = options[currentValue];
    NSAssert(compressionMode != nil, @"Incorrect compressionMode value: %@", currentValue);
    
    return (OpenVPNCompressionMode)[compressionMode integerValue];
}

+ (nonnull NSString *)getValueFromCompressionMode:(OpenVPNCompressionMode)compressionMode {
    NSDictionary *options = @{
        @(OpenVPNCompressionModeEnabled): OpenVPNCompressionModeEnabledValue,
        @(OpenVPNCompressionModeDisabled): OpenVPNCompressionModeDisabledValue,
        @(OpenVPNCompressionModeAsym): OpenVPNCompressionModeAsymValue,
        @(OpenVPNCompressionModeDefault): OpenVPNCompressionModeDefaultValue
    };
    
    NSString *value = options[@(compressionMode)];
    NSAssert(value != nil, @"Incorrect compressionMode value: %li", (long)compressionMode);
    
    return value;
}

+ (OpenVPNMinTLSVersion)getMinTLSFromValue:(nullable NSString *)value {
    NSDictionary *options = @{
        OpenVPNMinTLSVersionDisabledValue: @(OpenVPNMinTLSVersionDisabled),
        OpenVPNMinTLSVersion10Value: @(OpenVPNMinTLSVersion10),
        OpenVPNMinTLSVersion11Value: @(OpenVPNMinTLSVersion11),
        OpenVPNMinTLSVersion12Value: @(OpenVPNMinTLSVersion12),
        OpenVPNMinTLSVersionDefaultValue: @(OpenVPNMinTLSVersionDefault)
    };
    
    NSString *currentValue = [value length] == 0 ? OpenVPNMinTLSVersionDefaultValue : value;
    
    NSNumber *minTLSVersion = options[currentValue];
    NSAssert(minTLSVersion != nil, @"Incorrect minTLS value: %@", currentValue);
    
    return (OpenVPNMinTLSVersion)[minTLSVersion integerValue];
}

+ (nonnull NSString *)getValueFromMinTLS:(OpenVPNMinTLSVersion)minTLS {
    NSDictionary *options = @{
        @(OpenVPNMinTLSVersionDisabled): OpenVPNMinTLSVersionDisabledValue,
        @(OpenVPNMinTLSVersion10): OpenVPNMinTLSVersion10Value,
        @(OpenVPNMinTLSVersion11): OpenVPNMinTLSVersion11Value,
        @(OpenVPNMinTLSVersion12): OpenVPNMinTLSVersion12Value,
        @(OpenVPNMinTLSVersionDefault): OpenVPNMinTLSVersionDefaultValue
    };
    
    NSString *value = options[@(minTLS)];
    NSAssert(value != nil, @"Incorrect minTLS value: %li", (long)minTLS);
    
    return value;
}

+ (OpenVPNTLSCertProfile)getTLSCertProfileFromValue:(nullable NSString *)value {
    NSDictionary *options = @{
        OpenVPNTLSCertProfileLegacyValue: @(OpenVPNTLSCertProfileLegacy),
        OpenVPNTLSCertProfilePreferredValue: @(OpenVPNTLSCertProfilePreferred),
        OpenVPNTLSCertProfileSuiteBValue: @(OpenVPNTLSCertProfileSuiteB),
        OpenVPNTLSCertProfileLegacyDefaultValue: @(OpenVPNTLSCertProfileLegacyDefault),
        OpenVPNTLSCertProfilePreferredDefaultValue: @(OpenVPNTLSCertProfilePreferredDefault),
        OpenVPNTLSCertProfileDefaultValue: @(OpenVPNTLSCertProfileDefault),
    };
    
    NSString *currentValue = [value length] == 0 ? OpenVPNTLSCertProfileDefaultValue : value;
    
    NSNumber *tlsCertProfile = options[currentValue];
    NSAssert(tlsCertProfile != nil, @"Incorrect tlsCertProfile value: %@", currentValue);
    
    return (OpenVPNTLSCertProfile)[tlsCertProfile integerValue];
}

+ (nonnull NSString *)getValueFromTLSCertProfile:(OpenVPNTLSCertProfile)tlsCertProfile {
    NSDictionary *options = @{
        @(OpenVPNTLSCertProfileLegacy): OpenVPNTLSCertProfileLegacyValue,
        @(OpenVPNTLSCertProfilePreferred): OpenVPNTLSCertProfilePreferredValue,
        @(OpenVPNTLSCertProfileSuiteB): OpenVPNTLSCertProfileSuiteBValue,
        @(OpenVPNTLSCertProfileLegacyDefault): OpenVPNTLSCertProfileLegacyDefaultValue,
        @(OpenVPNTLSCertProfilePreferredDefault): OpenVPNTLSCertProfilePreferredDefaultValue,
        @(OpenVPNTLSCertProfileDefault): OpenVPNTLSCertProfileDefaultValue
    };
    
    NSString *value = options[@(tlsCertProfile)];
    NSAssert(value != nil, @"Incorrect tlsCertProfile value: %li", (long)tlsCertProfile);
    
    return value;
}

@end

@implementation OpenVPNConfiguration

- (NSData *)fileContent {
    return !_config.content.empty() ? [NSData dataWithBytes:_config.content.data() length:_config.content.size()] : nil;
}

- (void)setFileContent:(NSData *)fileContent {
    _config.content = fileContent.length ? std::string((const char *)fileContent.bytes) : "";
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
        self->_config.contentList.push_back(param);
    }];
}

- (NSString *)guiVersion {
    return !_config.guiVersion.empty() ? [NSString stringWithUTF8String:_config.guiVersion.c_str()] : nil;
}

- (void)setGuiVersion:(NSString *)guiVersion {
    _config.guiVersion = guiVersion ? std::string([guiVersion UTF8String]) : "";
}

- (NSString *)ssoMethods {
    return !_config.ssoMethods.empty() ? [NSString stringWithUTF8String:_config.ssoMethods.c_str()] : nil;
}

- (void)setSsoMethods:(NSString *)ssoMethods {
    _config.ssoMethods = ssoMethods ? std::string([ssoMethods UTF8String]) : "";
}

- (NSString *)hardwareAdressOverride {
    return !_config.hwAddrOverride.empty() ? [NSString stringWithUTF8String:_config.hwAddrOverride.c_str()] : nil;
}

- (void)setHardwareAdressOverride:(NSString *)hardwareAdressOverride {
    _config.hwAddrOverride = hardwareAdressOverride ? std::string([hardwareAdressOverride UTF8String]) : "";
}

- (NSString *)platformVersion {
    return !_config.platformVersion.empty() ? [NSString stringWithUTF8String:_config.platformVersion.c_str()] : nil;
}

- (void)setPlatformVersion:(NSString *)platformVersion {
    _config.platformVersion = platformVersion ? std::string([platformVersion UTF8String]) : "";
}

- (NSString *)server {
    return !_config.serverOverride.empty() ? [NSString stringWithUTF8String:_config.serverOverride.c_str()] : nil;
}

- (void)setServer:(NSString *)serverOverride {
    _config.serverOverride = serverOverride ? std::string([serverOverride UTF8String]) : "";
}

- (NSUInteger)port {
    try {
        return std::stoul(_config.portOverride, NULL);
    } catch (...) {
        return 0;
    }
}

- (void)setPort:(NSUInteger)port {
    _config.portOverride = std::to_string(port);
}

- (OpenVPNTransportProtocol)proto {
    NSString *currentValue = [NSString stringWithUTF8String:_config.protoOverride.c_str()];
    return [OpenVPNConfiguration getTransportProtocolFromValue:currentValue];
}

- (void)setProto:(OpenVPNTransportProtocol)proto {
    NSString *value = [OpenVPNConfiguration getValueFromTransportProtocol:proto];
    _config.protoOverride = std::string([value UTF8String]);
}

- (OpenVPNIPv6Preference)ipv6 {
    NSString *currentValue = [NSString stringWithUTF8String:_config.ipv6.c_str()];
    return [OpenVPNConfiguration getIPv6PreferenceFromValue:currentValue];
}

- (void)setIpv6:(OpenVPNIPv6Preference)ipv6 {
    NSString *value = [OpenVPNConfiguration getValueFromIPv6Preference:ipv6];
    _config.ipv6 = std::string([value UTF8String]);
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

- (BOOL)synchronousDNSLookup {
    return _config.synchronousDnsLookup;
}

- (void)setSynchronousDNSLookup:(BOOL)synchronousDNSLookup {
    _config.synchronousDnsLookup = synchronousDNSLookup;
}

- (BOOL)autologinSessions {
    return _config.autologinSessions;
}

- (void)setAutologinSessions:(BOOL)autologinSessions {
    _config.autologinSessions = autologinSessions;
}

- (BOOL)retryOnAuthFailed {
    return _config.retryOnAuthFailed;
}

- (void)setRetryOnAuthFailed:(BOOL)retryOnAuthFailed {
    _config.retryOnAuthFailed = retryOnAuthFailed;
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
    NSString *currentValue = [NSString stringWithUTF8String:_config.compressionMode.c_str()];
    return [OpenVPNConfiguration getCompressionModeFromValue:currentValue];
}

- (void)setCompressionMode:(OpenVPNCompressionMode)compressionMode {
    NSString *value = [OpenVPNConfiguration getValueFromCompressionMode:compressionMode];
    _config.compressionMode = std::string([value UTF8String]);
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
    NSString *currentValue = [NSString stringWithUTF8String:_config.tlsVersionMinOverride.c_str()];
    return [OpenVPNConfiguration getMinTLSFromValue:currentValue];
}

- (void)setMinTLSVersion:(OpenVPNMinTLSVersion)minTLSVersion {
    NSString *value = [OpenVPNConfiguration getValueFromMinTLS:minTLSVersion];
    _config.tlsVersionMinOverride = std::string([value UTF8String]);
}

- (OpenVPNTLSCertProfile)tlsCertProfile {
    NSString *currentValue = [NSString stringWithUTF8String:_config.tlsCertProfileOverride.c_str()];
    return [OpenVPNConfiguration getTLSCertProfileFromValue:currentValue];
}

- (void)setTlsCertProfile:(OpenVPNTLSCertProfile)tlsCertProfile {
    NSString *value = [OpenVPNConfiguration getValueFromTLSCertProfile:tlsCertProfile];
    _config.tlsCertProfileOverride = std::string([value UTF8String]);
}

- (void)setTlsCipherList:(NSArray<NSString *> *)tlsCipherList {
    NSString *cipherList = tlsCipherList ? [tlsCipherList componentsJoinedByString:@":"] : @"";
    _config.tlsCipherList = std::string([cipherList UTF8String]);
}

- (NSArray<NSString *> *)tlsCipherList {
    if (_config.tlsCipherList.empty()) { return nil; }
    
    NSString *cipherList = [NSString stringWithUTF8String:_config.tlsCipherList.c_str()];
    return [cipherList componentsSeparatedByString:@":"];
}

- (void)setTlsCiphersuitesList:(NSArray<NSString *> *)tlsCiphersuitesList {
    NSString *cipherList = tlsCiphersuitesList ? [tlsCiphersuitesList componentsJoinedByString:@":"] : @"";
    _config.tlsCiphersuitesList = std::string([cipherList UTF8String]);
}

- (NSArray<NSString *> *)tlsCiphersuitesList {
    if (_config.tlsCiphersuitesList.empty()) { return nil; }
    
    NSString *ciphersuitesList = [NSString stringWithUTF8String:_config.tlsCiphersuitesList.c_str()];
    return [ciphersuitesList componentsSeparatedByString:@":"];
}

- (NSDictionary<NSString *,NSString *> *)peerInfo {
    if (_config.peerInfo.empty()) {
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
        self->_config.peerInfo.push_back(param);
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

- (NSUInteger)clockTick {
    return _config.clockTickMS;
}

- (void)setClockTick:(NSUInteger)clockTick {
    _config.clockTickMS = clockTick;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)copyWithZone:(NSZone *)zone {
    OpenVPNConfiguration *configuration = [[OpenVPNConfiguration allocWithZone:zone] init];
    configuration.fileContent = [self.fileContent copyWithZone:zone];
    configuration.settings = [self.settings copyWithZone:zone];
    configuration.guiVersion = [self.guiVersion copyWithZone:zone];
    configuration.ssoMethods = [self.ssoMethods copyWithZone:zone];
    configuration.hardwareAdressOverride = [self.hardwareAdressOverride copyWithZone:zone];
    configuration.platformVersion = [self.platformVersion copyWithZone:zone];
    configuration.server = [self.server copyWithZone:zone];
    configuration.proto = self.proto;
    configuration.ipv6 = self.ipv6;
    configuration.connectionTimeout = self.connectionTimeout;
    configuration.tunPersist = self.tunPersist;
    configuration.googleDNSFallback = self.googleDNSFallback;
    configuration.synchronousDNSLookup = self.synchronousDNSLookup;
    configuration.autologinSessions = self.autologinSessions;
    configuration.disableClientCert = self.disableClientCert;
    configuration.sslDebugLevel = self.sslDebugLevel;
    configuration.compressionMode = self.compressionMode;
    configuration.privateKeyPassword = [self.privateKeyPassword copyWithZone:zone];
    configuration.keyDirection = self.keyDirection;
    configuration.forceCiphersuitesAESCBC = self.forceCiphersuitesAESCBC;
    configuration.minTLSVersion = self.minTLSVersion;
    configuration.tlsCertProfile = self.tlsCertProfile;
    configuration.peerInfo = [self.peerInfo copyWithZone:zone];
    configuration.echo = self.echo;
    configuration.info = self.info;
    configuration.clockTick = self.clockTick;
    return configuration;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.fileContent forKey:NSStringFromSelector(@selector(fileContent))];
    [aCoder encodeObject:self.settings forKey:NSStringFromSelector(@selector(settings))];
    [aCoder encodeObject:self.guiVersion forKey:NSStringFromSelector(@selector(guiVersion))];
    [aCoder encodeObject:self.ssoMethods forKey:NSStringFromSelector(@selector(ssoMethods))];
    [aCoder encodeObject:self.hardwareAdressOverride forKey:NSStringFromSelector(@selector(hardwareAdressOverride))];
    [aCoder encodeObject:self.platformVersion forKey:NSStringFromSelector(@selector(platformVersion))];
    [aCoder encodeObject:self.server forKey:NSStringFromSelector(@selector(server))];
    [aCoder encodeInteger:self.proto forKey:NSStringFromSelector(@selector(proto))];
    [aCoder encodeInteger:self.ipv6 forKey:NSStringFromSelector(@selector(ipv6))];
    [aCoder encodeInteger:self.connectionTimeout forKey:NSStringFromSelector(@selector(connectionTimeout))];
    [aCoder encodeBool:self.tunPersist forKey:NSStringFromSelector(@selector(tunPersist))];
    [aCoder encodeBool:self.googleDNSFallback forKey:NSStringFromSelector(@selector(googleDNSFallback))];
    [aCoder encodeBool:self.synchronousDNSLookup forKey:NSStringFromSelector(@selector(synchronousDNSLookup))];
    [aCoder encodeBool:self.autologinSessions forKey:NSStringFromSelector(@selector(autologinSessions))];
    [aCoder encodeBool:self.disableClientCert forKey:NSStringFromSelector(@selector(disableClientCert))];
    [aCoder encodeInteger:self.sslDebugLevel forKey:NSStringFromSelector(@selector(sslDebugLevel))];
    [aCoder encodeInteger:self.compressionMode forKey:NSStringFromSelector(@selector(compressionMode))];
    [aCoder encodeObject:self.privateKeyPassword forKey:NSStringFromSelector(@selector(privateKeyPassword))];
    [aCoder encodeInteger:self.keyDirection forKey:NSStringFromSelector(@selector(keyDirection))];
    [aCoder encodeBool:self.forceCiphersuitesAESCBC forKey:NSStringFromSelector(@selector(forceCiphersuitesAESCBC))];
    [aCoder encodeInteger:self.minTLSVersion forKey:NSStringFromSelector(@selector(minTLSVersion))];
    [aCoder encodeInteger:self.tlsCertProfile forKey:NSStringFromSelector(@selector(tlsCertProfile))];
    [aCoder encodeObject:self.peerInfo forKey:NSStringFromSelector(@selector(peerInfo))];
    [aCoder encodeBool:self.echo forKey:NSStringFromSelector(@selector(echo))];
    [aCoder encodeBool:self.info forKey:NSStringFromSelector(@selector(info))];
    [aCoder encodeInteger:self.clockTick forKey:NSStringFromSelector(@selector(clockTick))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        self.fileContent = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(fileContent))];
        self.settings = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:NSStringFromSelector(@selector(settings))];
        self.guiVersion = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(guiVersion))];
        self.ssoMethods = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(ssoMethods))];
        self.hardwareAdressOverride = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(hardwareAdressOverride))];
        self.platformVersion = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(platformVersion))];
        self.server = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(server))];
        self.proto = (OpenVPNTransportProtocol)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(proto))];
        self.ipv6 = (OpenVPNIPv6Preference)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(ipv6))];
        self.connectionTimeout = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(connectionTimeout))];
        self.tunPersist = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(tunPersist))];
        self.googleDNSFallback = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(googleDNSFallback))];
        self.synchronousDNSLookup = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(synchronousDNSLookup))];
        self.autologinSessions = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(autologinSessions))];
        self.disableClientCert = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(disableClientCert))];
        self.sslDebugLevel = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(sslDebugLevel))];
        self.compressionMode = (OpenVPNCompressionMode)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(compressionMode))];
        self.privateKeyPassword = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(privateKeyPassword))];
        self.keyDirection = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(keyDirection))];
        self.forceCiphersuitesAESCBC = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(forceCiphersuitesAESCBC))];
        self.minTLSVersion = (OpenVPNMinTLSVersion)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(minTLSVersion))];
        self.tlsCertProfile = (OpenVPNTLSCertProfile)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(tlsCertProfile))];
        self.peerInfo = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:NSStringFromSelector(@selector(peerInfo))];
        self.echo = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(echo))];
        self.info = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(info))];
        self.clockTick = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(clockTick))];
    }
    return self;
}

@end

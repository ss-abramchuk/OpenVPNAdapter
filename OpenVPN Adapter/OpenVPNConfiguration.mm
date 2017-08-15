//
//  OpenVPNConfiguration.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import "OpenVPNConfiguration+Internal.h"

#import "OpenVPNContentPair.h"

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

- (NSString *)content {
    return !_config.content.empty() ? [NSString stringWithUTF8String:_config.content.c_str()] : nil;
}

- (void)setContent:(NSString *)fileContent {
    _config.content = fileContent ? std::string(fileContent.UTF8String) : "";
}

- (NSArray <OpenVPNContentPair *> *)contentList {
    NSMutableArray *contentList = [[NSMutableArray alloc] init];
    
    for (ClientAPI::KeyValue param : _config.contentList) {
        [contentList addObject:[[OpenVPNContentPair alloc] initWithKey:[NSString stringWithCString:param.key.c_str() encoding:NSUTF8StringEncoding] value:[NSString stringWithCString:param.value.c_str() encoding:NSUTF8StringEncoding]]];
    }
    
    return [contentList copy];
}

- (void)setContentList:(NSArray <OpenVPNContentPair *> *)contentList {
    _config.contentList.clear();
    
    for (OpenVPNContentPair *pair in contentList) {
        ClientAPI::KeyValue param = ClientAPI::KeyValue(std::string(pair.key.UTF8String), std::string((pair.value ?: @"").UTF8String));
        _config.contentList.push_back(param);
    }
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

- (OpenVPNTransportProtocol)transportProtocol {
    NSString *currentValue = [NSString stringWithUTF8String:_config.protoOverride.c_str()];
    return [OpenVPNConfiguration getTransportProtocolFromValue:currentValue];
}

- (void)setTransportProtocol:(OpenVPNTransportProtocol)proto {
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

- (BOOL)autologinSessions {
    return _config.autologinSessions;
}

- (void)setAutologinSessions:(BOOL)autologinSessions {
    _config.autologinSessions = autologinSessions;
}

- (BOOL)disableClientCertificate {
    return _config.disableClientCert;
}

- (void)setDisableClientCertificate:(BOOL)disableClientCertificate {
    _config.disableClientCert = disableClientCertificate;
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

- (OpenVPNMinTLSVersion)minimumTLSVersion {
    NSString *currentValue = [NSString stringWithUTF8String:_config.tlsVersionMinOverride.c_str()];
    return [OpenVPNConfiguration getMinTLSFromValue:currentValue];
}

- (void)setMinimumTLSVersion:(OpenVPNMinTLSVersion)minTLSVersion {
    NSString *value = [OpenVPNConfiguration getValueFromMinTLS:minTLSVersion];
    _config.tlsVersionMinOverride = std::string([value UTF8String]);
}

- (OpenVPNTLSCertProfile)tlsCertificateProfile {
    NSString *currentValue = [NSString stringWithUTF8String:_config.tlsCertProfileOverride.c_str()];
    return [OpenVPNConfiguration getTLSCertProfileFromValue:currentValue];
}

- (void)setTlsCertifiateProfile:(OpenVPNTLSCertProfile)tlsCertProfile {
    NSString *value = [OpenVPNConfiguration getValueFromTLSCertProfile:tlsCertProfile];
    _config.tlsCertProfileOverride = std::string([value UTF8String]);
}

- (NSArray <OpenVPNContentPair *> *)peerInfo {
    NSMutableArray *contentList = [[NSMutableArray alloc] init];
    
    for (ClientAPI::KeyValue param : _config.peerInfo) {
        [contentList addObject:[[OpenVPNContentPair alloc] initWithKey:[NSString stringWithCString:param.key.c_str() encoding:NSUTF8StringEncoding] value:[NSString stringWithCString:param.value.c_str() encoding:NSUTF8StringEncoding]]];
    }
    
    return [contentList copy];
}

- (void)setPeerInfo:(NSArray <OpenVPNContentPair *> *)peerInfo {
    _config.peerInfo.clear();
    
    for (OpenVPNContentPair *pair in peerInfo) {
        ClientAPI::KeyValue param = ClientAPI::KeyValue(std::string(pair.key.UTF8String), std::string((pair.value ?: @"").UTF8String));
        _config.peerInfo.push_back(param);
    }
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

- (id)copyWithZone:(NSZone *)zone {
    OpenVPNConfiguration *configuration = [[OpenVPNConfiguration allocWithZone:zone] init];
    configuration.content = [self.content copyWithZone:zone];
    configuration.contentList = [self.contentList copyWithZone:zone];
    configuration.guiVersion = [self.guiVersion copyWithZone:zone];
    configuration.server = [self.server copyWithZone:zone];
    configuration.transportProtocol = self.transportProtocol;
    configuration.ipv6 = self.ipv6;
    configuration.connectionTimeout = self.connectionTimeout;
    configuration.tunPersist = self.tunPersist;
    configuration.googleDNSFallback = self.googleDNSFallback;
    configuration.autologinSessions = self.autologinSessions;
    configuration.disableClientCertificate = self.disableClientCertificate;
    configuration.sslDebugLevel = self.sslDebugLevel;
    configuration.compressionMode = self.compressionMode;
    configuration.privateKeyPassword = [self.privateKeyPassword copyWithZone:zone];
    configuration.keyDirection = self.keyDirection;
    configuration.forceCiphersuitesAESCBC = self.forceCiphersuitesAESCBC;
    configuration.minimumTLSVersion = self.minimumTLSVersion;
    configuration.tlsCertificateProfile = self.tlsCertificateProfile;
    configuration.peerInfo = [self.peerInfo copyWithZone:zone];
    configuration.echo = self.echo;
    configuration.info = self.info;
    configuration.clockTick = self.clockTick;
    return configuration;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        self.content = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(content))];
        self.contentList = [aDecoder decodeObjectOfClass:[NSArray class] forKey:NSStringFromSelector(@selector(contentList))];
        self.guiVersion = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(guiVersion))];
        self.server = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(server))];
        self.transportProtocol = (OpenVPNTransportProtocol)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(transportProtocol))];
        self.ipv6 = (OpenVPNIPv6Preference)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(ipv6))];
        self.connectionTimeout = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(connectionTimeout))];
        self.tunPersist = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(tunPersist))];
        self.googleDNSFallback = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(googleDNSFallback))];
        self.autologinSessions = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(autologinSessions))];
        self.disableClientCertificate = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(disableClientCertificate))];
        self.sslDebugLevel = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(sslDebugLevel))];
        self.compressionMode = (OpenVPNCompressionMode)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(compressionMode))];
        self.privateKeyPassword = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(privateKeyPassword))];
        self.keyDirection = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(keyDirection))];
        self.forceCiphersuitesAESCBC = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(forceCiphersuitesAESCBC))];
        self.minimumTLSVersion = (OpenVPNMinTLSVersion)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(minimumTLSVersion))];
        self.tlsCertificateProfile = (OpenVPNTLSCertProfile)[aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(tlsCertificateProfile))];
        self.peerInfo = [aDecoder decodeObjectOfClass:[NSArray class] forKey:NSStringFromSelector(@selector(peerInfo))];
        self.echo = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(echo))];
        self.info = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(info))];
        self.clockTick = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(clockTick))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.content forKey:NSStringFromSelector(@selector(content))];
    [aCoder encodeObject:self.contentList forKey:NSStringFromSelector(@selector(contentList))];
    [aCoder encodeObject:self.guiVersion forKey:NSStringFromSelector(@selector(guiVersion))];
    [aCoder encodeObject:self.server forKey:NSStringFromSelector(@selector(server))];
    [aCoder encodeInteger:self.transportProtocol forKey:NSStringFromSelector(@selector(transportProtocol))];
    [aCoder encodeInteger:self.ipv6 forKey:NSStringFromSelector(@selector(ipv6))];
    [aCoder encodeInteger:self.connectionTimeout forKey:NSStringFromSelector(@selector(connectionTimeout))];
    [aCoder encodeBool:self.tunPersist forKey:NSStringFromSelector(@selector(tunPersist))];
    [aCoder encodeBool:self.googleDNSFallback forKey:NSStringFromSelector(@selector(googleDNSFallback))];
    [aCoder encodeBool:self.autologinSessions forKey:NSStringFromSelector(@selector(autologinSessions))];
    [aCoder encodeBool:self.disableClientCertificate forKey:NSStringFromSelector(@selector(disableClientCertificate))];
    [aCoder encodeInteger:self.sslDebugLevel forKey:NSStringFromSelector(@selector(sslDebugLevel))];
    [aCoder encodeInteger:self.compressionMode forKey:NSStringFromSelector(@selector(compressionMode))];
    [aCoder encodeObject:self.privateKeyPassword forKey:NSStringFromSelector(@selector(privateKeyPassword))];
    [aCoder encodeInteger:self.keyDirection forKey:NSStringFromSelector(@selector(keyDirection))];
    [aCoder encodeBool:self.forceCiphersuitesAESCBC forKey:NSStringFromSelector(@selector(forceCiphersuitesAESCBC))];
    [aCoder encodeInteger:self.minimumTLSVersion forKey:NSStringFromSelector(@selector(minimumTLSVersion))];
    [aCoder encodeInteger:self.tlsCertificateProfile forKey:NSStringFromSelector(@selector(tlsCertificateProfile))];
    [aCoder encodeObject:self.peerInfo forKey:NSStringFromSelector(@selector(peerInfo))];
    [aCoder encodeBool:self.echo forKey:NSStringFromSelector(@selector(echo))];
    [aCoder encodeBool:self.info forKey:NSStringFromSelector(@selector(info))];
    [aCoder encodeInteger:self.clockTick forKey:NSStringFromSelector(@selector(clockTick))];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

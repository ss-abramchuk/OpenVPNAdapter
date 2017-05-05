//
//  OpenVPNConfiguration+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNConfiguration.h"

using namespace openvpn;

@interface OpenVPNConfiguration (Internal)

@property (readonly) ClientAPI::Config config;

+ (OpenVPNTransportProtocol)getTransportProtocolFromValue:(nullable NSString *)value;
+ (nonnull NSString *)getValueFromTransportProtocol:(OpenVPNTransportProtocol)protocol;

+ (OpenVPNIPv6Preference)getIPv6PreferenceFromValue:(nullable NSString *)value;
+ (nonnull NSString *)getValueFromIPv6Preference:(OpenVPNIPv6Preference)preference;

+ (OpenVPNCompressionMode)getCompressionModeFromValue:(nullable NSString *)value;
+ (nonnull NSString *)getValueFromCompressionMode:(OpenVPNCompressionMode)compressionMode;

+ (OpenVPNMinTLSVersion)getMinTLSFromValue:(nullable NSString *)value;
+ (nonnull NSString *)getValueFromMinTLS:(OpenVPNMinTLSVersion)minTLS;

+ (OpenVPNTLSCertProfile)getTLSCertProfileFromValue:(nullable NSString *)value;
+ (nonnull NSString *)getValueFromTLSCertProfile:(OpenVPNTLSCertProfile)tlsCertProfile;

@end

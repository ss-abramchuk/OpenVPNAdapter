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

+ (OpenVPNTransportProtocol)getTransportProtocolFromString:(nullable NSString *)value;
+ (nonnull NSString *)getStringFromTransportProtocol:(OpenVPNTransportProtocol)protocol;

+ (OpenVPNIPv6Preference)getIPv6PreferenceFromString:(nullable NSString *)value;
+ (nonnull NSString *)getStringFromIPv6Preference:(OpenVPNIPv6Preference)preference;

+ (OpenVPNCompressionMode)getCompressionModeFromString:(nullable NSString *)value;
+ (nonnull NSString *)getStringFromCompressionMode:(OpenVPNCompressionMode)compressionMode;

@end

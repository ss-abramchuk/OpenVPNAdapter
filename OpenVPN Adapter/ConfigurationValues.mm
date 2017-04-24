//
//  ConfigurationValues.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 24.04.17.
//
//

#import "ConfigurationValues.h"

NSString * const OpenVPNMinTLSVersionDisabledValue = @"disabled";
NSString * const OpenVPNMinTLSVersion10Value = @"tls_1_0";
NSString * const OpenVPNMinTLSVersion11Value = @"tls_1_1";
NSString * const OpenVPNMinTLSVersion12Value = @"tls_1_2";
NSString * const OpenVPNMinTLSVersionDefaultValue = @"default";

NSString * const OpenVPNTLSCertProfileLegacyValue = @"legacy";
NSString * const OpenVPNTLSCertProfilePreferredValue = @"preferred";
NSString * const OpenVPNTLSCertProfileSuiteBValue = @"suiteb";
NSString * const OpenVPNTLSCertProfileLegacyDefaultValue = @"legacy-default";
NSString * const OpenVPNTLSCertProfilePreferredDefaultValue = @"preferred-default";
NSString * const OpenVPNTLSCertProfileDefaultValue = @"default";

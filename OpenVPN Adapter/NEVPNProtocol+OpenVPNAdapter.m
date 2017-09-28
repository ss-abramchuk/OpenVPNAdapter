//
//  NEVPNProtocol+OpenVPNConfiguration.m
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 28/09/2017.
//

#import "NEVPNProtocol+OpenVPNAdapter.h"

#import "OpenVPNConfiguration.h"
#import "OpenVPNCredentials.h"

NSString * const OpenVPNAdapterConfigurationKey = @"OpenVPNAdapterConfigurationKey";

@implementation NEVPNProtocol (OpenVPNAdapter)

- (id)providerObjectOfClass:(Class)class ForKey:(NSString *)key {
    if (![self isKindOfClass:[NETunnelProviderProtocol class]]) return nil;
    id data = ((NETunnelProviderProtocol *)self).providerConfiguration[key];
    if (![data isKindOfClass:[NSData class]]) return nil;
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![object isKindOfClass:class]) return nil;
    return object;
}

- (void)setProviderConfigurationObject:(id<NSSecureCoding>)object forKey:(NSString *)key {
    if (![self isKindOfClass:[NETunnelProviderProtocol class]]) return;
    NSMutableDictionary *providerConfiguration = [((NETunnelProviderProtocol *)self).providerConfiguration mutableCopy] ?: [[NSMutableDictionary alloc] init];
    providerConfiguration[key] = object ? [NSKeyedArchiver archivedDataWithRootObject:object] : nil;
    ((NETunnelProviderProtocol *)self).providerConfiguration = [providerConfiguration copy];
}

- (OpenVPNConfiguration *)openVPNConfiguration {
    return [self providerObjectOfClass:[OpenVPNConfiguration class] ForKey:OpenVPNAdapterConfigurationKey];
}

- (void)setOpenVPNConfiguration:(OpenVPNConfiguration *)openVPNConfiguration {
    [self setProviderConfigurationObject:openVPNConfiguration forKey:OpenVPNAdapterConfigurationKey];
}

- (OpenVPNCredentials *)openVPNCredentials {
    if (!self.username.length) return nil;
    if (!self.passwordReference) return nil;
    
    CFTypeRef reference;
    NSDictionary *query = @{(id)kSecClass: (id)kSecClassGenericPassword,
                            (id)kSecReturnData: (id)kCFBooleanTrue,
                            (id)kSecValuePersistentRef: self.passwordReference};
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &reference) != errSecSuccess) return nil;
    
    NSString *password = [[NSString alloc] initWithData:(__bridge NSData *)reference encoding:NSUTF8StringEncoding];
    if (!password.length) return nil;
    
    OpenVPNCredentials *credentials = [[OpenVPNCredentials alloc] init];
    credentials.username = self.username;
    credentials.password = password;
    return credentials;
}

@end

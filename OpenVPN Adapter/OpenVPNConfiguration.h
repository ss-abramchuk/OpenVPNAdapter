//
//  OpenVPNConfiguration.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import <Foundation/Foundation.h>

// TODO: Wrap ClientAPI::Config into Objective-C class

/**
 IPv6 preference options

 - IPv6PreferenceEnabled: request combined IPv4/IPv6 tunnel
 - IPv6PreferenceDisabled: disable IPv6, so tunnel will be IPv4-only
 - IPv6PreferenceDefault: leave decision to server
 */
typedef NS_ENUM(NSInteger, IPv6Preference) {
    IPv6PreferenceEnabled,
    IPv6PreferenceDisabled,
    IPv6PreferenceDefault
};

@interface OpenVPNConfiguration : NSObject

/**
 OpenVPN profile as a NSData
 */
@property (nullable, nonatomic) NSData *fileContent;

/**
 OpenVPN profile as series of key/value pairs (may be provided exclusively
 or in addition to file content).
 */
@property (nullable, nonatomic) NSDictionary<NSString *, NSString *> *settings;

/**
 Set to identity OpenVPN GUI version.
 Format should be "<gui_identifier><space><version>"
 Passed to server as IV_GUI_VER.
 */
@property (nullable, nonatomic) NSString *guiVersion;

/**
 Use a different server than that specified in "remote"
 option of profile
 */
@property (nullable, nonatomic) NSString *serverOverride;

/**
 Force a given transport protocol
 Should be tcp, udp, or adaptive.
 */
@property (nullable, nonatomic) NSString *protoOverride;

/**
 IPv6 preference
 */
@property (nonatomic) IPv6Preference ipv6;

@end

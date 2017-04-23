//
//  OpenVPNConfiguration.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import <Foundation/Foundation.h>

// TODO: Wrap ClientAPI::Config into Objective-C class

typedef NS_ENUM(NSInteger, OpenVPNTransportProtocol) {
    OpenVPNTransportProtocolUDP,
    OpenVPNTransportProtocolTCP,
    OpenVPNTransportProtocolAdaptive,
    OpenVPNTransportProtocolDefault
};

/**
 IPv6 preference options
 */
typedef NS_ENUM(NSInteger, OpenVPNIPv6Preference) {
    /// Request combined IPv4/IPv6 tunnel
    OpenVPNIPv6PreferenceEnabled,
    /// Disable IPv6, so tunnel will be IPv4-only
    OpenVPNIPv6PreferenceDisabled,
    /// Leave decision to server
    OpenVPNIPv6PreferenceDefault
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
@property (nullable, nonatomic) NSString *server;

/**
 Force a given transport protocol
 */
@property (nonatomic) OpenVPNTransportProtocol proto;

/**
 IPv6 preference
 */
@property (nonatomic) OpenVPNIPv6Preference ipv6;

/**
 Connection timeout in seconds, or 0 to retry indefinitely
 */
@property (nonatomic) NSInteger connectionTimeout;

/**
 Keep tun interface active during pauses or reconnections
 */
@property (nonatomic) BOOL tunPersist;

/**
 If true and a redirect-gateway profile doesn't also define
 DNS servers, use the standard Google DNS servers.
 */
@property (nonatomic) BOOL googleDNSFallback;

/**
 Enable autologin sessions
 */
@property (nonatomic) BOOL autologinSessions;

@end

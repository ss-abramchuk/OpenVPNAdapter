//
//  OpenVPNConfiguration.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNTransportProtocol);
typedef NS_ENUM(NSInteger, OpenVPNIPv6Preference);
typedef NS_ENUM(NSInteger, OpenVPNCompressionMode);
typedef NS_ENUM(NSInteger, OpenVPNMinTLSVersion);
typedef NS_ENUM(NSInteger, OpenVPNTLSCertProfile);

/**
 Class used to pass configuration
 */
@interface OpenVPNConfiguration : NSObject <NSCopying, NSSecureCoding>

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
 Set to a comma seperated list of supported SSO mechanisms that may
 be signalled via INFO_PRE to the client.
 "openurl" is to continue authentication by opening an url in a browser
 "crtext" gives a challenge response in text format that needs to
 responded via control channel.
 Passed to the server as IV_SSO.
*/
@property (nullable, nonatomic) NSString *ssoMethods;

/**
 Override the string that is passed as IV_HWADDR to the server.
*/
@property (nullable, nonatomic) NSString *hardwareAdressOverride;

/**
 Set the string that is passed to the server as IV_PLAT_VER
*/
@property (nullable, nonatomic) NSString *platformVersion;

/**
 Use a different server than that specified in "remote"
 option of profile
 */
@property (nullable, nonatomic) NSString *server;

/**
 Use a different port than that specified in "remote"
 option of profile
 */
@property (nonatomic) NSUInteger port;

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
 If YES and a redirect-gateway profile doesn't also define
 DNS servers, use the standard Google DNS servers.
 */
@property (nonatomic) BOOL googleDNSFallback;

/**
 Whether to do DNS lookups synchronously.
 */
@property (nonatomic) BOOL synchronousDNSLookup;

/**
 Enable autologin sessions
 */
@property (nonatomic) BOOL autologinSessions;

/**
 If YES, consider AUTH_FAILED to be a non-fatal error,
 and retry the connection after a pause.
 */
@property (nonatomic) BOOL retryOnAuthFailed;

/**
 If YES, don't send client cert/key to peer
 */
@property (nonatomic) BOOL disableClientCert;

/**
 SSL library debug level
 */
@property (nonatomic) NSInteger sslDebugLevel;

/**
 Compression mode
 */
@property (nonatomic) OpenVPNCompressionMode compressionMode;

/**
 Private key password
 */
@property (nullable, nonatomic) NSString *privateKeyPassword;

/**
 Default key direction parameter for tls-auth (0, 1, 
 or -1 (bidirectional -- default)) if no key-direction 
 parameter defined in profile
 */
@property (nonatomic) NSInteger keyDirection;

/**
 If YES, force ciphersuite to be one of:
 1. TLS_DHE_RSA_WITH_AES_256_CBC_SHA, or
 2. TLS_DHE_RSA_WITH_AES_128_CBC_SHA
 and disable setting TLS minimum version.
 This is intended for compatibility with legacy systems.
 */
@property (nonatomic) BOOL forceCiphersuitesAESCBC;

/**
 Override the minimum TLS version
 */
@property (nonatomic) OpenVPNMinTLSVersion minTLSVersion;

/**
 Override or default the tls-cert-profile setting
 */
@property (nonatomic) OpenVPNTLSCertProfile tlsCertProfile;

/**
 Overrides the list of tls ciphers like the tls-cipher option
 */
@property (nullable, nonatomic) NSArray<NSString *> *tlsCipherList;

/**
 Overrides the list of TLS 1.3 ciphersuites like the tls-ciphersuites option
 */
@property (nullable, nonatomic) NSArray<NSString *> *tlsCiphersuitesList;

/**
 Pass custom key/value pairs to OpenVPN server
 */
@property (nullable, nonatomic) NSDictionary<NSString *, NSString *> *peerInfo;

/**
 Pass through pushed "echo" directives via "ECHO" event
 */
@property (nonatomic) BOOL echo;

/**
 Pass through control channel INFO notifications via "INFO" event
 */
@property (nonatomic) BOOL info;

/**
 Periodic convenience clock tick in milliseconds. Will call 
 [OpenVPNAdapterDelegate tick] at a frequency defined by this parameter.
 Set to 0 to disable.
 */
@property (nonatomic) NSUInteger clockTick;

@end

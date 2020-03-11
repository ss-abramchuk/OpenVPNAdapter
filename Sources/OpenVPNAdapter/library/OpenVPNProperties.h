//
//  OpenVPNProperties.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNTransportProtocol);
@class OpenVPNServerEntry;

@interface OpenVPNProperties : NSObject

/**
 This username must be used with profile
 */
@property (nullable, readonly, nonatomic) NSString *username;

/**
 Profile name of config
 */
@property (nullable, readonly, nonatomic) NSString *profileName;

/**
 "Friendly" name of config
 */
@property (nullable, readonly, nonatomic) NSString *friendlyName;

/**
 If YES no creds required, otherwise username/password required
 */
@property (readonly, nonatomic) BOOL autologin;

/**
 Static challenge, may be empty, ignored if autologin
 */
@property (nullable, readonly, nonatomic) NSString *staticChallenge;

/**
 YES if static challenge response should be echoed to UI, ignored if autologin
 */
@property (readonly, nonatomic) BOOL staticChallengeEcho;

/**
 YES if this profile requires a private key password
 */
@property (readonly, nonatomic, getter=isPrivateKeyPasswordRequired) BOOL privateKeyPasswordRequired;

/**
 YES if user is allowed to save authentication password in UI
 */
@property (readonly, nonatomic) BOOL allowPasswordSave;

/**
 Address of the first remote item in config
 */
@property (nullable, readonly, nonatomic) NSString *remoteHost;

/**
 Port of the first remote item in config
 */
@property (readonly, nonatomic) NSUInteger remotePort;

/**
 Transport protocol of the first remote item in config
 */
@property (readonly, nonatomic) OpenVPNTransportProtocol remoteProto;

/**
 Optional list of user-selectable VPN servers
 */
@property (nullable, readonly, nonatomic) NSArray<OpenVPNServerEntry *> *servers;

- (nonnull instancetype) init NS_UNAVAILABLE;

@end

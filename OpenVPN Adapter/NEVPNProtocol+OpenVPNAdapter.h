//
//  NEVPNProtocol+OpenVPNAdapter.h
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 28/09/2017.
//

@import NetworkExtension;

@class OpenVPNConfiguration;
@class OpenVPNCredentials;

@interface NEVPNProtocol (OpenVPNAdapter)

/*
 The configuration object for the OpenVPN session.
 */
@property (nonatomic, nullable) OpenVPNConfiguration *openVPNConfiguration;

/*
 The credentials object for the OpenVPN session, derived from the username and passwordReference properties on self.
 */
@property (nonatomic, nullable, readonly) OpenVPNCredentials *openVPNCredentials;

@end

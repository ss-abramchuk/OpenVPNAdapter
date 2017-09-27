//
//  OpenVPNTunnelProvider.h
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 26/09/2017.
//

#import <NetworkExtension/NetworkExtension.h>

NS_ASSUME_NONNULL_BEGIN

@class OpenVPNConfiguration;
@class OpenVPNCredentials;

extern NSString * const OpenVPNTunnelProviderConfigurationKey;

/*!
 * @interface OpenVPNTunnelProvider
 * @discussion The OpenVPNTunnelProvider subclass is a convenient way to use OpenVPNAdapter in conjunction with the NetworkExtension framework.
 *
 * OpenVPNTunnelProvider is a subclass of NEPacketTunnelProvider which provides all the necessary logic to establish an OpenVPN tunnel via a Packet Tunnel Provider Extension.
 *
 * In order to provide an OpenVPNConfiguration object to OpenVPNTunnelProvider, the following procedure must be followed:
 * 1) Create a valid OpenVPNConfiguration object with the desired configuration,
 * 2) Convert it to an NSData object via NSKeyedArchiver
 * 3) Add this data object to the providerConfiguration dictionary on NETunnelProviderProtocol using OpenVPNTunnelProviderConfigurationKey as the key.
 *
 * Credentials are aquired using the username and passwordReference properties on NETunnelProviderProtocol.
 * @note Only username/password or client certificate authentication is supported when using OpenVPNTunnelProvider.
 */
@interface OpenVPNTunnelProvider : NEPacketTunnelProvider

@end
           
NS_ASSUME_NONNULL_END

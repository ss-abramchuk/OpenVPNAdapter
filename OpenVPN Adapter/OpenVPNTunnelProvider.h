//
//  OpenVPNTunnelProvider.h
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 26/09/2017.
//

@import NetworkExtension;

NS_ASSUME_NONNULL_BEGIN

@class OpenVPNAdapter;
@class OpenVPNConfiguration;
@class OpenVPNConnectionInfo;
@class OpenVPNCredentials;
@class OpenVPNConnectionInfo;
@class OpenVPNInterfaceStats;
@class OpenVPNSessionToken;
@class OpenVPNTransportStats;

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

/**
 Returns information about the most recent connection once the tunnel connection state is connected, otherwise nil.
 */
@property (nonatomic, readonly, nullable) OpenVPNConnectionInfo *connectionInformation;

/**
 Return current session token if available, otherwise nil.
 */
@property (nonatomic, readonly, nullable) OpenVPNSessionToken *sessionToken;

/**
 Return transport statistics.
 */
@property (nonatomic, readonly) OpenVPNTransportStats *transportStatistics;

/**
 Return tunnel interface statistics.
 */
@property (nonatomic, readonly) OpenVPNInterfaceStats *interfaceStatistics;

@end
           
NS_ASSUME_NONNULL_END

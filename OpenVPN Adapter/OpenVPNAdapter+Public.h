//
//  OpenVPNAdapter+Public.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import "OpenVPNAdapterEvent.h"
#import "OpenVPNAdapter.h"

@class OpenVPNConfiguration;
@class OpenVPNProperties;
@class OpenVPNCredentials;
@class OpenVPNConnectionInfo;
@class OpenVPNSessionToken;
@class OpenVPNTransportStats;
@class OpenVPNInterfaceStats;
@class NEPacketTunnelNetworkSettings;

// TODO: Add documentation to properties and methods

/**
 <#Description#>
 */
@protocol OpenVPNAdapterPacketFlow <NSObject>

/**
 <#Description#>

 @param completionHandler <#completionHandler description#>
 */
- (void)readPacketsWithCompletionHandler:(nonnull void (^)(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols))completionHandler;

/**
 <#Description#>

 @param packets <#packets description#>
 @param protocols <#protocols description#>
 @return <#return value description#>
 */
- (BOOL)writePackets:(nonnull NSArray<NSData *> *)packets withProtocols:(nonnull NSArray<NSNumber *> *)protocols;

@end

/**
 <#Description#>
 */
@protocol OpenVPNAdapterDelegate <NSObject>

/**
 <#Description#>

 @param settings <#settings description#>
 @param callback <#callback description#>
 */
- (void)configureTunnelWithSettings:(nonnull NEPacketTunnelNetworkSettings *)settings
                 callback:(nonnull void (^)(id<OpenVPNAdapterPacketFlow> _Nullable flow))callback
NS_SWIFT_NAME(configureTunnel(settings:callback:));

/**
 <#Description#>

 @param event <#event description#>
 @param message <#message description#>
 */
- (void)handleEvent:(OpenVPNAdapterEvent)event
            message:(nullable NSString *)message
NS_SWIFT_NAME(handle(event:message:));

/**
 <#Description#>

 @param error <#error description#>
 */
- (void)handleError:(nonnull NSError *)error
NS_SWIFT_NAME(handle(error:));

@optional

/**
 <#Description#>

 @param logMessage <#logMessage description#>
 */
- (void)handleLog:(nonnull NSString *)logMessage
NS_SWIFT_NAME(handle(logMessage:));

/**
 <#Description#>
 */
- (void)tick;

@end

/**
 <#Description#>
 */
@interface OpenVPNAdapter (Public)

/**
 Return core copyright
 */
@property (class, nonnull, readonly, nonatomic) NSString *copyright;

/**
 Return platform description
 */
@property (class, nonnull, readonly, nonatomic) NSString *platform;

/**
 <#Description#>
 */
@property (weak, nonatomic, null_unspecified) id<OpenVPNAdapterDelegate> delegate;

/**
 Return information about the most recent connection. Will be available
 after an event of type "OpenVPNAdapterEventConnected, otherwise return nil.
 */
@property (nullable, readonly, nonatomic) OpenVPNConnectionInfo *connectionInfo;

/**
 Return current session token or nil if session token is unavailable
 */
@property (nullable, readonly, nonatomic) OpenVPNSessionToken *sessionToken;

/**
 Return transport stats
 */
@property (nonnull, readonly, nonatomic) OpenVPNTransportStats *transportStats;

/**
 Return tun stats
 */
@property (nonnull, readonly, nonatomic) OpenVPNInterfaceStats *interfaceStats;

/**
 <#Description#>

 @param configuration <#configuration description#>
 @param error <#error description#>
 @return <#return value description#>
 */
- (nullable OpenVPNProperties *)applyConfiguration:(nonnull OpenVPNConfiguration *)configuration
                     error:(out NSError * __nullable * __nullable)error
NS_SWIFT_NAME(apply(configuration:));

/**
 <#Description#>

 @param credentials <#credentials description#>
 @param error <#error description#>
 @return <#return value description#>
 */
- (BOOL)provideCredentials:(nonnull OpenVPNCredentials *)credentials
                     error:(out NSError * __nullable * __nullable)error
NS_SWIFT_NAME(provide(credentials:));

/**
 Establish connection with the VPN server
 */
- (void)connect;

/**
 Pause the client –- useful to avoid continuous reconnection attempts
 when network is down

 @param pauseReason <#reason description#>
 */
- (void)pauseWithReason:(nullable NSString *)pauseReason
NS_SWIFT_NAME(pause(reason:));

/**
 Resume the client after it has been paused
 */
- (void)resume;

/**
 Do a disconnect/reconnect cycle after given amount of seconds from now

 @param interval <#interval description#>
 */
- (void)reconnectAfterTimeInterval:(NSInteger)interval
NS_SWIFT_NAME(reconnect(interval:));

/**
 Close connection with the VPN server
 */
- (void)disconnect;

@end

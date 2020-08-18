//
//  OpenVPNAdapter.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OpenVPNAdapterEvent);

@class NEPacketTunnelFlow;
@class NEPacketTunnelNetworkSettings;

@protocol OpenVPNAdapterPacketFlow;

@class OpenVPNAdapter;
@class OpenVPNConfiguration;
@class OpenVPNConnectionInfo;
@class OpenVPNCredentials;
@class OpenVPNInterfaceStats;
@class OpenVPNConfigurationEvaluation;
@class OpenVPNTransportStats;
@class OpenVPNSessionToken;

@protocol OpenVPNAdapterDelegate <NSObject>

/**
 This method is called once the network settings to be used have been established.
 The receiver should call the completion handler once these settings have been set, returning a NEPacketTunnelFlow object for
 the TUN interface, or nil if an error occurred.
 
 @param openVPNAdapter The OpenVPNAdapter instance requesting this information.
 @param networkSettings The NEPacketTunnelNetworkSettings to be used for the tunnel. Provides nil to clear out the network settings.
 @param completionHandler The completion handler to be called with a NEPacketTunnelFlow object, or nil if an error occurred or the network settings were cleared out.
 */
- (void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter
configureTunnelWithNetworkSettings:(nullable NEPacketTunnelNetworkSettings *)networkSettings
                 completionHandler:(void (^)(NSError * _Nullable error))completionHandler
NS_SWIFT_NAME(openVPNAdapter(_:configureTunnelWithNetworkSettings:completionHandler:));

/**
 Informs the receiver that an OpenVPN error has occurred.
 Some errors are fatal and should trigger the diconnection of the tunnel, check for fatal errors with the
 OpenVPNAdapterErrorFatalKey.
 
 @param openVPNAdapter The OpenVPNAdapter instance which encountered the error.
 @param error The error which has occurred.
 */
- (void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter handleError:(NSError *)error;

/**
 Informs the receiver that an OpenVPN event has occurred.

 @param openVPNAdapter The OpenVPNAdapter instance which encountered the event.
 @param event The event which has occurred.
 @param message An accompanying message, may be nil.
 */
- (void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter
           handleEvent:(OpenVPNAdapterEvent)event
               message:(nullable NSString *)message 
NS_SWIFT_NAME(openVPNAdapter(_:handleEvent:message:));

@optional

/**
 Informs the receiver that an OpenVPN message has been logged.
 
 @param openVPNAdapter The OpenVPNAdapter instance which encountered the log message.
 @param logMessage The log message.
 */
- (void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter handleLogMessage:(NSString *)logMessage;

/**
 Informs the receiver that a clock tick has occurred.
 Clock ticks can be configured with an OpenVPNConfiguration object.
 
 @param openVPNAdapter The OpenVPNAdapter instance which encountered the clock tick.
 */
- (void)openVPNAdapterDidReceiveClockTick:(OpenVPNAdapter *)openVPNAdapter;

@end

@interface OpenVPNAdapter : NSObject

/**
 The OpenVPN core copyright message.
 */
@property (nonatomic, class, readonly) NSString *copyright;

/**
 The OpenVPN platform.
 */
@property (nonatomic, class, readonly) NSString *platform;

/**
 The object that acts as the delegate of the adapter.
 */
@property (nonatomic, weak) id<OpenVPNAdapterDelegate> delegate;

/**
 The session name, nil unless the tunnel is connected.
 */
@property (nonatomic, nullable, readonly) NSString *sessionName;

/**
 The connection information, nil unless the tunnel is connected.
 */
@property (nonatomic, nullable, readonly) OpenVPNConnectionInfo *connectionInformation;

/**
 The interface statistics.
 */
@property (nonatomic, readonly) OpenVPNInterfaceStats *interfaceStatistics;

/**
 The session token, nil unless the tunnel is connected.
 */
@property (nonatomic, nullable, readonly) OpenVPNSessionToken *sessionToken;

/**
 The transport statistics.
 */
@property (nonatomic, readonly) OpenVPNTransportStats *transportStatistics;

/**
 Evaluate the given configuration object and determine needed credentials.

 @param configuration The configuration object.
 @param error If there is an error applying the configuration, upon return contains an error object that describes the problem.
 @return An object describing the configuration which has been evaluated.
 */
+ (nullable OpenVPNConfigurationEvaluation *)evaluateConfiguration:(OpenVPNConfiguration *)configuration
                                                             error:(NSError **)error
NS_SWIFT_NAME(evaluate(configuration:));

/**
 Applies the given configuration object.
 Call this method prior to connecting, this method has no effect after calling connect.

 @param configuration The configuration object.
 @param error If there is an error applying the configuration, upon return contains an error object that describes the problem.
 @return An object describing the configuration which has been applied.
 */
- (nullable OpenVPNConfigurationEvaluation *)applyConfiguration:(OpenVPNConfiguration *)configuration
                                             error:(NSError **)error
NS_SWIFT_NAME(apply(configuration:));

/**
 Provides credentials to the receiver.

 @param credentials The credentials object.
 @param error If there is an error providing the credentials, upon return contains an error object that describes the problem.
 @return Returns YES if this method was successful, otherwise NO.
 */
- (BOOL)provideCredentials:(OpenVPNCredentials *)credentials error:(NSError **)error NS_SWIFT_NAME(provide(credentials:));

/**
 Starts the tunnel.
 
 @param packetFlow The object implementing OpenVPNAdapterPacketFlow protocol.
 */
- (void)connectUsingPacketFlow:(id<OpenVPNAdapterPacketFlow>)packetFlow NS_SWIFT_NAME(connect(using:));

/**
 Pauses the tunnel.

 @param reason The reason for pausing the tunnel.
 */
- (void)pauseWithReason:(NSString *)reason NS_SWIFT_NAME(pause(withReason:));

/**
 Resumes the connection.
 */
- (void)resume;

/**
 Reconnects after a given time period, perhaps due to an interface change.

 @param timeInterval The time interval to wait before reconnecting.
 */
- (void)reconnectAfterTimeInterval:(NSTimeInterval)timeInterval NS_SWIFT_NAME(reconnect(afterTimeInterval:));

/**
 Disconnect from the tunnel.
 */
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END

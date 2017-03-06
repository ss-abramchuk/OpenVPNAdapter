//
//  OpenVPNAdapter+Provider.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import "OpenVPNEvent.h"

#import "OpenVPNAdapter.h"

@class NEPacketTunnelFlow;
@class NEPacketTunnelNetworkSettings;


@protocol OpenVPNAdapterDelegate <NSObject>

- (void)configureTunnelWithSettings:(nonnull NEPacketTunnelNetworkSettings *)settings
                 callback:(nonnull void (^)(NEPacketTunnelFlow * __nullable flow))callback
NS_SWIFT_NAME(configureTunnel(settings:callback:));

- (void)handleEvent:(OpenVPNEvent)event
            message:(nullable NSString *)message
NS_SWIFT_NAME(handle(event:message:));

- (void)handleError:(nonnull NSError *)error
NS_SWIFT_NAME(handle(error:));

@end


@interface OpenVPNAdapter (Provider)

@property (strong, nonatomic, nullable) NSString *username;
@property (strong, nonatomic, nullable) NSString *password;

@property (weak, nonatomic, null_unspecified) id<OpenVPNAdapterDelegate> delegate;

- (BOOL)configureUsing:(nonnull NSData *)settings
            error:(out NSError * __nullable * __nullable)error
NS_SWIFT_NAME(configure(using:));

- (void)connect;
- (void)disconnect;

@end

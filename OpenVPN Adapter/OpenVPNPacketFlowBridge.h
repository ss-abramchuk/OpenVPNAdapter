//
//  OpenVPNPacketFlowBridge.h
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 12/10/2017.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPacketTunnelFlow;

@interface OpenVPNPacketFlowBridge : NSObject

@property (nonatomic, readonly) CFSocketNativeHandle socketHandle;

- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithPacketFlow:(NEPacketTunnelFlow *)packetFlow NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

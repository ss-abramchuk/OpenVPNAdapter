//
//  OpenVPNPacketFlowBridge.h
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 12/10/2017.
//  Modified by Sergey Abramchuk on 15/01/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OpenVPNAdapterPacketFlow;

@interface OpenVPNPacketFlowBridge: NSObject

@property (nonatomic, readonly) CFSocketRef openVPNSocket;
@property (nonatomic, readonly) CFSocketRef packetFlowSocket;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPacketFlow:(id<OpenVPNAdapterPacketFlow>)packetFlow NS_DESIGNATED_INITIALIZER;

- (BOOL)configureSocketsWithError:(NSError **)error;
- (void)startReading;

@end

NS_ASSUME_NONNULL_END

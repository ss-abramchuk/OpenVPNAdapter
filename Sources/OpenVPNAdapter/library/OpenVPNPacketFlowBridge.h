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

@property (nonatomic, weak) id<OpenVPNAdapterPacketFlow> packetFlow;

@property (nonatomic, readonly) int openVPNSocket;
@property (nonatomic, readonly) int packetFlowSocket;
@property (nonatomic, readonly) dispatch_source_t source;

- (BOOL)configureSocketsWithError:(NSError **)error;
- (void)invalidateSocketsIfNeeded;

- (void)startReading;

@end

NS_ASSUME_NONNULL_END

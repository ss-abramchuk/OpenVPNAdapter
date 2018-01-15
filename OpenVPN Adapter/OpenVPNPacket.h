//
//  OpenVPNPacket.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.01.2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNPacket : NSObject

/**
 Data that can be written to the VPN socket.
 */
@property (readonly, nonatomic) NSData *vpnData;

/**
 Data that can be written to the packet flow.
 */
@property (readonly, nonatomic) NSData *packetFlowData;

/**
 Protocol number (e.g. PF_INET or PF_INET6) of the packet.
 */
@property (readonly, nonatomic) NSNumber *protocolFamily;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVPNData:(NSData *)data NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPacketFlowData:(NSData *)data protocolFamily:(NSNumber *)protocolFamily NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

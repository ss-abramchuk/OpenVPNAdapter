//
//  OpenVPNAdapterPacketFlow.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.01.2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OpenVPNAdapterPacketFlow <NSObject>

/**
 Read IP packets from the TUN interface.
 
 @param completionHandler A block that is executed when some packets are read from the TUN interface. The packets that were
 read are passed to this block in the packets array. The protocol numbers of the packets that were read are passed to this
 block in the protocols array. Each packet has a protocol number in the corresponding index in the protocols array. The
 protocol numbers are given in host byte order. Valid protocol numbers include PF_INET and PF_INET6. See /usr/include/sys/socket.h.
 */
- (void)readPacketsWithCompletionHandler:(void (^)(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols))completionHandler;

/**
 Write IP packets to the TUN interface
 
 @param packets An array of NSData objects containing the IP packets to the written.
 @param protocols An array of NSNumber objects containing the protocol numbers (e.g. PF_INET or PF_INET6) of the IP packets
 in packets in host byte order.
 
 @discussion The number of NSData objects in packets must be exactly equal to the number of NSNumber objects in protocols.
 
 @return YES on success, otherwise NO.
 */
- (BOOL)writePackets:(NSArray<NSData *> *)packets withProtocols:(NSArray<NSNumber *> *)protocols;

@end

NS_ASSUME_NONNULL_END

//
//  OpenVPNTransportStats.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Class used to provide basic transport stats
 */
@interface OpenVPNTransportStats : NSObject <NSCopying, NSSecureCoding>

/**
 Amount of received bytes
 */
@property (readonly, nonatomic) NSInteger bytesIn;

/**
 Amout of sent bytes
 */
@property (readonly, nonatomic) NSInteger bytesOut;

/**
 Amount of received packets
 */
@property (readonly, nonatomic) NSInteger packetsIn;

/**
 Amount of sent packets
 */
@property (readonly, nonatomic) NSInteger packetsOut;

/**
 Date when last packet was received, or nil if undefined
 */
@property (readonly, nonatomic, nullable) NSDate *lastPacketReceived;

@end

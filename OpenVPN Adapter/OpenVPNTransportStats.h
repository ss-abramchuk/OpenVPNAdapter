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
@interface OpenVPNTransportStats : NSObject

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
 Amout of sent packets
 */
@property (readonly, nonatomic) NSInteger packetsOut;

/**
 Number of binary milliseconds (1/1024th of a second) since
 last packet was received, or -1 if undefined
 */
@property (readonly, nonatomic) NSInteger lastPacketReceived;

- (nonnull instancetype) __unavailable init;

@end

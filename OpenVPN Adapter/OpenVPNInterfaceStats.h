//
//  OpenVPNInterfaceStats.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Class used to provide stats for an interface
 */
@interface OpenVPNInterfaceStats : NSObject <NSCopying, NSSecureCoding>

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
 Amount of incoming packets handling errors
 */
@property (readonly, nonatomic) NSInteger errorsIn;

/**
 Amount of outgoing packets handling errors
 */
@property (readonly, nonatomic) NSInteger errorsOut;

@end

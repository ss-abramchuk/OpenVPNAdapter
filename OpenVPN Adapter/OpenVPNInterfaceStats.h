//
//  OpenVPNInterfaceStats.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

@interface OpenVPNInterfaceStats : NSObject

@property (readonly, nonatomic) NSInteger bytesIn;
@property (readonly, nonatomic) NSInteger bytesOut;
@property (readonly, nonatomic) NSInteger packetsIn;
@property (readonly, nonatomic) NSInteger packetsOut;
@property (readonly, nonatomic) NSInteger errorsIn;
@property (readonly, nonatomic) NSInteger errorsOut;

- (nonnull instancetype) __unavailable init;

@end

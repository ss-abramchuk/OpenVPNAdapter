//
//  OpenVPNPacket.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.01.2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNPacket : NSObject

@property (readonly, nonatomic) NSData *data;
@property (readonly, nonatomic) NSNumber *protocolFamily;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithData:(NSData *)data protocolFamily:(NSNumber *)protocolFamily NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

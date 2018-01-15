//
//  OpenVPNPacket.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.01.2018.
//

#import "OpenVPNPacket.h"

@implementation OpenVPNPacket

- (instancetype)initWithData:(NSData *)data protocolFamily:(NSNumber *)protocolFamily {
    if ((self = [super init])) {
        _data = data;
        _protocolFamily = protocolFamily;
    }
    return self;
}

@end

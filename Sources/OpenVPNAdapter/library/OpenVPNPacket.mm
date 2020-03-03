//
//  OpenVPNPacket.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.01.2018.
//

#import "OpenVPNPacket.h"

#include <arpa/inet.h>

#include <openvpn/ip/ipcommon.hpp>

@interface OpenVPNPacket () {
    NSData *_data;
    NSNumber *_protocolFamily;
}

@end

@implementation OpenVPNPacket

- (instancetype)initWithVPNData:(NSData *)data {
    if (self = [super init]) {
#if TARGET_OS_IPHONE
        // Get network protocol family from data prefix
        NSUInteger prefix_size = sizeof(uint32_t);
        
        uint32_t protocol = PF_UNSPEC;
        [data getBytes:&protocol length:prefix_size];
        protocol = CFSwapInt32BigToHost(protocol);
        
        NSRange range = NSMakeRange(prefix_size, data.length - prefix_size);
        NSData *packetData = [data subdataWithRange:range];
#else
        // Get network protocol family from packet header
        uint8_t header = 0;
        [data getBytes:&header length:1];
        
        uint32_t protocol = PF_UNSPEC;
        
        uint32_t version = openvpn::IPCommon::version(header);
        switch (version) {
            case 4:
                protocol = PF_INET;
                break;
            case 6:
                protocol = PF_INET6;
                break;
        }

        NSData *packetData = data;
#endif
        
        _data = packetData;
        _protocolFamily = @(protocol);
    }
    return self;
}

- (instancetype)initWithPacketFlowData:(NSData *)data protocolFamily:(NSNumber *)protocolFamily {
    if (self = [super init]) {
        _data = data;
        _protocolFamily = protocolFamily;
    }
    return self;
}

- (NSData *)vpnData {
#if TARGET_OS_IPHONE
    // Prepend data with network protocol. It should be done because OpenVPN on iOS uses uint32_t prefixes containing network
    // protocol.
    uint32_t prefix = CFSwapInt32HostToBig(_protocolFamily.unsignedIntegerValue);
    NSUInteger prefix_size = sizeof(uint32_t);
    
    NSMutableData *data = [NSMutableData dataWithCapacity:prefix_size + _data.length];
    
    [data appendBytes:&prefix length:prefix_size];
    [data appendData:_data];
    
    return data;
#else
    return _data;
#endif
}

- (NSData *)packetFlowData {
    return _data;
}

- (NSNumber *)protocolFamily {
    return _protocolFamily;
}

@end

//
//  OpenVPNTransportStats.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNTransportStats+Internal.h"

using namespace openvpn;

@implementation OpenVPNTransportStats

- (instancetype)initWithTransportStats:(ClientAPI::TransportStats)stats
{
    self = [super init];
    if (self) {
        _bytesIn = stats.bytesIn;
        _bytesOut = stats.bytesOut;
        _packetsIn = stats.packetsIn;
        _packetsOut = stats.packetsOut;
        _lastPacketReceived = stats.lastPacketReceived;
    }
    return self;
}

@end

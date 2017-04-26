//
//  OpenVPNInterfaceStats.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNInterfaceStats.h"
#import "OpenVPNInterfaceStats+Internal.h"

@implementation OpenVPNInterfaceStats

- (instancetype)initWithInterfaceStats:(ClientAPI::InterfaceStats)stats {
    self = [super init];
    if (self) {
        _bytesIn = stats.bytesIn;
        _bytesOut = stats.bytesOut;
        _packetsIn = stats.packetsIn;
        _packetsOut = stats.packetsOut;
        _errorsIn = stats.errorsIn;
        _errorsOut = stats.errorsOut;
    }
    return self;
}

@end

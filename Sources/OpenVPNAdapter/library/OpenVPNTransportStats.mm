//
//  OpenVPNTransportStats.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNTransportStats.h"
#import "OpenVPNTransportStats+Internal.h"

using namespace openvpn;

@interface OpenVPNTransportStats ()
@property (readwrite, nonatomic) NSInteger bytesIn;
@property (readwrite, nonatomic) NSInteger bytesOut;
@property (readwrite, nonatomic) NSInteger packetsIn;
@property (readwrite, nonatomic) NSInteger packetsOut;
@property (readwrite, nonatomic) NSDate *lastPacketReceived;
@end

@implementation OpenVPNTransportStats

- (instancetype)initWithTransportStats:(ClientAPI::TransportStats)stats {
    if (self = [self init]) {
        self.bytesIn = stats.bytesIn;
        self.bytesOut = stats.bytesOut;
        self.packetsIn = stats.packetsIn;
        self.packetsOut = stats.packetsOut;
        self.lastPacketReceived = stats.lastPacketReceived >= 0 ?
            [NSDate dateWithTimeIntervalSinceNow:stats.lastPacketReceived / -1024.0] : nil;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OpenVPNTransportStats *statistics = [[OpenVPNTransportStats allocWithZone:zone] init];
    statistics.bytesIn = self.bytesIn;
    statistics.bytesOut = self.bytesOut;
    statistics.packetsIn = self.packetsIn;
    statistics.packetsOut = self.packetsOut;
    statistics.lastPacketReceived = [self.lastPacketReceived copyWithZone:zone];
    return statistics;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.bytesIn forKey:NSStringFromSelector(@selector(bytesIn))];
    [aCoder encodeInteger:self.bytesOut forKey:NSStringFromSelector(@selector(bytesOut))];
    [aCoder encodeInteger:self.packetsIn forKey:NSStringFromSelector(@selector(packetsIn))];
    [aCoder encodeInteger:self.packetsOut forKey:NSStringFromSelector(@selector(packetsOut))];
    [aCoder encodeObject:self.lastPacketReceived forKey:NSStringFromSelector(@selector(lastPacketReceived))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.bytesIn = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(bytesIn))];
        self.bytesOut = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(bytesOut))];
        self.packetsIn = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(packetsIn))];
        self.packetsOut = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(packetsOut))];
        self.lastPacketReceived = [aDecoder decodeObjectOfClass:[NSDate class]
                                                         forKey:NSStringFromSelector(@selector(lastPacketReceived))];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

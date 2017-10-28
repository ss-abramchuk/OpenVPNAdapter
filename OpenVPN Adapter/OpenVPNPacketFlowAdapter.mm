//
//  OpenVPNPacketFlowAdapter.mm
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 12/10/2017.
//

#import <NetworkExtension/NetworkExtension.h>
#import <openvpn/ip/ip.hpp>
#import "OpenVPNPacketFlowAdapter.h"

@interface OpenVPNPacketFlowAdapter () {
    CFSocketRef _openVPNClientSocket;
    CFSocketRef _packetFlowSocket;
}
@property (nonatomic) NEPacketTunnelFlow *packetFlow;
@end

@implementation OpenVPNPacketFlowAdapter

- (instancetype)initWithPacketFlow:(NEPacketTunnelFlow *)packetFlow {
    if ((self = [super init])) {
        self.packetFlow = packetFlow;
        
        if (![self configureSockets]) {
            return nil;
        }
        
        [self readPacketFlowPackets];
    }
    return self;
}

- (CFSocketNativeHandle)socketHandle {
    return CFSocketGetNative(_openVPNClientSocket);
}

static inline void PacketFlowSocketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *adapter) {
    [(__bridge OpenVPNPacketFlowAdapter *)adapter writeDataToPacketFlow:(__bridge NSData *)data];
}

- (BOOL)configureSockets {
    int sockets[2];
    if (socketpair(PF_LOCAL, SOCK_DGRAM, IPPROTO_IP, sockets) == -1) {
        NSLog(@"Failed to create a pair of connected sockets: %@", [NSString stringWithUTF8String:strerror(errno)]);
        return NO;
    }
    
    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    _packetFlowSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[0], kCFSocketDataCallBack, PacketFlowSocketCallback, &socketCtxt);
    _openVPNClientSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1], kCFSocketNoCallBack, NULL, NULL);
    
    if (!(_packetFlowSocket && _openVPNClientSocket)) {
        NSLog(@"Failed to create core foundation sockets from native sockets");
        return NO;
    }
    
    if (!([self configureOptionsForSocket:_packetFlowSocket] && [self configureOptionsForSocket:_openVPNClientSocket])) {
        NSLog(@"Failed to configure buffer size of the sockets");
        return NO;
    }
    
    CFRunLoopSourceRef packetFlowSocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _packetFlowSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), packetFlowSocketSource, kCFRunLoopDefaultMode);
    CFRelease(packetFlowSocketSource);
    
    return YES;
}

- (BOOL)configureOptionsForSocket:(CFSocketRef)socket {
    CFSocketNativeHandle socketHandle = CFSocketGetNative(socket);
    
    int buf_value = 65536;
    socklen_t buf_len = sizeof(buf_value);
    
    if (setsockopt(socketHandle, SOL_SOCKET, SO_RCVBUF, &buf_value, buf_len) == -1) {
        NSLog(@"Failed to setup buffer size for input: %@", [NSString stringWithUTF8String:strerror(errno)]);
        return NO;
    }
    
    if (setsockopt(socketHandle, SOL_SOCKET, SO_SNDBUF, &buf_value, buf_len) == -1) {
        NSLog(@"Failed to setup buffer size for output: %@", [NSString stringWithUTF8String:strerror(errno)]);
        return NO;
    }
    
    CFOptionFlags sockopt = CFSocketGetSocketFlags(socket);
    
    sockopt |= kCFSocketCloseOnInvalidate | kCFSocketAutomaticallyReenableDataCallBack;
    CFSocketSetSocketFlags(socket, sockopt);
    
    return YES;
}

- (void)readPacketFlowPackets {
    __weak typeof(self) weakSelf = self;
    [self.packetFlow readPacketObjectsWithCompletionHandler:^(NSArray<NEPacket *> * _Nonnull packets) {
        typeof(self) strongSelf = weakSelf;
        [strongSelf writeVPNPacketObjects:packets];
        [strongSelf readPacketFlowPackets];
    }];
}

- (void)writeVPNPacketObjects:(NSArray<NEPacket *> *)packets {
    for (NEPacket *packet in packets) {
        CFSocketSendData(_packetFlowSocket, NULL, (CFDataRef)[self dataFromPacket:packet], 0.05);
    }
}

- (NSData *)dataFromPacket:(NEPacket *)packet {
#if TARGET_OS_IPHONE
    // Prepend data with network protocol. It should be done because OpenVPN on iOS uses uint32_t prefixes containing network protocol.
    uint32_t prefix = CFSwapInt32HostToBig((uint32_t)packet.protocolFamily);
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:sizeof(prefix) + packet.data.length];
    [data appendBytes:&prefix length:sizeof(prefix)];
    [data appendData:packet.data];
    return data;
#else
    return packet.data;
#endif
}

- (NEPacket *)packetFromData:(NSData *)data {
#if TARGET_OS_IPHONE
    // Get network protocol from prefix
    NSUInteger prefixSize = sizeof(uint32_t);
    
    if (data.length < prefixSize) {
        return nil;
    }
    
    uint32_t protocol = PF_UNSPEC;
    [data getBytes:&protocol length:prefixSize];
    protocol = CFSwapInt32BigToHost(protocol);
    
    NSRange range = NSMakeRange(prefixSize, data.length - prefixSize);
    NSData *packetData = [data subdataWithRange:range];
#else
    // Get network protocol from header
    uint8_t header = 0;
    [data getBytes:&header length:1];
    
    uint32_t version = openvpn::IPHeader::version(header);
    sa_family_t protocol = [self protocolFamilyForVersion:version];
    
    NSData *packetData = data;
#endif
    
    return [[NEPacket alloc] initWithData:packetData protocolFamily:protocol];
}

- (void)writeDataToPacketFlow:(NSData *)data {
    NEPacket *packet = [self packetFromData:data];
    
    if (!packet) {
        return;
    }
    
    [self.packetFlow writePacketObjects:@[packet]];
}

- (sa_family_t)protocolFamilyForVersion:(uint32_t)version {
    switch (version) {
        case 4: return PF_INET;
        case 6: return PF_INET6;
        default: return PF_UNSPEC;
    }
}

- (void)dealloc {
    CFSocketInvalidate(_openVPNClientSocket);
    CFRelease(_openVPNClientSocket);
    
    CFSocketInvalidate(_packetFlowSocket);
    CFRelease(_packetFlowSocket);
}

@end

//
//  OpenVPNPacketFlowAdapter.mm
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 12/10/2017.
//

#import "OpenVPNPacketFlowAdapter.h"
#import <NetworkExtension/NetworkExtension.h>
#import <openvpn/ip/ip.hpp>

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

static inline void PacketFlowSocketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    if (type == kCFSocketDataCallBack) {
        [(__bridge OpenVPNPacketFlowAdapter *)info writeDataToPacketFlow:(__bridge NSData *)data];
    }
}

- (BOOL)configureSockets {
    int sockets[2];
    if (socketpair(PF_LOCAL, SOCK_DGRAM, IPPROTO_IP, sockets) == -1) {
        NSLog(@"Failed to create a pair of connected sockets: %@", [NSString stringWithUTF8String:strerror(errno)]);
        return NO;
    }
    
    if (![self configureBufferSizeForSocket:sockets[0]] || ![self configureBufferSizeForSocket:sockets[1]]) {
        NSLog(@"Failed to configure buffer size of the sockets");
        return NO;
    }
    
    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    _packetFlowSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[0], kCFSocketDataCallBack, PacketFlowSocketCallback, &socketCtxt);
    _openVPNClientSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1], kCFSocketNoCallBack, NULL, NULL);
    
    if (!_packetFlowSocket || !_openVPNClientSocket) {
        NSLog(@"Failed to create core foundation sockets from native sockets");
        return NO;
    }
    
    CFRunLoopSourceRef packetFlowSocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _packetFlowSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), packetFlowSocketSource, kCFRunLoopDefaultMode);
    CFRelease(packetFlowSocketSource);
    
    return YES;
}

- (BOOL)configureBufferSizeForSocket:(int)socket {
    int buf_value = 65536;
    socklen_t buf_len = sizeof(buf_value);
    
    if (setsockopt(socket, SOL_SOCKET, SO_RCVBUF, &buf_value, buf_len) == -1) {
        NSLog(@"Failed to setup buffer size for input: %@", [NSString stringWithUTF8String:strerror(errno)]);
        return NO;
    }
    
    if (setsockopt(socket, SOL_SOCKET, SO_SNDBUF, &buf_value, buf_len) == -1) {
        NSLog(@"Failed to setup buffer size for output: %@", [NSString stringWithUTF8String:strerror(errno)]);
        return NO;
    }
    
    return YES;
}

- (void)readPacketFlowPackets {
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
        [self writeVPNPackets:packets protocols:protocols];
        [self readPacketFlowPackets];
    }];
}

- (void)writeVPNPackets:(NSArray<NSData *> *)packets protocols:(NSArray<NSNumber *> *)protocols {
    [packets enumerateObjectsUsingBlock:^(NSData *data, NSUInteger idx, BOOL *stop) {
        if (!_packetFlowSocket) {
            *stop = YES;
            return;
        }
        
        // Prepare data for sending
        NSData *packet = [self prepareVPNPacket:data protocol:protocols[idx]];
        
        // Send data to the VPN server
        CFSocketSendData(_packetFlowSocket, NULL, (CFDataRef)packet, 0.05);
    }];
}

- (NSData *)prepareVPNPacket:(NSData *)packet protocol:(NSNumber *)protocol {
    NSMutableData *data = [NSMutableData new];
    
#if TARGET_OS_IPHONE
    // Prepend data with network protocol. It should be done because OpenVPN on iOS uses uint32_t prefixes containing network protocol.
    uint32_t prefix = CFSwapInt32HostToBig((uint32_t)[protocol unsignedIntegerValue]);
    [data appendBytes:&prefix length:sizeof(prefix)];
#endif
    
    [data appendData:packet];
    
    return [data copy];
}

- (void)writeDataToPacketFlow:(NSData *)packet {
#if TARGET_OS_IPHONE
    // Get network protocol from prefix
    NSUInteger prefixSize = sizeof(uint32_t);
    
    if (packet.length < prefixSize) {
        NSLog(@"Incorrect OpenVPN packet size");
        return;
    }
    
    uint32_t protocol = PF_UNSPEC;
    [packet getBytes:&protocol length:prefixSize];
    protocol = CFSwapInt32BigToHost(protocol);
    
    NSRange range = NSMakeRange(prefixSize, packet.length - prefixSize);
    NSData *data = [packet subdataWithRange:range];
#else
    // Get network protocol from header
    uint8_t header = 0;
    [packet getBytes:&header length:1];
    
    uint32_t version = openvpn::IPHeader::version(header);
    uint8_t protocol = [self protocolFamilyForVersion:version];
    
    NSData *data = packet;
#endif
    
    // Send the packet to the TUN interface
    if (![self.packetFlow writePackets:@[data] withProtocols:@[@(protocol)]]) {
        NSLog(@"Failed to send OpenVPN packet to the TUN interface");
    }
}

- (uint8_t)protocolFamilyForVersion:(uint32_t)version {
    switch (version) {
        case 4: return PF_INET;
        case 6: return PF_INET6;
        default: return PF_UNSPEC;
    }
}

- (void)dealloc {
    if (_packetFlowSocket) {
        CFSocketInvalidate(_packetFlowSocket);
        CFRelease(_packetFlowSocket);
    }
    
    if (_openVPNClientSocket) {
        CFSocketInvalidate(_openVPNClientSocket);
        CFRelease(_openVPNClientSocket);
    }
}

@end

//
//  OpenVPNPacketFlowBridge.mm
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 12/10/2017.
//  Modified by Sergey Abramchuk on 15/01/2018.
//

#import "OpenVPNPacketFlowBridge.h"

#include <sys/socket.h>
#include <arpa/inet.h>

#import "OpenVPNError.h"
#import "OpenVPNPacket.h"
#import "OpenVPNAdapterPacketFlow.h"

@implementation OpenVPNPacketFlowBridge

#pragma mark - Sockets Configuration

static void SocketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *obj) {
    if (type != kCFSocketDataCallBack) { return; }
    
    OpenVPNPacket *packet = [[OpenVPNPacket alloc] initWithVPNData:(__bridge NSData *)data];
    
    OpenVPNPacketFlowBridge *bridge = (__bridge OpenVPNPacketFlowBridge *)obj;
    [bridge writePackets:@[packet] toPacketFlow:bridge.packetFlow];
}

- (BOOL)configureSocketsWithError:(NSError * __autoreleasing *)error {
    int sockets[2];
    if (socketpair(PF_LOCAL, SOCK_DGRAM, IPPROTO_IP, sockets) == -1) {
        if (error) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: @"Failed to create a pair of connected sockets.",
                NSLocalizedFailureReasonErrorKey: [NSString stringWithUTF8String:strerror(errno)],
                OpenVPNAdapterErrorFatalKey: @(YES)
            };
            
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                         code:OpenVPNAdapterErrorSocketSetupFailed
                                     userInfo:userInfo];
        }
        
        return NO;
    }
    
    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    _packetFlowSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[0], kCFSocketDataCallBack,
                                                 SocketCallback, &socketCtxt);
    _openVPNSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1], kCFSocketNoCallBack, NULL, NULL);
    
    if (!(_packetFlowSocket && _openVPNSocket)) {
        if (error) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: @"Failed to create core foundation sockets from native sockets.",
                OpenVPNAdapterErrorFatalKey: @(YES)
            };
            
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                         code:OpenVPNAdapterErrorSocketSetupFailed
                                     userInfo:userInfo];
        }

        return NO;
    }
    
    if (!([self configureOptionsForSocket:_packetFlowSocket error:error] &&
          [self configureOptionsForSocket:_openVPNSocket error:error])) { return NO; }
    
    CFRunLoopSourceRef packetFlowSocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _packetFlowSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), packetFlowSocketSource, kCFRunLoopDefaultMode);
    CFRelease(packetFlowSocketSource);
    
    return YES;
}

- (BOOL)configureOptionsForSocket:(CFSocketRef)socket error:(NSError * __autoreleasing *)error {
    CFSocketNativeHandle socketHandle = CFSocketGetNative(socket);
    
    int buf_value = 65536;
    socklen_t buf_len = sizeof(buf_value);
    
    if (setsockopt(socketHandle, SOL_SOCKET, SO_RCVBUF, &buf_value, buf_len) == -1) {
        if (error) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: @"Failed to setup buffer size for input.",
                NSLocalizedFailureReasonErrorKey: [NSString stringWithUTF8String:strerror(errno)],
                OpenVPNAdapterErrorFatalKey: @(YES)
            };
            
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                         code:OpenVPNAdapterErrorSocketSetupFailed
                                     userInfo:userInfo];
        }
        
        return NO;
    }
    
    if (setsockopt(socketHandle, SOL_SOCKET, SO_SNDBUF, &buf_value, buf_len) == -1) {
        if (error) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: @"Failed to setup buffer size for output.",
                NSLocalizedFailureReasonErrorKey: [NSString stringWithUTF8String:strerror(errno)],
                OpenVPNAdapterErrorFatalKey: @(YES)
            };
            
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                         code:OpenVPNAdapterErrorSocketSetupFailed
                                     userInfo:userInfo];
        }
        
        return NO;
    }
    
    return YES;
}

- (void)invalidateSocketsIfNeeded {
    if (_openVPNSocket) {
        CFSocketInvalidate(_openVPNSocket);
        CFRelease(_openVPNSocket);
        
        _openVPNSocket = NULL;
    }
    
    if (_packetFlowSocket) {
        CFSocketInvalidate(_packetFlowSocket);
        CFRelease(_packetFlowSocket);
        
        _packetFlowSocket = NULL;
    }
}

- (void)startReading {
    NSAssert(self.packetFlow != nil, @"packetFlow property shouldn't be nil, set it before start reading packets.");
    
    __weak typeof(self) weakSelf = self;
    
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
        __strong typeof(self) self = weakSelf;
        
        [self writePackets:packets protocols:protocols toSocket:self.packetFlowSocket];
        [self startReading];
    }];
}

#pragma mark - TUN -> VPN

- (void)writePackets:(NSArray<NSData *> *)packets protocols:(NSArray<NSNumber *> *)protocols toSocket:(CFSocketRef)socket {
    if (socket == NULL) { return; }
    
    [packets enumerateObjectsUsingBlock:^(NSData *data, NSUInteger idx, BOOL *stop) {
        NSNumber *protocolFamily = protocols[idx];
        OpenVPNPacket *packet = [[OpenVPNPacket alloc] initWithPacketFlowData:data protocolFamily:protocolFamily];
        
        CFSocketSendData(socket, NULL, (CFDataRef)packet.vpnData, 0.05);
    }];
}

#pragma mark - VPN -> TUN

- (void)writePackets:(NSArray<OpenVPNPacket *> *)packets toPacketFlow:(id<OpenVPNAdapterPacketFlow>)packetFlow {
    NSAssert(packetFlow != nil, @"packetFlow shouldn't be nil, check provided parameter before start writing packets.");
    
    NSMutableArray<NSData *> *flowPackets = [[NSMutableArray alloc] init];
    NSMutableArray<NSNumber *> *protocols = [[NSMutableArray alloc] init];
    
    [packets enumerateObjectsUsingBlock:^(OpenVPNPacket * _Nonnull packet, NSUInteger idx, BOOL * _Nonnull stop) {
        [flowPackets addObject:packet.packetFlowData];
        [protocols addObject:packet.protocolFamily];
    }];
    
    [packetFlow writePackets:flowPackets withProtocols:protocols];
}

#pragma mark -

- (void)dealloc {
    [self invalidateSocketsIfNeeded];
}

@end

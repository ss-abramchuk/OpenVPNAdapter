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

static void SocketCallback(NSData *data, OpenVPNPacketFlowBridge *obj) {
    OpenVPNPacket *packet = [[OpenVPNPacket alloc] initWithVPNData:data];
    
    OpenVPNPacketFlowBridge *bridge = obj;
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
    
    _packetFlowSocket = sockets[0];
    _openVPNSocket = sockets[1];
    
    int flags = fcntl(_packetFlowSocket, F_GETFL);
    bool success = fcntl(_packetFlowSocket, F_SETFL, flags | O_NONBLOCK) >= 0;
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, _packetFlowSocket, 0, DISPATCH_QUEUE_SERIAL);
    dispatch_source_set_event_handler(_source, ^{
        unsigned long bytesAvail = dispatch_source_get_data(_source);
        static char buffer[1024*500];    // 500 KB buffer
        unsigned long actual = read(_packetFlowSocket, buffer, sizeof(buffer));
        NSData* someData = [NSData dataWithBytes:(const void *)buffer length:sizeof(unsigned char)*actual];
        SocketCallback(someData, self);
    });
    dispatch_source_set_cancel_handler(_source, ^{
        close(_packetFlowSocket);
    });
    
    if (!(flags != 0 && success && _source)) {
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
    
    dispatch_activate(_source);
    
    return YES;
}

- (BOOL)configureOptionsForSocket:(int)socket error:(NSError * __autoreleasing *)error {
    CFSocketNativeHandle socketHandle = socket;
    
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
        close(_openVPNSocket);
        _openVPNSocket = NULL;
    }
    
    if (_packetFlowSocket) {
        dispatch_source_cancel(_source);
        _packetFlowSocket = NULL;
        _source = NULL;
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

- (void)writePackets:(NSArray<NSData *> *)packets protocols:(NSArray<NSNumber *> *)protocols toSocket:(int)socket {
    [packets enumerateObjectsUsingBlock:^(NSData *data, NSUInteger idx, BOOL *stop) {
        NSNumber *protocolFamily = protocols[idx];
        OpenVPNPacket *packet = [[OpenVPNPacket alloc] initWithPacketFlowData:data protocolFamily:protocolFamily];

        char buffer[1024*500];
        [packet.vpnData getBytes:buffer length:packet.vpnData.length];
        write(socket, buffer, packet.vpnData.length);
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

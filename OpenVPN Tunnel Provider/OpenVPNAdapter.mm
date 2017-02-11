//
//  OpenVPNAdapter.m
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <sys/socket.h>
#import <sys/un.h>
#import <sys/stat.h>
#import <sys/ioctl.h>
#import <arpa/inet.h>

#import <NetworkExtension/NetworkExtension.h>

#import "OpenVPNClient.h"

#import "OpenVPNAdapter.h"
#import "OpenVPNAdapter+Client.h"
#import "OpenVPNAdapter+Provider.h"


@interface OpenVPNAdapter ()

@property OpenVPNClient *vpnClient;

@property CFSocketRef tunSocket;
@property CFSocketRef vpnSocket;

@property (weak, nonatomic) NEPacketTunnelFlow *packetFlow;

@end


@implementation OpenVPNAdapter (Client)

#pragma mark Sockets Configuration

static void socketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    OpenVPNAdapter *adapter = (__bridge OpenVPNAdapter *)info;
    
    switch (type) {
        case kCFSocketDataCallBack:
            // TODO: Handle received data and send it to the tun interface
            break;
            
        default:
            break;
    }
}

- (BOOL)configureSockets {
    int sockets[2];
    if (socketpair(PF_LOCAL, SOCK_DGRAM, IPPROTO_IP, sockets) == -1) {
        NSLog(@"Failed to create a pair of connected sockets: %@", [NSString stringWithUTF8String:strerror(errno)]);
        return NO;
    }
    
    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    self.tunSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[0], kCFSocketDataCallBack, &socketCallback, &socketCtxt);
    self.vpnSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1], kCFSocketNoCallBack, NULL, NULL);
    
    if (!self.tunSocket || !self.vpnSocket) {
        NSLog(@"Failed to create core foundation sockets from native sockets");
        return NO;
    }
    
    CFRunLoopSourceRef tunSocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.tunSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), tunSocketSource, kCFRunLoopCommonModes);
    
    CFRelease(tunSocketSource);
    
    return YES;
}

@end

@implementation OpenVPNAdapter (Provider)

@end

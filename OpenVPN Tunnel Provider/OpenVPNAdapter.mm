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

#import "OpenVPNError.h"
#import "OpenVPNEvent.h"
#import "OpenVPNClient.h"

#import "OpenVPNAdapter.h"
#import "OpenVPNAdapter+Client.h"
#import "OpenVPNAdapter+Provider.h"

NSString *const OpenVPNClientErrorDomain = @"OpenVPNClientErrorDomain";
NSString *const OpenVPNClientErrorFatalKey = @"OpenVPNClientErrorFatalKey";


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

#pragma mark Event and Log Handlers

- (void)handleEvent:(const ClientAPI::Event *)event {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    NSString *eventName = [NSString stringWithUTF8String:event->name.c_str()];
    OpenVPNEvent eventIdentifier = [self getOpenVPNEventByName:eventName];
    
    NSString *eventMessage = [NSString stringWithUTF8String:event->info.c_str()];
    
    if (event->error) {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setObject:[NSNumber numberWithBool:event->fatal] forKey:OpenVPNClientErrorFatalKey];
        
        if (eventMessage != nil && ![eventMessage isEqualToString:@""]) {
            [userInfo setObject:eventMessage forKey:NSLocalizedDescriptionKey];
        }
        
        NSError *error = [NSError errorWithDomain:OpenVPNClientErrorDomain
                                             code:eventIdentifier
                                         userInfo:[userInfo copy]];
        
        [self.delegate handleError:error];
    } else {
        [self.delegate handleEvent:eventIdentifier message:eventMessage == nil || [eventMessage isEqualToString:@""] ? nil : eventMessage];
    }
}

- (void)handleLog:(const ClientAPI::LogInfo *)log {
    NSString *message = [NSString stringWithCString:log->text.c_str() encoding:NSUTF8StringEncoding];
    NSLog(@"%@", message);
}

- (OpenVPNEvent)getOpenVPNEventByName:(NSString *)eventName {
    NSDictionary *events = @{
        @"DISCONNECTED": @(OpenVPNEventDisconnected),
        @"CONNECTED": @(OpenVPNEventConnected),
        @"RECONNECTING": @(OpenVPNEventReconnecting),
        @"RESOLVE": @(OpenVPNEventResolve),
        @"WAIT": @(OpenVPNEventWait),
        @"WAIT_PROXY": @(OpenVPNEventWaitProxy),
        @"CONNECTING": @(OpenVPNEventConnecting),
        @"GET_CONFIG": @(OpenVPNEventGetConfig),
        @"ASSIGN_IP": @(OpenVPNEventAssignIP),
        @"ADD_ROUTES": @(OpenVPNEventAddRoutes),
        @"ECHO": @(OpenVPNEventEcho),
        @"INFO": @(OpenVPNEventInfo),
        @"PAUSE": @(OpenVPNEventPause),
        @"RESUME": @(OpenVPNEventResume),
        @"TRANSPORT_ERROR": @(OpenVPNEventTransportError),
        @"TUN_ERROR": @(OpenVPNEventTunError),
        @"CLIENT_RESTART": @(OpenVPNEventClientRestart),
        @"AUTH_FAILED": @(OpenVPNEventAuthFailed),
        @"CERT_VERIFY_FAIL": @(OpenVPNEventCertVerifyFail),
        @"TLS_VERSION_MIN": @(OpenVPNEventTLSVersionMin),
        @"CLIENT_HALT": @(OpenVPNEventClientHalt),
        @"CONNECTION_TIMEOUT": @(OpenVPNEventConnectionTimeout),
        @"INACTIVE_TIMEOUT": @(OpenVPNEventInactiveTimeout),
        @"DYNAMIC_CHALLENGE": @(OpenVPNEventDynamicChallenge),
        @"PROXY_NEED_CREDS": @(OpenVPNEventProxyNeedCreds),
        @"PROXY_ERROR": @(OpenVPNEventProxyError),
        @"TUN_SETUP_FAILED": @(OpenVPNEventTunSetupFailed),
        @"TUN_IFACE_CREATE": @(OpenVPNEventTunIfaceCreate),
        @"TUN_IFACE_DISABLED": @(OpenVPNEventTunIfaceDisabled),
        @"EPKI_ERROR": @(OpenVPNEventEPKIError),
        @"EPKI_INVALID_ALIAS": @(OpenVPNEventEPKIInvalidAlias),
    };
    
    OpenVPNEvent event = events[eventName] != nil ? (OpenVPNEvent)[(NSNumber *)events[eventName] unsignedIntegerValue] : OpenVPNEventUnknown;
    return event;
}

@end

@implementation OpenVPNAdapter (Provider)

@end

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
#import "TUNConfiguration.h"

#import "OpenVPNAdapter.h"
#import "OpenVPNAdapter+Client.h"
#import "OpenVPNAdapter+Provider.h"

NSString * const OpenVPNClientErrorDomain = @"OpenVPNClientErrorDomain";

NSString * const OpenVPNClientErrorFatalKey = @"OpenVPNClientErrorFatalKey";
NSString * const OpenVPNClientErrorEventKey = @"OpenVPNClientErrorEventKey";


@interface OpenVPNAdapter ()

@property OpenVPNClient *vpnClient;

@property (strong, nonatomic) TUNConfiguration *tunConfiguration;

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

#pragma mark TUN Configuration

- (BOOL)setRemoteAddress:(NSString *)address {
    NSAssert(self.tunConfiguration != nil, @"TUN configuration should be initialized");
    
    if (address == nil) {
        return NO;
    }
    
    self.tunConfiguration.remoteAddress = address;
    
    return YES;
}

- (BOOL)addLocalAddress:(NSString *)address subnet:(NSString *)subnet gateway:(NSString *)gateway {
    NSAssert(self.tunConfiguration != nil, @"TUN configuration should be initialized");
    
    if (address == nil || subnet == nil) {
        return NO;
    }
    
    [self.tunConfiguration.localAddresses addObject:address];
    [self.tunConfiguration.subnets addObject:subnet];
    
    return YES;
}

- (BOOL)addRoute:(NSString *)route subnet:(NSString *)subnet {
    NSAssert(self.tunConfiguration != nil, @"TUN configuration should be initialized");
    
    if (route == nil || subnet == nil) {
        return NO;
    }
    
    NEIPv4Route *includedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnet];
    [self.tunConfiguration.includedRoutes addObject:includedRoute];
    
    return YES;
}

- (BOOL)excludeRoute:(NSString *)route subnet:(NSString *)subnet {
    NSAssert(self.tunConfiguration != nil, @"TUN configuration should be initialized");
    
    if (route == nil || subnet == nil) {
        return NO;
    }
    
    NEIPv4Route *excludedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnet];
    [self.tunConfiguration.excludedRoutes addObject:excludedRoute];
    
    return YES;
}

- (BOOL)addDNSAddress:(NSString *)address {
    NSAssert(self.tunConfiguration != nil, @"TUN configuration should be initialized");
    
    if (address == nil) {
        return NO;
    }
    
    [self.tunConfiguration.dnsAddresses addObject:address];
    
    return YES;
}

- (BOOL)addSearchDomain:(NSString *)domain {
    NSAssert(self.tunConfiguration != nil, @"TUN configuration should be initialized");
    
    if (domain == nil) {
        return NO;
    }
    
    [self.tunConfiguration.searchDomains addObject:domain];
    
    return YES;
}

- (BOOL)setMTU:(NSInteger)mtu {
    NSAssert(self.tunConfiguration != nil, @"TUN configuration should be initialized");
    
    self.tunConfiguration.mtu = @(mtu);
    
    return YES;
}

#pragma mark Event and Log Handlers

- (void)handleEvent:(const ClientAPI::Event *)event {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    NSString *eventName = [NSString stringWithUTF8String:event->name.c_str()];
    OpenVPNEvent eventIdentifier = [self getEventIdentifierByName:eventName];
    
    NSString *eventMessage = [NSString stringWithUTF8String:event->info.c_str()];
    
    if (event->error) {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setObject:@(event->fatal) forKey:OpenVPNClientErrorFatalKey];
        [userInfo setObject:@(eventIdentifier) forKey:OpenVPNClientErrorEventKey];
        
        if (eventMessage != nil && ![eventMessage isEqualToString:@""]) {
            [userInfo setObject:eventMessage forKey:NSLocalizedDescriptionKey];
        }
        
        NSError *error = [NSError errorWithDomain:OpenVPNClientErrorDomain
                                             code:OpenVPNErrorClientFailure
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

- (OpenVPNEvent)getEventIdentifierByName:(NSString *)eventName {
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

#pragma mark Client Configuration

- (BOOL)configureWithUsername:(NSString *)username password:(NSString *)password configuration:(NSData *)configuration error:(out NSError * __autoreleasing _Nullable *)error {
    NSString *vpnConfiguration = [[NSString alloc] initWithData:configuration encoding:NSUTF8StringEncoding];
    
    if (vpnConfiguration == nil) {
        if (error) *error = [NSError errorWithDomain:OpenVPNClientErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            // TODO: Write error message
            NSLocalizedDescriptionKey: @"Failed to ..."
        }];
        return NO;
    }
    
    ClientAPI::Config clientConfiguration;
    clientConfiguration.content = std::string([vpnConfiguration UTF8String]);
    clientConfiguration.connTimeout = 30;
    
    self.vpnClient = new OpenVPNClient((__bridge void *)self);
    
    ClientAPI::EvalConfig eval = self.vpnClient->eval_config(clientConfiguration);
    if (eval.error) {
        if (error) *error = [NSError errorWithDomain:OpenVPNClientErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithUTF8String:eval.message.c_str()]
        }];
        return NO;
    }
    
    ClientAPI::ProvideCreds creds;
    creds.username = [username UTF8String];
    creds.password = [password UTF8String];
    
    ClientAPI::Status creds_status = self.vpnClient->provide_creds(creds);
    if (creds_status.error) {
        if (error) *error = [NSError errorWithDomain:OpenVPNClientErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithUTF8String:creds_status.message.c_str()]
        }];
        return NO;
    }
    
    return YES;
}

#pragma mark Connection Control

- (void)connect {
    // TODO: Describe why we use async invocation here
    dispatch_queue_t connectQueue = dispatch_queue_create("me.ss-abramchuk.openvpn-ios-client.tunnel-provider.connection", NULL);
    dispatch_async(connectQueue, ^{
        self.tunConfiguration = [TUNConfiguration new];
        OpenVPNClient::init_process();
        
        try {
            ClientAPI::Status status = self.vpnClient->connect();
            if (status.error) {
                NSError *error = [NSError errorWithDomain:OpenVPNClientErrorDomain
                                                     code:OpenVPNErrorClientFailure
                                                 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:status.message.c_str()],
                                                             OpenVPNClientErrorFatalKey: @(YES),
                                                             OpenVPNClientErrorEventKey: @(OpenVPNEventConnectionFailed) }];
                [self.delegate handleError:error];
            }
        } catch(const std::exception& e) {
            NSError *error = [NSError errorWithDomain:OpenVPNClientErrorDomain
                                                 code:OpenVPNErrorClientFailure
                                             userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:e.what()],
                                                         OpenVPNClientErrorFatalKey: @(YES),
                                                         OpenVPNClientErrorEventKey: @(OpenVPNEventConnectionFailed) }];
            [self.delegate handleError:error];
        }
        
        OpenVPNClient::uninit_process();
        self.tunConfiguration = nil;
    });
}

- (void)disconnect {
    self.vpnClient->stop();
}

@end

@implementation OpenVPNAdapter

- (void)dealloc {
    delete self.vpnClient;
    
    CFSocketInvalidate(self.tunSocket);
    CFSocketInvalidate(self.vpnSocket);
    
    CFRelease(self.tunSocket);
    CFRelease(self.vpnSocket);
}

@end

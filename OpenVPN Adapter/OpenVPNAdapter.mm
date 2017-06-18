//
//  OpenVPNAdapter.m
//  OpenVPN Adapter
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

#import <openvpn/addr/ipv4.hpp>

#import "OpenVPNTunnelSettings.h"
#import "OpenVPNClient.h"
#import "OpenVPNError.h"
#import "OpenVPNEvent.h"
#import "OpenVPNConfiguration+Internal.h"
#import "OpenVPNCredentials+Internal.h"
#import "OpenVPNProperties+Internal.h"
#import "OpenVPNConnectionInfo+Internal.h"
#import "OpenVPNSessionToken+Internal.h"
#import "OpenVPNTransportStats+Internal.h"
#import "OpenVPNInterfaceStats+Internal.h"
#import "OpenVPNAdapter.h"
#import "OpenVPNAdapter+Internal.h"
#import "OpenVPNAdapter+Public.h"

@interface OpenVPNAdapter () {
    __weak id<OpenVPNAdapterDelegate> _delegate;
}

@property OpenVPNClient *vpnClient;

@property CFSocketRef vpnSocket;
@property CFSocketRef tunSocket;

@property (strong, nonatomic) NSString *remoteAddress;

@property (strong, nonatomic) NSString *defaultGatewayIPv6;
@property (strong, nonatomic) NSString *defaultGatewayIPv4;

@property (strong, nonatomic) OpenVPNTunnelSettings *tunnelSettingsIPv6;
@property (strong, nonatomic) OpenVPNTunnelSettings *tunnelSettingsIPv4;

@property (strong, nonatomic) NSMutableArray *searchDomains;

@property (strong, nonatomic) NSNumber *mtu;

@property (weak, nonatomic) id<OpenVPNAdapterPacketFlow> packetFlow;

- (void)readTUNPackets;
- (void)readVPNData:(NSData *)data;
- (OpenVPNEvent)getEventIdentifierByName:(NSString *)eventName;
- (NSString *)getDescriptionForErrorEvent:(OpenVPNEvent)event;
- (NSString *)getSubnetFromPrefixLength:(NSNumber *)prefixLength;
- (void)performAsyncBlock:(void (^)())block;

@end

@implementation OpenVPNAdapter (Internal)

#pragma mark Sockets Configuration

static void socketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    OpenVPNAdapter *adapter = (__bridge OpenVPNAdapter *)info;
    
    switch (type) {
        case kCFSocketDataCallBack:
            [adapter readVPNData:(__bridge NSData *)data];
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
    
    if (![self configureBufferSizeForSocket: sockets[0]] || ![self configureBufferSizeForSocket: sockets[1]]) {
        NSLog(@"Failed to configure buffer size of the sockets");
        return NO;
    }
    
    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    self.vpnSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[0], kCFSocketDataCallBack, &socketCallback, &socketCtxt);
    self.tunSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1], kCFSocketNoCallBack, NULL, NULL);
    
    if (!self.vpnSocket || !self.tunSocket) {
        NSLog(@"Failed to create core foundation sockets from native sockets");
        return NO;
    }
    
    CFRunLoopSourceRef tunSocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.vpnSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), tunSocketSource, kCFRunLoopDefaultMode);
    
    CFRelease(tunSocketSource);
    
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

#pragma mark TUN Configuration

- (BOOL)setRemoteAddress:(NSString *)address isIPv6:(BOOL)isIPv6 {
    if (address == nil) {
        return NO;
    }
    
    self.remoteAddress = address;
    
    return YES;
}

- (BOOL)addLocalAddress:(NSString *)address prefixLength:(NSNumber *)prefixLength gateway:(NSString *)gateway isIPv6:(BOOL)isIPv6 {
    if (address == nil || prefixLength == nil) {
        return NO;
    }
    
    NSString *defaultGateway = [gateway length] == 0 || [gateway isEqualToString:@"UNSPEC"] ? nil : gateway;
    
    if (isIPv6) {
        if (!self.tunnelSettingsIPv6.initialized) {
            self.tunnelSettingsIPv6.initialized = YES;
        }
        
        self.defaultGatewayIPv6 = defaultGateway;
        
        [self.tunnelSettingsIPv6.localAddresses addObject:address];
        [self.tunnelSettingsIPv6.prefixLengths addObject:prefixLength];
    } else {
        if (!self.tunnelSettingsIPv4.initialized) {
            self.tunnelSettingsIPv4.initialized = YES;
        }
        
        self.defaultGatewayIPv4 = defaultGateway;
        
        [self.tunnelSettingsIPv4.localAddresses addObject:address];
        [self.tunnelSettingsIPv4.prefixLengths addObject:prefixLength];
    }
    
    return YES;
}

- (BOOL)defaultGatewayRerouteIPv4:(BOOL)rerouteIPv4 rerouteIPv6:(BOOL)rerouteIPv6 {
    if (rerouteIPv6) {
        NEIPv6Route *includedRoute = [NEIPv6Route defaultRoute];
        includedRoute.gatewayAddress = self.defaultGatewayIPv6;
        
        [self.tunnelSettingsIPv6.includedRoutes addObject:includedRoute];
    }
    
    if (rerouteIPv4) {
        NEIPv4Route *includedRoute = [NEIPv4Route defaultRoute];
        includedRoute.gatewayAddress = self.defaultGatewayIPv4;
        
        [self.tunnelSettingsIPv4.includedRoutes addObject:includedRoute];
    }
    
    return YES;
}

- (BOOL)addRoute:(NSString *)route prefixLength:(NSNumber *)prefixLength isIPv6:(BOOL)isIPv6 {
    if (route == nil || prefixLength == nil) {
        return NO;
    }
    
    if (isIPv6) {
        NEIPv6Route *includedRoute = [[NEIPv6Route alloc] initWithDestinationAddress:route networkPrefixLength:prefixLength];
        includedRoute.gatewayAddress = self.defaultGatewayIPv6;
        
        [self.tunnelSettingsIPv6.includedRoutes addObject:includedRoute];
    } else {
        NSString *subnet = [self getSubnetFromPrefixLength:prefixLength];
        
        NEIPv4Route *includedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnet];
        includedRoute.gatewayAddress = self.defaultGatewayIPv4;
        
        [self.tunnelSettingsIPv4.includedRoutes addObject:includedRoute];
    }
    
    return YES;
}

- (BOOL)excludeRoute:(NSString *)route prefixLength:(NSNumber *)prefixLength isIPv6:(BOOL)isIPv6 {
    if (route == nil || prefixLength == nil) {
        return NO;
    }
    
    if (isIPv6) {
        NEIPv6Route *excludedRoute = [[NEIPv6Route alloc] initWithDestinationAddress:route networkPrefixLength:prefixLength];
        [self.tunnelSettingsIPv6.excludedRoutes addObject:excludedRoute];
    } else {
        NSString *subnet = [self getSubnetFromPrefixLength:prefixLength];
        NEIPv4Route *excludedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnet];
        [self.tunnelSettingsIPv4.excludedRoutes addObject:excludedRoute];
    }
    
    return YES;
}

- (BOOL)addDNSAddress:(NSString *)address isIPv6:(BOOL)isIPv6 {
    if (address == nil) {
        return NO;
    }
    
    if (isIPv6) {
        [self.tunnelSettingsIPv6.dnsAddresses addObject:address];
    } else {
        [self.tunnelSettingsIPv4.dnsAddresses addObject:address];
    }
    
    return YES;
}

- (BOOL)addSearchDomain:(NSString *)domain {
    if (domain == nil) {
        return NO;
    }
    
    [self.searchDomains addObject:domain];
    
    return YES;
}

- (BOOL)setMTU:(NSNumber *)mtu {
    self.mtu = mtu;
    return YES;
}

- (NSInteger)establishTunnel {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:self.remoteAddress];
    
    // Configure IPv6 addresses and routes
    if (self.tunnelSettingsIPv6.initialized) {
        NEIPv6Settings *settingsIPv6 = [[NEIPv6Settings alloc] initWithAddresses:self.tunnelSettingsIPv6.localAddresses networkPrefixLengths:self.tunnelSettingsIPv6.prefixLengths];
        settingsIPv6.includedRoutes = self.tunnelSettingsIPv6.includedRoutes;
        settingsIPv6.excludedRoutes = self.tunnelSettingsIPv6.excludedRoutes;
        
        networkSettings.IPv6Settings = settingsIPv6;
    }
    
    // Configure IPv4 addresses and routes
    if (self.tunnelSettingsIPv4.initialized) {
        NSMutableArray *subnets = [NSMutableArray new];
        [self.tunnelSettingsIPv4.prefixLengths enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *subnet = [self getSubnetFromPrefixLength:obj];
            [subnets addObject:subnet];
        }];
        
        NEIPv4Settings *ipSettings = [[NEIPv4Settings alloc] initWithAddresses:self.tunnelSettingsIPv4.localAddresses subnetMasks:subnets];
        ipSettings.includedRoutes = self.tunnelSettingsIPv4.includedRoutes;
        ipSettings.excludedRoutes = self.tunnelSettingsIPv4.excludedRoutes;
        
        networkSettings.IPv4Settings = ipSettings;
    }
    
    // Configure DNS addresses and search domains
    NSMutableArray *dnsAddresses = [NSMutableArray new];
    
    if (self.tunnelSettingsIPv6.dnsAddresses.count > 0) {
        [dnsAddresses addObjectsFromArray:self.tunnelSettingsIPv6.dnsAddresses];
    }
    
    if (self.tunnelSettingsIPv4.dnsAddresses.count > 0) {
        [dnsAddresses addObjectsFromArray:self.tunnelSettingsIPv4.dnsAddresses];
    }
    
    if (dnsAddresses.count > 0) {
        networkSettings.DNSSettings = [[NEDNSSettings alloc] initWithServers:dnsAddresses];
    }
    
    if (networkSettings.DNSSettings && self.searchDomains.count > 0) {
        networkSettings.DNSSettings.searchDomains = self.searchDomains;
    }
    
    // Set MTU
    networkSettings.MTU = self.mtu;
    
    // Establish TUN interface
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    [self performAsyncBlock:^{
        [self.delegate configureTunnelWithSettings:networkSettings callback:^(id<OpenVPNAdapterPacketFlow> _Nullable flow) {
            self.packetFlow = flow;
            dispatch_semaphore_signal(sema);
        }];
    }];
    
    // Wait 10 seconds
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
    if (dispatch_semaphore_wait(sema, timeout) != 0) {
        NSLog(@"Failed to establish tunnel in a reasonable time");
        return -1;
    }
    
    if (self.packetFlow) {
        [self readTUNPackets];
        return CFSocketGetNative(self.tunSocket);
    } else {
        return -1;
    }
}

#pragma mark Event and Log Handlers

- (void)handleEvent:(const ClientAPI::Event *)event {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    NSString *eventName = [NSString stringWithUTF8String:event->name.c_str()];
    OpenVPNEvent eventIdentifier = [self getEventIdentifierByName:eventName];
    
    NSString *eventMessage = [NSString stringWithUTF8String:event->info.c_str()];
    
    if (event->error) {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setObject:@(event->fatal) forKey:OpenVPNAdapterErrorFatalKey];
        [userInfo setObject:@(eventIdentifier) forKey:OpenVPNAdapterErrorEventIdentifierKey];
        
        NSString *eventDescription = [self getDescriptionForErrorEvent:eventIdentifier];
        if (eventDescription) {
            [userInfo setObject:eventDescription forKey:NSLocalizedFailureReasonErrorKey];
        }
        
        if (eventMessage != nil && ![eventMessage isEqualToString:@""]) {
            [userInfo setObject:eventMessage forKey:NSLocalizedDescriptionKey];
        }
        
        NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                             code:OpenVPNErrorClientFailure
                                         userInfo:[userInfo copy]];
        
        [self performAsyncBlock:^{
            [self.delegate handleError:error];
        }];
    } else {
        [self performAsyncBlock:^{
            [self.delegate handleEvent:eventIdentifier message:eventMessage == nil || [eventMessage isEqualToString:@""] ? nil : eventMessage];
        }];
    }
}

- (void)handleLog:(const ClientAPI::LogInfo *)log {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    if ([self.delegate respondsToSelector:@selector(handleLog:)]) {
        NSString *message = [NSString stringWithCString:log->text.c_str() encoding:NSUTF8StringEncoding];
        [self performAsyncBlock:^{
            [self.delegate handleLog:message];
        }];
    }
}

#pragma mark Clock Tick

- (void)tick {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    if ([self.delegate respondsToSelector:@selector(tick)]) {
        [self performAsyncBlock:^{
            [self.delegate tick];
        }];
    }
}

@end

@implementation OpenVPNAdapter (Public)

#pragma mark Properties

+ (NSString *)copyright {
    std::string copyright = OpenVPNClient::copyright();
    return [NSString stringWithUTF8String:copyright.c_str()];
}

+ (NSString *)platform {
    std::string platform = OpenVPNClient::platform();
    return [NSString stringWithUTF8String:platform.c_str()];
}

- (void)setDelegate:(id<OpenVPNAdapterDelegate>)delegate {
    _delegate = delegate;
}

- (id<OpenVPNAdapterDelegate>)delegate {
    return _delegate;
}

- (OpenVPNConnectionInfo *)connectionInfo {
    ClientAPI::ConnectionInfo info = self.vpnClient->connection_info();
    return info.defined ? [[OpenVPNConnectionInfo alloc] initWithConnectionInfo:info] : nil;
}

- (OpenVPNSessionToken *)sessionToken {
    ClientAPI::SessionToken token;
    bool gotToken = self.vpnClient->session_token(token);
    
    return gotToken ? [[OpenVPNSessionToken alloc] initWithSessionToken:token] : nil;
}

- (OpenVPNTransportStats *)transportStats {
    ClientAPI::TransportStats stats = self.vpnClient->transport_stats();
    return [[OpenVPNTransportStats alloc] initWithTransportStats:stats];
}

- (OpenVPNInterfaceStats *)interfaceStats {
    ClientAPI::InterfaceStats stats = self.vpnClient->tun_stats();
    return [[OpenVPNInterfaceStats alloc] initWithInterfaceStats:stats];
}

#pragma mark Client Configuration

- (OpenVPNProperties *)applyConfiguration:(nonnull OpenVPNConfiguration *)configuration error:(out NSError * __nullable * __nullable)error {
    ClientAPI::EvalConfig eval = self.vpnClient->eval_config(configuration.config);
    if (eval.error) {
        if (error) *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithUTF8String:eval.message.c_str()]
        }];
        return nil;
    }
    
    return [[OpenVPNProperties alloc] initWithEvalConfig:eval];
}

- (BOOL)provideCredentials:(nonnull OpenVPNCredentials *)credentials error:(out NSError * __nullable * __nullable)error {
    ClientAPI::Status creds_status = self.vpnClient->provide_creds(credentials.credentials);
    if (creds_status.error) {
        if (error) *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithUTF8String:creds_status.message.c_str()]
        }];
        return NO;
    }
    
    return YES;
}

#pragma mark Connection Control

- (void)connect {
    dispatch_queue_t connectQueue = dispatch_queue_create("me.ss-abramchuk.openvpn-adapter.connection", NULL);
    dispatch_async(connectQueue, ^{
        OpenVPNClient::init_process();
        
        self.tunnelSettingsIPv6 = [OpenVPNTunnelSettings new];
        self.tunnelSettingsIPv4 = [OpenVPNTunnelSettings new];
        
        self.searchDomains = [NSMutableArray new];
        
        try {
            ClientAPI::Status status = self.vpnClient->connect();
            if (status.error) {
                NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                                     code:OpenVPNErrorClientFailure
                                                 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:status.message.c_str()],
                                                             OpenVPNAdapterErrorFatalKey: @(YES),
                                                             OpenVPNAdapterErrorEventIdentifierKey: @(OpenVPNEventConnectionFailed) }];
                [self performAsyncBlock:^{
                    [self.delegate handleError:error];
                }];
            }
        } catch(const std::exception& e) {
            NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                                 code:OpenVPNErrorClientFailure
                                             userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:e.what()],
                                                         OpenVPNAdapterErrorFatalKey: @(YES),
                                                         OpenVPNAdapterErrorEventIdentifierKey: @(OpenVPNEventConnectionFailed) }];
            [self performAsyncBlock:^{
                [self.delegate handleError:error];
            }];
        }
        
        self.remoteAddress = nil;
        
        self.tunnelSettingsIPv6 = nil;
        self.tunnelSettingsIPv4 = nil;
        
        self.searchDomains = nil;
        
        self.mtu = nil;
        
        if (self.vpnSocket) {
            CFSocketInvalidate(self.vpnSocket);
            CFRelease(self.vpnSocket);
        }
        
        if (self.tunSocket) {
            CFSocketInvalidate(self.tunSocket);
            CFRelease(self.tunSocket);
        }
        
        OpenVPNClient::uninit_process();
    });
}

- (void)pauseWithReason:(NSString *)pauseReason {
    std::string reason = pauseReason ? std::string([pauseReason UTF8String]) : "";
    self.vpnClient->pause(reason);
}

- (void)resume {
    self.vpnClient->resume();
}

- (void)reconnectAfterTimeInterval:(NSInteger)interval {
    self.vpnClient->reconnect(interval);
}

- (void)disconnect {
    self.vpnClient->stop();
}

@end

@implementation OpenVPNAdapter

#pragma mark Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        _delegate = nil;
        self.vpnClient = new OpenVPNClient((__bridge void *)self);
    }
    return self;
}

#pragma mark TUN -> OpenVPN

- (void)readTUNPackets {
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
        [packets enumerateObjectsUsingBlock:^(NSData * data, NSUInteger idx, BOOL * stop) {
            // Prepend data with network protocol. It should be done because OpenVPN uses uint32_t prefixes containing network protocol.
            NSNumber *protocol = protocols[idx];
            uint32_t prefix = CFSwapInt32HostToBig((uint32_t)[protocol unsignedIntegerValue]);
            
            NSMutableData *packet = [NSMutableData new];
            [packet appendBytes:&prefix length:sizeof(prefix)];
            [packet appendData:data];
            
            // Send data to the VPN server
            CFSocketSendData(self.vpnSocket, NULL, (CFDataRef)packet, 0.05);
        }];
        
        [self readTUNPackets];
    }];
}

#pragma mark OpenVPN -> TUN

- (void)readVPNData:(NSData *)data {
    // Get network protocol from data
    NSUInteger prefixSize = sizeof(uint32_t);
    
    if (data.length < prefixSize) {
        NSLog(@"Incorrect OpenVPN packet size");
        return;
    }
    
    uint32_t protocol = UINT32_MAX;
    [data getBytes:&protocol length:prefixSize];
    
    protocol = CFSwapInt32BigToHost(protocol);
    
    // Send the packet to the TUN interface
    NSData *packet = [data subdataWithRange:NSMakeRange(prefixSize, data.length - prefixSize)];
    if (![self.packetFlow writePackets:@[packet] withProtocols:@[@(protocol)]]) {
        NSLog(@"Failed to send OpenVPN packet to the TUN interface");
    }
}

#pragma mark Utils

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
        @"RELAY": @(OpenVPNEventRelay),
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
        @"RELAY_ERROR": @(OpenVPNEventRelayError)
    };
    
    OpenVPNEvent event = events[eventName] != nil ? (OpenVPNEvent)[(NSNumber *)events[eventName] unsignedIntegerValue] : OpenVPNEventUnknown;
    return event;
}

- (NSString *)getDescriptionForErrorEvent:(OpenVPNEvent)event {
    switch (event) {
        case OpenVPNEventTransportError: return @"General transport error.";
        case OpenVPNEventTunError: return @"General tun error.";
        case OpenVPNEventClientRestart: return @"RESTART message from server received.";
        case OpenVPNEventAuthFailed: return @"General authentication failure.";
        case OpenVPNEventCertVerifyFail: return @"Peer certificate verification failure.";
        case OpenVPNEventTLSVersionMin: return @"Peer cannot handshake at our minimum required TLS version.";
        case OpenVPNEventClientHalt: return @"HALT message from server received.";
        case OpenVPNEventConnectionTimeout: return @"Connection failed to establish within given time.";
        case OpenVPNEventInactiveTimeout: return @"Disconnected due to inactive timer.";
        case OpenVPNEventProxyNeedCreds: return @"HTTP proxy needs credentials.";
        case OpenVPNEventProxyError: return @"HTTP proxy error.";
        case OpenVPNEventTunSetupFailed: return @"Error setting up TUN interface.";
        case OpenVPNEventTunIfaceCreate: return @"Error creating TUN interface.";
        case OpenVPNEventTunIfaceDisabled: return @"TUN interface is disabled.";
        case OpenVPNEventRelayError: return @"RELAY error.";
            
        default: return nil;
    }
}

- (NSString *)getSubnetFromPrefixLength:(NSNumber *)prefixLength {
    std::string subnet = openvpn::IPv4::Addr::netmask_from_prefix_len([prefixLength intValue]).to_string();
    return [NSString stringWithUTF8String:subnet.c_str()];
}

- (void)performAsyncBlock:(void (^)())block {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, block);
}

#pragma mark Deallocation

- (void)dealloc {
    delete self.vpnClient;
}

@end

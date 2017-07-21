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

#import <openvpn/ip/ip.hpp>
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

@property (assign, nonatomic) OpenVPNClient *vpnClient;

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
- (void)readVPNPacket:(NSData *)packet;
- (OpenVPNEvent)eventByName:(NSString *)eventName;
- (OpenVPNError)errorByName:(NSString *)errorName;
- (NSString *)reasonForError:(OpenVPNError)error;
- (NSString *)subnetFromPrefixLength:(NSNumber *)prefixLength;
- (void)performAsyncBlock:(void (^)())block;

@end

@implementation OpenVPNAdapter (Internal)

#pragma mark Sockets Configuration

static void socketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    OpenVPNAdapter *adapter = (__bridge OpenVPNAdapter *)info;
    
    switch (type) {
        case kCFSocketDataCallBack:
            [adapter readVPNPacket:(__bridge NSData *)data];
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
        NSString *subnet = [self subnetFromPrefixLength:prefixLength];
        
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
        NSString *subnet = [self subnetFromPrefixLength:prefixLength];
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
            NSString *subnet = [self subnetFromPrefixLength:obj];
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
    
    NSString *name = [NSString stringWithUTF8String:event->name.c_str()];
    NSString *message = [NSString stringWithUTF8String:event->info.c_str()];
    
    if (event->error) {
        OpenVPNError errorCode = [self errorByName:name];
        NSString *errorReason = [self reasonForError:errorCode];
        
        NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                             code:errorCode
                                         userInfo:@{ NSLocalizedDescriptionKey: @"OpenVPN error occured.",
                                                     NSLocalizedFailureReasonErrorKey: errorReason,
                                                     OpenVPNAdapterErrorMessageKey: message != nil ? message : @"",
                                                     OpenVPNAdapterErrorFatalKey: @(event->fatal) }];
        
        [self performAsyncBlock:^{
            [self.delegate handleError:error];
        }];
    } else {
        OpenVPNEvent eventIdentifier = [self eventByName:name];
        [self performAsyncBlock:^{
            [self.delegate handleEvent:eventIdentifier message:message == nil || [message isEqualToString:@""] ? nil : message];
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
        NSString *errorReason = [self reasonForError:OpenVPNErrorConfigurationFailure];
        
        if (error) *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: @"Failed to apply OpenVPN configuration.",
            NSLocalizedFailureReasonErrorKey: errorReason,
            OpenVPNAdapterErrorMessageKey: [NSString stringWithUTF8String:eval.message.c_str()],
            OpenVPNAdapterErrorFatalKey: @(YES)
        }];
        return nil;
    }
    
    return [[OpenVPNProperties alloc] initWithEvalConfig:eval];
}

- (BOOL)provideCredentials:(nonnull OpenVPNCredentials *)credentials error:(out NSError * __nullable * __nullable)error {
    ClientAPI::Status status = self.vpnClient->provide_creds(credentials.credentials);
    if (status.error) {
        if (error) {
            OpenVPNError errorCode = !status.status.empty() ? [self errorByName:[NSString stringWithUTF8String:status.status.c_str()]] : OpenVPNErrorCredentialsFailure;
            NSString *errorReason = [self reasonForError:errorCode];
            
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:errorCode userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to provide OpenVPN credentials.",
                NSLocalizedFailureReasonErrorKey: errorReason,
                OpenVPNAdapterErrorMessageKey: [NSString stringWithUTF8String:status.message.c_str()],
                OpenVPNAdapterErrorFatalKey: @(YES)
            }];
        }
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
        
        ClientAPI::Status status = self.vpnClient->connect();
        if (status.error) {
            OpenVPNError errorCode = !status.status.empty() ? [self errorByName:[NSString stringWithUTF8String:status.status.c_str()]] : OpenVPNErrorUnknown;
            NSString *errorReason = [self reasonForError:errorCode];
            
            NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                                 code:errorCode
                                             userInfo:@{ NSLocalizedDescriptionKey: @"Failed to establish connection with OpenVPN server.",
                                                         NSLocalizedFailureReasonErrorKey: errorReason,
                                                         OpenVPNAdapterErrorMessageKey: [NSString stringWithUTF8String:status.message.c_str()],
                                                         OpenVPNAdapterErrorFatalKey: @(YES) }];
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
        [self writeVPNPackets:packets protocols:protocols];
        [self readTUNPackets];
    }];
}

- (void)writeVPNPackets:(NSArray<NSData *> *)packets protocols:(NSArray<NSNumber *> *)protocols {
    [packets enumerateObjectsUsingBlock:^(NSData * data, NSUInteger idx, BOOL * stop) {
        // Prepare data for sending
        NSData *packet = [self prepareVPNPacket:data protocol:protocols[idx]];
        
        // Send data to the VPN server
        CFSocketSendData(self.vpnSocket, NULL, (CFDataRef)packet, 0.05);
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

#pragma mark OpenVPN -> TUN

- (void)readVPNPacket:(NSData *)packet {
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

#pragma mark Utils

- (OpenVPNEvent)eventByName:(NSString *)eventName {
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
        @"RELAY": @(OpenVPNEventRelay)
    };
    
    OpenVPNEvent event = events[eventName] != nil ? (OpenVPNEvent)[events[eventName] integerValue] : OpenVPNEventUnknown;
    return event;
}

- (OpenVPNError)errorByName:(NSString *)errorName {
    NSDictionary *errors = @{
        @"NETWORK_RECV_ERROR": @(OpenVPNErrorNetworkRecvError),
        @"NETWORK_EOF_ERROR": @(OpenVPNErrorNetworkEOFError),
        @"NETWORK_SEND_ERROR": @(OpenVPNErrorNetworkSendError),
        @"NETWORK_UNAVAILABLE": @(OpenVPNErrorNetworkUnavailable),
        @"DECRYPT_ERROR": @(OpenVPNErrorDecryptError),
        @"HMAC_ERROR": @(OpenVPNErrorDecryptError),
        @"REPLAY_ERROR": @(OpenVPNErrorReplayError),
        @"BUFFER_ERROR": @(OpenVPNErrorBufferError),
        @"CC_ERROR": @(OpenVPNErrorCCError),
        @"BAD_SRC_ADDR": @(OpenVPNErrorBadSrcAddr),
        @"COMPRESS_ERROR": @(OpenVPNErrorCompressError),
        @"RESOLVE_ERROR": @(OpenVPNErrorResolveError),
        @"SOCKET_PROTECT_ERROR": @(OpenVPNErrorSocketProtectError),
        @"TUN_READ_ERROR": @(OpenVPNErrorTUNReadError),
        @"TUN_WRITE_ERROR": @(OpenVPNErrorTUNWriteError),
        @"TUN_FRAMING_ERROR": @(OpenVPNErrorTUNFramingError),
        @"TUN_SETUP_FAILED": @(OpenVPNErrorTUNSetupFailed),
        @"TUN_IFACE_CREATE": @(OpenVPNErrorTUNIfaceCreate),
        @"TUN_IFACE_DISABLED": @(OpenVPNErrorTUNIfaceDisabled),
        @"TUN_ERROR": @(OpenVPNErrorTUNError),
        @"TAP_NOT_SUPPORTED": @(OpenVPNErrorTAPNotSupported),
        @"REROUTE_GW_NO_DNS": @(OpenVPNErrorRerouteGatewayNoDns),
        @"TRANSPORT_ERROR": @(OpenVPNErrorTransportError),
        @"TCP_OVERFLOW": @(OpenVPNErrorTCPOverflow),
        @"TCP_SIZE_ERROR": @(OpenVPNErrorTCPSizeError),
        @"TCP_CONNECT_ERROR": @(OpenVPNErrorTCPConnectError),
        @"UDP_CONNECT_ERROR": @(OpenVPNErrorUDPConnectError),
        @"SSL_ERROR": @(OpenVPNErrorSSLError),
        @"SSL_PARTIAL_WRITE": @(OpenVPNErrorSSLPartialWrite),
        @"ENCAPSULATION_ERROR": @(OpenVPNErrorEncapsulationError),
        @"EPKI_CERT_ERROR": @(OpenVPNErrorEPKICertError),
        @"EPKI_SIGN_ERROR": @(OpenVPNErrorEPKISignError),
        @"HANDSHAKE_TIMEOUT": @(OpenVPNErrorHandshakeTimeout),
        @"KEEPALIVE_TIMEOUT": @(OpenVPNErrorKeepaliveTimeout),
        @"INACTIVE_TIMEOUT": @(OpenVPNErrorInactiveTimeout),
        @"CONNECTION_TIMEOUT": @(OpenVPNErrorConnectionTimeout),
        @"PRIMARY_EXPIRE": @(OpenVPNErrorPrimaryExpire),
        @"TLS_VERSION_MIN": @(OpenVPNErrorTLSVersionMin),
        @"TLS_AUTH_FAIL": @(OpenVPNErrorTLSAuthFail),
        @"CERT_VERIFY_FAIL": @(OpenVPNErrorCertVerifyFail),
        @"PEM_PASSWORD_FAIL": @(OpenVPNErrorPEMPasswordFail),
        @"AUTH_FAILED": @(OpenVPNErrorAuthFailed),
        @"CLIENT_HALT": @(OpenVPNErrorClientHalt),
        @"CLIENT_RESTART": @(OpenVPNErrorClientRestart),
        @"RELAY": @(OpenVPNErrorRelay),
        @"RELAY_ERROR": @(OpenVPNErrorRelayError),
        @"N_PAUSE": @(OpenVPNErrorPauseNumber),
        @"N_RECONNECT": @(OpenVPNErrorReconnectNumber),
        @"N_KEY_LIMIT_RENEG": @(OpenVPNErrorKeyLimitRenegNumber),
        @"KEY_STATE_ERROR": @(OpenVPNErrorKeyStateError),
        @"PROXY_ERROR": @(OpenVPNErrorProxyError),
        @"PROXY_NEED_CREDS": @(OpenVPNErrorProxyNeedCreds),
        @"KEV_NEGOTIATE_ERROR": @(OpenVPNErrorKevNegotiateError),
        @"KEV_PENDING_ERROR": @(OpenVPNErrorKevPendingError),
        @"N_KEV_EXPIRE": @(OpenVPNErrorKevExpireNumber),
        @"PKTID_INVALID": @(OpenVPNErrorPKTIDInvalid),
        @"PKTID_BACKTRACK": @(OpenVPNErrorPKTIDBacktrack),
        @"PKTID_EXPIRE": @(OpenVPNErrorPKTIDExpire),
        @"PKTID_REPLAY": @(OpenVPNErrorPKTIDReplay),
        @"PKTID_TIME_BACKTRACK": @(OpenVPNErrorPKTIDTimeBacktrack),
        @"DYNAMIC_CHALLENGE": @(OpenVPNErrorDynamicChallenge),
        @"EPKI_ERROR": @(OpenVPNErrorEPKIError),
        @"EPKI_INVALID_ALIAS": @(OpenVPNErrorEPKIInvalidAlias),
    };
    
    OpenVPNError error = errors[errorName] != nil ? (OpenVPNError)[errors[errorName] integerValue] : OpenVPNErrorUnknown;
    return error;
}

- (NSString *)reasonForError:(OpenVPNError)error {
    // TODO: Add missing error reasons
    switch (error) {
        case OpenVPNErrorConfigurationFailure: return @"See OpenVPN error message for more details.";
        case OpenVPNErrorCredentialsFailure: return @"See OpenVPN error message for more details.";
        case OpenVPNErrorNetworkRecvError: return @"Errors receiving on network socket.";
        case OpenVPNErrorNetworkEOFError: return @"EOF received on TCP network socket.";
        case OpenVPNErrorNetworkSendError: return @"Errors sending on network socket";
        case OpenVPNErrorNetworkUnavailable: return @"Network unavailable.";
        case OpenVPNErrorDecryptError: return @"Data channel encrypt/decrypt error.";
        case OpenVPNErrorHMACError: return @"HMAC verification failure.";
        case OpenVPNErrorReplayError: return @"Error from PacketIDReceive.";
        case OpenVPNErrorBufferError: return @"Exception thrown in Buffer methods.";
        case OpenVPNErrorCCError: return @"General control channel errors.";
        case OpenVPNErrorBadSrcAddr: return @"Packet from unknown source address.";
        case OpenVPNErrorCompressError: return @"Compress/Decompress errors on data channel.";
        case OpenVPNErrorResolveError: return @"DNS resolution error.";
        case OpenVPNErrorSocketProtectError: return @"Error calling protect() method on socket.";
        case OpenVPNErrorTUNReadError: return @"Read errors on TUN/TAP interface.";
        case OpenVPNErrorTUNWriteError: return @"Write errors on TUN/TAP interface.";
        case OpenVPNErrorTUNFramingError: return @"Error with tun PF_INET/PF_INET6 prefix.";
        case OpenVPNErrorTUNSetupFailed: return @"Error setting up TUN/TAP interface.";
        case OpenVPNErrorTUNIfaceCreate: return @"Error creating TUN/TAP interface.";
        case OpenVPNErrorTUNIfaceDisabled: return @"TUN/TAP interface is disabled.";
        case OpenVPNErrorTUNError: return @"General tun error.";
        case OpenVPNErrorTAPNotSupported: return @"Dev TAP is present in profile but not supported.";
        case OpenVPNErrorRerouteGatewayNoDns: return @"redirect-gateway specified without alt DNS servers.";
        case OpenVPNErrorTransportError: return @"General transport error";
        case OpenVPNErrorTCPOverflow: return @"TCP output queue overflow.";
        case OpenVPNErrorTCPSizeError: return @"Bad embedded uint16_t TCP packet size.";
        case OpenVPNErrorTCPConnectError: return @"Client error on TCP connect.";
        case OpenVPNErrorUDPConnectError: return @"Client error on UDP connect.";
        case OpenVPNErrorSSLError: return @"Errors resulting from read/write on SSL object.";
        case OpenVPNErrorSSLPartialWrite: return @"SSL object did not process all written cleartext.";
        case OpenVPNErrorEncapsulationError: return @"Exceptions thrown during packet encapsulation.";
        case OpenVPNErrorEPKICertError: return @"Error obtaining certificate from External PKI provider.";
        case OpenVPNErrorEPKISignError: return @"Error obtaining RSA signature from External PKI provider.";
        case OpenVPNErrorHandshakeTimeout: return @"Handshake failed to complete within given time frame.";
        case OpenVPNErrorKeepaliveTimeout: return @"Lost contact with peer.";
        case OpenVPNErrorInactiveTimeout: return @"Disconnected due to inactive timer.";
        case OpenVPNErrorConnectionTimeout: return @"Connection failed to establish within given time.";
        case OpenVPNErrorPrimaryExpire: return @"Primary key context expired.";
        case OpenVPNErrorTLSVersionMin: return @"Peer cannot handshake at our minimum required TLS version.";
        case OpenVPNErrorTLSAuthFail: return @"tls-auth HMAC verification failed.";
        case OpenVPNErrorCertVerifyFail: return @"Peer certificate verification failure.";
        case OpenVPNErrorPEMPasswordFail: return @"Incorrect or missing PEM private key decryption password.";
        case OpenVPNErrorAuthFailed: return @"General authentication failure";
        case OpenVPNErrorClientHalt: return @"HALT message from server received.";
        case OpenVPNErrorClientRestart: return @"RESTART message from server received.";
        case OpenVPNErrorRelay: return @"RELAY message from server received.";
        case OpenVPNErrorRelayError: return @"RELAY error.";
        case OpenVPNErrorPauseNumber: return @"";
        case OpenVPNErrorReconnectNumber: return @"";
        case OpenVPNErrorKeyLimitRenegNumber: return @"";
        case OpenVPNErrorKeyStateError: return @"Received packet didn't match expected key state.";
        case OpenVPNErrorProxyError: return @"HTTP proxy error.";
        case OpenVPNErrorProxyNeedCreds: return @"HTTP proxy needs credentials.";
        case OpenVPNErrorKevNegotiateError: return @"";
        case OpenVPNErrorKevPendingError: return @"";
        case OpenVPNErrorKevExpireNumber: return @"";
        case OpenVPNErrorPKTIDInvalid: return @"";
        case OpenVPNErrorPKTIDBacktrack: return @"";
        case OpenVPNErrorPKTIDExpire: return @"";
        case OpenVPNErrorPKTIDReplay: return @"";
        case OpenVPNErrorPKTIDTimeBacktrack: return @"";
        case OpenVPNErrorDynamicChallenge: return @"";
        case OpenVPNErrorEPKIError: return @"";
        case OpenVPNErrorEPKIInvalidAlias: return @"";
        case OpenVPNErrorUnknown: return @"Unknown error.";
    }
}

- (NSString *)subnetFromPrefixLength:(NSNumber *)prefixLength {
    std::string subnet = openvpn::IPv4::Addr::netmask_from_prefix_len([prefixLength intValue]).to_string();
    return [NSString stringWithUTF8String:subnet.c_str()];
}

- (uint8_t)protocolFamilyForVersion:(uint32_t)version {
    switch (version) {
        case 4: return PF_INET;
        case 6: return PF_INET6;
        default: return PF_UNSPEC;
    }
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

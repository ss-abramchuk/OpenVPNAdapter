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
#import "OpenVPNAdapterEvent.h"
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
    CFSocketRef _tunSocket;
    CFSocketRef _vpnSocket;
    __weak id<OpenVPNAdapterDelegate> _delegate;
}

@property (assign, nonatomic) OpenVPNClient *vpnClient;

@property (strong, nonatomic) NSString *remoteAddress;

@property (strong, nonatomic) NSString *defaultGatewayIPv6;
@property (strong, nonatomic) NSString *defaultGatewayIPv4;

@property (strong, nonatomic) OpenVPNTunnelSettings *tunnelSettingsIPv6;
@property (strong, nonatomic) OpenVPNTunnelSettings *tunnelSettingsIPv4;

@property (strong, nonatomic) NSMutableArray *searchDomains;

@property (strong, nonatomic) NSNumber *mtu;

@property (weak, nonatomic) id<OpenVPNAdapterPacketFlow> packetFlow;

@end

@implementation OpenVPNAdapter

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
    
    _vpnSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[0], kCFSocketDataCallBack, &socketCallback, &socketCtxt);
    _tunSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1], kCFSocketNoCallBack, NULL, NULL);
    
    if (!_vpnSocket || !_tunSocket) {
        NSLog(@"Failed to create core foundation sockets from native sockets");
        return NO;
    }
    
    CFRunLoopSourceRef tunSocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _vpnSocket, 0);
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

- (CFSocketNativeHandle)establishTunnel {
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
        return CFSocketGetNative(_tunSocket);
    } else {
        return -1;
    }
}

- (void)teardownTunnel:(BOOL)disconnect {
    [self resetTunnelSettings];
    
    if (_vpnSocket) {
        CFSocketInvalidate(_vpnSocket);
        CFRelease(_vpnSocket);
        _vpnSocket = nil;
    }
    
    if (_tunSocket) {
        CFSocketInvalidate(_tunSocket);
        CFRelease(_tunSocket);
        _tunSocket = nil;
    }
}

- (void)resetTunnelSettings {
    self.remoteAddress = nil;
    self.defaultGatewayIPv6 = nil;
    self.defaultGatewayIPv4 = nil;
    self.tunnelSettingsIPv6 = [[OpenVPNTunnelSettings alloc] init];
    self.tunnelSettingsIPv4 = [[OpenVPNTunnelSettings alloc] init];
    self.searchDomains = [[NSMutableArray alloc] init];
    self.mtu = nil;
}

#pragma mark Event and Log Handlers

- (void)handleEvent:(const ClientAPI::Event *)event {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    NSString *name = [NSString stringWithUTF8String:event->name.c_str()];
    NSString *message = [NSString stringWithUTF8String:event->info.c_str()];
    
    if (event->error) {
        OpenVPNAdapterError errorCode = [self errorByName:name];
        NSString *errorReason = [self reasonForError:errorCode];
        
        NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                             code:errorCode
                                         userInfo:@{ NSLocalizedDescriptionKey: @"OpenVPN error occurred.",
                                                     NSLocalizedFailureReasonErrorKey: errorReason,
                                                     OpenVPNAdapterErrorMessageKey: message != nil ? message : @"",
                                                     OpenVPNAdapterErrorFatalKey: @(event->fatal) }];
        
        [self performAsyncBlock:^{
            [self.delegate handleError:error];
        }];
    } else {
        OpenVPNAdapterEvent eventIdentifier = [self eventByName:name];
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

- (OpenVPNProperties *)applyConfiguration:(nonnull OpenVPNConfiguration *)configuration error:(out NSError **)error {
    ClientAPI::EvalConfig eval = self.vpnClient->eval_config(configuration.config);
    if (eval.error) {
        NSString *errorReason = [self reasonForError:OpenVPNAdapterErrorConfigurationFailure];
        
        if (error) *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNAdapterErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: @"Failed to apply OpenVPN configuration.",
            NSLocalizedFailureReasonErrorKey: errorReason,
            OpenVPNAdapterErrorMessageKey: [NSString stringWithUTF8String:eval.message.c_str()],
            OpenVPNAdapterErrorFatalKey: @(YES)
        }];
        return nil;
    }
    
    return [[OpenVPNProperties alloc] initWithEvalConfig:eval];
}

- (BOOL)provideCredentials:(nonnull OpenVPNCredentials *)credentials error:(out NSError **)error {
    ClientAPI::Status status = self.vpnClient->provide_creds(credentials.credentials);
    if (status.error) {
        if (error) {
            OpenVPNAdapterError errorCode = !status.status.empty() ? [self errorByName:[NSString stringWithUTF8String:status.status.c_str()]] : OpenVPNAdapterErrorCredentialsFailure;
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
    dispatch_queue_t connectQueue = dispatch_queue_create("me.ss-abramchuk.openvpn-adapter.connection-queue", NULL);
    dispatch_async(connectQueue, ^{
        OpenVPNClient::init_process();
        
        self.tunnelSettingsIPv6 = [OpenVPNTunnelSettings new];
        self.tunnelSettingsIPv4 = [OpenVPNTunnelSettings new];
        
        self.searchDomains = [NSMutableArray new];
        
        ClientAPI::Status status = self.vpnClient->connect();
        if (status.error) {
            OpenVPNAdapterError errorCode = !status.status.empty() ? [self errorByName:[NSString stringWithUTF8String:status.status.c_str()]] : OpenVPNAdapterErrorUnknown;
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
    [packets enumerateObjectsUsingBlock:^(NSData *data, NSUInteger idx, BOOL *stop) {
        if (!_vpnSocket) {
            *stop = YES;
            return;
        }
        
        // Prepare data for sending
        NSData *packet = [self prepareVPNPacket:data protocol:protocols[idx]];
        
        // Send data to the VPN server
        CFSocketSendData(_vpnSocket, NULL, (CFDataRef)packet, 0.05);
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

- (OpenVPNAdapterEvent)eventByName:(NSString *)eventName {
    NSDictionary *events = @{
        @"DISCONNECTED": @(OpenVPNAdapterEventDisconnected),
        @"CONNECTED": @(OpenVPNAdapterEventConnected),
        @"RECONNECTING": @(OpenVPNAdapterEventReconnecting),
        @"RESOLVE": @(OpenVPNAdapterEventResolve),
        @"WAIT": @(OpenVPNAdapterEventWait),
        @"WAIT_PROXY": @(OpenVPNAdapterEventWaitProxy),
        @"CONNECTING": @(OpenVPNAdapterEventConnecting),
        @"GET_CONFIG": @(OpenVPNAdapterEventGetConfig),
        @"ASSIGN_IP": @(OpenVPNAdapterEventAssignIP),
        @"ADD_ROUTES": @(OpenVPNAdapterEventAddRoutes),
        @"ECHO": @(OpenVPNAdapterEventEcho),
        @"INFO": @(OpenVPNAdapterEventInfo),
        @"PAUSE": @(OpenVPNAdapterEventPause),
        @"RESUME": @(OpenVPNAdapterEventResume),
        @"RELAY": @(OpenVPNAdapterEventRelay)
    };
    
    OpenVPNAdapterEvent event = events[eventName] != nil ? (OpenVPNAdapterEvent)[events[eventName] integerValue] : OpenVPNAdapterEventUnknown;
    return event;
}

- (OpenVPNAdapterError)errorByName:(NSString *)errorName {
    NSDictionary *errors = @{
        @"NETWORK_RECV_ERROR": @(OpenVPNAdapterErrorNetworkRecvError),
        @"NETWORK_EOF_ERROR": @(OpenVPNAdapterErrorNetworkEOFError),
        @"NETWORK_SEND_ERROR": @(OpenVPNAdapterErrorNetworkSendError),
        @"NETWORK_UNAVAILABLE": @(OpenVPNAdapterErrorNetworkUnavailable),
        @"DECRYPT_ERROR": @(OpenVPNAdapterErrorDecryptError),
        @"HMAC_ERROR": @(OpenVPNAdapterErrorDecryptError),
        @"REPLAY_ERROR": @(OpenVPNAdapterErrorReplayError),
        @"BUFFER_ERROR": @(OpenVPNAdapterErrorBufferError),
        @"CC_ERROR": @(OpenVPNAdapterErrorCCError),
        @"BAD_SRC_ADDR": @(OpenVPNAdapterErrorBadSrcAddr),
        @"COMPRESS_ERROR": @(OpenVPNAdapterErrorCompressError),
        @"RESOLVE_ERROR": @(OpenVPNAdapterErrorResolveError),
        @"SOCKET_PROTECT_ERROR": @(OpenVPNAdapterErrorSocketProtectError),
        @"TUN_READ_ERROR": @(OpenVPNAdapterErrorTUNReadError),
        @"TUN_WRITE_ERROR": @(OpenVPNAdapterErrorTUNWriteError),
        @"TUN_FRAMING_ERROR": @(OpenVPNAdapterErrorTUNFramingError),
        @"TUN_SETUP_FAILED": @(OpenVPNAdapterErrorTUNSetupFailed),
        @"TUN_IFACE_CREATE": @(OpenVPNAdapterErrorTUNIfaceCreate),
        @"TUN_IFACE_DISABLED": @(OpenVPNAdapterErrorTUNIfaceDisabled),
        @"TUN_ERROR": @(OpenVPNAdapterErrorTUNError),
        @"TAP_NOT_SUPPORTED": @(OpenVPNAdapterErrorTAPNotSupported),
        @"REROUTE_GW_NO_DNS": @(OpenVPNAdapterErrorRerouteGatewayNoDns),
        @"TRANSPORT_ERROR": @(OpenVPNAdapterErrorTransportError),
        @"TCP_OVERFLOW": @(OpenVPNAdapterErrorTCPOverflow),
        @"TCP_SIZE_ERROR": @(OpenVPNAdapterErrorTCPSizeError),
        @"TCP_CONNECT_ERROR": @(OpenVPNAdapterErrorTCPConnectError),
        @"UDP_CONNECT_ERROR": @(OpenVPNAdapterErrorUDPConnectError),
        @"SSL_ERROR": @(OpenVPNAdapterErrorSSLError),
        @"SSL_PARTIAL_WRITE": @(OpenVPNAdapterErrorSSLPartialWrite),
        @"ENCAPSULATION_ERROR": @(OpenVPNAdapterErrorEncapsulationError),
        @"EPKI_CERT_ERROR": @(OpenVPNAdapterErrorEPKICertError),
        @"EPKI_SIGN_ERROR": @(OpenVPNAdapterErrorEPKISignError),
        @"HANDSHAKE_TIMEOUT": @(OpenVPNAdapterErrorHandshakeTimeout),
        @"KEEPALIVE_TIMEOUT": @(OpenVPNAdapterErrorKeepaliveTimeout),
        @"INACTIVE_TIMEOUT": @(OpenVPNAdapterErrorInactiveTimeout),
        @"CONNECTION_TIMEOUT": @(OpenVPNAdapterErrorConnectionTimeout),
        @"PRIMARY_EXPIRE": @(OpenVPNAdapterErrorPrimaryExpire),
        @"TLS_VERSION_MIN": @(OpenVPNAdapterErrorTLSVersionMin),
        @"TLS_AUTH_FAIL": @(OpenVPNAdapterErrorTLSAuthFail),
        @"CERT_VERIFY_FAIL": @(OpenVPNAdapterErrorCertVerifyFail),
        @"PEM_PASSWORD_FAIL": @(OpenVPNAdapterErrorPEMPasswordFail),
        @"AUTH_FAILED": @(OpenVPNAdapterErrorAuthFailed),
        @"CLIENT_HALT": @(OpenVPNAdapterErrorClientHalt),
        @"CLIENT_RESTART": @(OpenVPNAdapterErrorClientRestart),
        @"RELAY": @(OpenVPNAdapterErrorRelay),
        @"RELAY_ERROR": @(OpenVPNAdapterErrorRelayError),
        @"N_PAUSE": @(OpenVPNAdapterErrorPauseNumber),
        @"N_RECONNECT": @(OpenVPNAdapterErrorReconnectNumber),
        @"N_KEY_LIMIT_RENEG": @(OpenVPNAdapterErrorKeyLimitRenegNumber),
        @"KEY_STATE_ERROR": @(OpenVPNAdapterErrorKeyStateError),
        @"PROXY_ERROR": @(OpenVPNAdapterErrorProxyError),
        @"PROXY_NEED_CREDS": @(OpenVPNAdapterErrorProxyNeedCreds),
        @"KEV_NEGOTIATE_ERROR": @(OpenVPNAdapterErrorKevNegotiateError),
        @"KEV_PENDING_ERROR": @(OpenVPNAdapterErrorKevPendingError),
        @"N_KEV_EXPIRE": @(OpenVPNAdapterErrorKevExpireNumber),
        @"PKTID_INVALID": @(OpenVPNAdapterErrorPKTIDInvalid),
        @"PKTID_BACKTRACK": @(OpenVPNAdapterErrorPKTIDBacktrack),
        @"PKTID_EXPIRE": @(OpenVPNAdapterErrorPKTIDExpire),
        @"PKTID_REPLAY": @(OpenVPNAdapterErrorPKTIDReplay),
        @"PKTID_TIME_BACKTRACK": @(OpenVPNAdapterErrorPKTIDTimeBacktrack),
        @"DYNAMIC_CHALLENGE": @(OpenVPNAdapterErrorDynamicChallenge),
        @"EPKI_ERROR": @(OpenVPNAdapterErrorEPKIError),
        @"EPKI_INVALID_ALIAS": @(OpenVPNAdapterErrorEPKIInvalidAlias),
    };
    
    OpenVPNAdapterError error = errors[errorName] != nil ? (OpenVPNAdapterError)[errors[errorName] integerValue] : OpenVPNAdapterErrorUnknown;
    return error;
}

- (NSString *)reasonForError:(OpenVPNAdapterError)error {
    // TODO: Add missing error reasons
    switch (error) {
        case OpenVPNAdapterErrorConfigurationFailure: return @"See OpenVPN error message for more details.";
        case OpenVPNAdapterErrorCredentialsFailure: return @"See OpenVPN error message for more details.";
        case OpenVPNAdapterErrorNetworkRecvError: return @"Errors receiving on network socket.";
        case OpenVPNAdapterErrorNetworkEOFError: return @"EOF received on TCP network socket.";
        case OpenVPNAdapterErrorNetworkSendError: return @"Errors sending on network socket";
        case OpenVPNAdapterErrorNetworkUnavailable: return @"Network unavailable.";
        case OpenVPNAdapterErrorDecryptError: return @"Data channel encrypt/decrypt error.";
        case OpenVPNAdapterErrorHMACError: return @"HMAC verification failure.";
        case OpenVPNAdapterErrorReplayError: return @"Error from PacketIDReceive.";
        case OpenVPNAdapterErrorBufferError: return @"Exception thrown in Buffer methods.";
        case OpenVPNAdapterErrorCCError: return @"General control channel errors.";
        case OpenVPNAdapterErrorBadSrcAddr: return @"Packet from unknown source address.";
        case OpenVPNAdapterErrorCompressError: return @"Compress/Decompress errors on data channel.";
        case OpenVPNAdapterErrorResolveError: return @"DNS resolution error.";
        case OpenVPNAdapterErrorSocketProtectError: return @"Error calling protect() method on socket.";
        case OpenVPNAdapterErrorTUNReadError: return @"Read errors on TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNWriteError: return @"Write errors on TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNFramingError: return @"Error with tun PF_INET/PF_INET6 prefix.";
        case OpenVPNAdapterErrorTUNSetupFailed: return @"Error setting up TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNIfaceCreate: return @"Error creating TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNIfaceDisabled: return @"TUN/TAP interface is disabled.";
        case OpenVPNAdapterErrorTUNError: return @"General tun error.";
        case OpenVPNAdapterErrorTAPNotSupported: return @"Dev TAP is present in profile but not supported.";
        case OpenVPNAdapterErrorRerouteGatewayNoDns: return @"redirect-gateway specified without alt DNS servers.";
        case OpenVPNAdapterErrorTransportError: return @"General transport error";
        case OpenVPNAdapterErrorTCPOverflow: return @"TCP output queue overflow.";
        case OpenVPNAdapterErrorTCPSizeError: return @"Bad embedded uint16_t TCP packet size.";
        case OpenVPNAdapterErrorTCPConnectError: return @"Client error on TCP connect.";
        case OpenVPNAdapterErrorUDPConnectError: return @"Client error on UDP connect.";
        case OpenVPNAdapterErrorSSLError: return @"Errors resulting from read/write on SSL object.";
        case OpenVPNAdapterErrorSSLPartialWrite: return @"SSL object did not process all written cleartext.";
        case OpenVPNAdapterErrorEncapsulationError: return @"Exceptions thrown during packet encapsulation.";
        case OpenVPNAdapterErrorEPKICertError: return @"Error obtaining certificate from External PKI provider.";
        case OpenVPNAdapterErrorEPKISignError: return @"Error obtaining RSA signature from External PKI provider.";
        case OpenVPNAdapterErrorHandshakeTimeout: return @"Handshake failed to complete within given time frame.";
        case OpenVPNAdapterErrorKeepaliveTimeout: return @"Lost contact with peer.";
        case OpenVPNAdapterErrorInactiveTimeout: return @"Disconnected due to inactive timer.";
        case OpenVPNAdapterErrorConnectionTimeout: return @"Connection failed to establish within given time.";
        case OpenVPNAdapterErrorPrimaryExpire: return @"Primary key context expired.";
        case OpenVPNAdapterErrorTLSVersionMin: return @"Peer cannot handshake at our minimum required TLS version.";
        case OpenVPNAdapterErrorTLSAuthFail: return @"tls-auth HMAC verification failed.";
        case OpenVPNAdapterErrorCertVerifyFail: return @"Peer certificate verification failure.";
        case OpenVPNAdapterErrorPEMPasswordFail: return @"Incorrect or missing PEM private key decryption password.";
        case OpenVPNAdapterErrorAuthFailed: return @"General authentication failure";
        case OpenVPNAdapterErrorClientHalt: return @"HALT message from server received.";
        case OpenVPNAdapterErrorClientRestart: return @"RESTART message from server received.";
        case OpenVPNAdapterErrorRelay: return @"RELAY message from server received.";
        case OpenVPNAdapterErrorRelayError: return @"RELAY error.";
        case OpenVPNAdapterErrorPauseNumber: return @"";
        case OpenVPNAdapterErrorReconnectNumber: return @"";
        case OpenVPNAdapterErrorKeyLimitRenegNumber: return @"";
        case OpenVPNAdapterErrorKeyStateError: return @"Received packet didn't match expected key state.";
        case OpenVPNAdapterErrorProxyError: return @"HTTP proxy error.";
        case OpenVPNAdapterErrorProxyNeedCreds: return @"HTTP proxy needs credentials.";
        case OpenVPNAdapterErrorKevNegotiateError: return @"";
        case OpenVPNAdapterErrorKevPendingError: return @"";
        case OpenVPNAdapterErrorKevExpireNumber: return @"";
        case OpenVPNAdapterErrorPKTIDInvalid: return @"";
        case OpenVPNAdapterErrorPKTIDBacktrack: return @"";
        case OpenVPNAdapterErrorPKTIDExpire: return @"";
        case OpenVPNAdapterErrorPKTIDReplay: return @"";
        case OpenVPNAdapterErrorPKTIDTimeBacktrack: return @"";
        case OpenVPNAdapterErrorDynamicChallenge: return @"";
        case OpenVPNAdapterErrorEPKIError: return @"";
        case OpenVPNAdapterErrorEPKIInvalidAlias: return @"";
        case OpenVPNAdapterErrorUnknown: return @"Unknown error.";
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

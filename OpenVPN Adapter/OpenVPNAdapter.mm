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
#import "OpenVPNAdapter+Internal.h"
#import "OpenVPNAdapter+Public.h"

NSString * const OpenVPNAdapterErrorDomain = @"me.ss-abramchuk.openvpn-adapter.error-domain";

NSString * const OpenVPNAdapterErrorFatalKey = @"me.ss-abramchuk.openvpn-adapter.error-key.fatal";
NSString * const OpenVPNAdapterErrorEventKey = @"me.ss-abramchuk.openvpn-adapter.error-key.event";


@interface OpenVPNAdapter () {
    NSString *_username;
    NSString *_password;
    
    __weak id<OpenVPNAdapterDelegate> _delegate;
}

@property OpenVPNClient *vpnClient;

@property CFSocketRef vpnSocket;
@property CFSocketRef tunSocket;

@property (strong, nonatomic) NSString *remoteAddress;

@property (strong, nonatomic) TUNConfiguration *tunConfigurationIPv6;
@property (strong, nonatomic) TUNConfiguration *tunConfigurationIPv4;

@property (strong, nonatomic) NSMutableArray *searchDomains;

@property (strong, nonatomic) NSNumber *mtu;

@property (weak, nonatomic) id<OpenVPNAdapterPacketFlow> packetFlow;

- (void)readTUNPackets;
- (void)readVPNData:(NSData *)data;
- (NSString *)getSubnetFromPrefixLength:(NSNumber *)prefixLength;

@end

@implementation OpenVPNAdapter (Client)

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
    
    if (isIPv6) {
        if (!self.tunConfigurationIPv6.initialized) {
            self.tunConfigurationIPv6.initialized = YES;
        }
        
        [self.tunConfigurationIPv6.localAddresses addObject:address];
        [self.tunConfigurationIPv6.prefixLengths addObject:prefixLength];
    } else {
        if (!self.tunConfigurationIPv4.initialized) {
            self.tunConfigurationIPv4.initialized = YES;
        }
        
        [self.tunConfigurationIPv4.localAddresses addObject:address];
        [self.tunConfigurationIPv4.prefixLengths addObject:prefixLength];
    }
    
    return YES;
}

- (BOOL)defaultGatewayRerouteIPv4:(BOOL)rerouteIPv4 rerouteIPv6:(BOOL)rerouteIPv6 {
    if (rerouteIPv6) {
        NEIPv6Route *includedRoute = [NEIPv6Route defaultRoute];
        [self.tunConfigurationIPv6.includedRoutes addObject:includedRoute];
    }
    
    if (rerouteIPv4) {
        NEIPv4Route *includedRoute = [NEIPv4Route defaultRoute];
        [self.tunConfigurationIPv4.includedRoutes addObject:includedRoute];
    }
    
    return YES;
}

- (BOOL)addRoute:(NSString *)route prefixLength:(NSNumber *)prefixLength isIPv6:(BOOL)isIPv6 {
    if (route == nil || prefixLength == nil) {
        return NO;
    }
    
    if (isIPv6) {
        NEIPv6Route *includedRoute = [[NEIPv6Route alloc] initWithDestinationAddress:route networkPrefixLength:prefixLength];
        [self.tunConfigurationIPv6.includedRoutes addObject:includedRoute];
    } else {
        NSString *subnet = [self getSubnetFromPrefixLength:prefixLength];
        NEIPv4Route *includedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnet];
        [self.tunConfigurationIPv4.includedRoutes addObject:includedRoute];
    }
    
    return YES;
}

- (BOOL)excludeRoute:(NSString *)route prefixLength:(NSNumber *)prefixLength isIPv6:(BOOL)isIPv6 {
    if (route == nil || prefixLength == nil) {
        return NO;
    }
    
    if (isIPv6) {
        NEIPv6Route *excludedRoute = [[NEIPv6Route alloc] initWithDestinationAddress:route networkPrefixLength:prefixLength];
        [self.tunConfigurationIPv6.excludedRoutes addObject:excludedRoute];
    } else {
        NSString *subnet = [self getSubnetFromPrefixLength:prefixLength];
        NEIPv4Route *excludedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnet];
        [self.tunConfigurationIPv4.excludedRoutes addObject:excludedRoute];
    }
    
    return YES;
}

- (BOOL)addDNSAddress:(NSString *)address isIPv6:(BOOL)isIPv6 {
    if (address == nil) {
        return NO;
    }
    
    if (isIPv6) {
        [self.tunConfigurationIPv6.dnsAddresses addObject:address];
    } else {
        [self.tunConfigurationIPv4.dnsAddresses addObject:address];
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
    if (self.tunConfigurationIPv6.initialized) {
        NEIPv6Settings *settingsIPv6 = [[NEIPv6Settings alloc] initWithAddresses:self.tunConfigurationIPv6.localAddresses networkPrefixLengths:self.tunConfigurationIPv6.prefixLengths];
        settingsIPv6.includedRoutes = self.tunConfigurationIPv6.includedRoutes;
        settingsIPv6.excludedRoutes = self.tunConfigurationIPv6.excludedRoutes;
        
        networkSettings.IPv6Settings = settingsIPv6;
    }
    
    // Configure IPv4 addresses and routes
    if (self.tunConfigurationIPv4.initialized) {
        NSMutableArray *subnets = [NSMutableArray new];
        [self.tunConfigurationIPv4.prefixLengths enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *subnet = [self getSubnetFromPrefixLength:obj];
            [subnets addObject:subnet];
        }];
        
        NEIPv4Settings *ipSettings = [[NEIPv4Settings alloc] initWithAddresses:self.tunConfigurationIPv4.localAddresses subnetMasks:subnets];
        ipSettings.includedRoutes = self.tunConfigurationIPv4.includedRoutes;
        ipSettings.excludedRoutes = self.tunConfigurationIPv4.excludedRoutes;
        
        networkSettings.IPv4Settings = ipSettings;
    }
    
    // Configure DNS addresses and search domains
    NSMutableArray *dnsAddresses = [NSMutableArray new];
    
    if (self.tunConfigurationIPv6.dnsAddresses.count > 0) {
        [dnsAddresses addObjectsFromArray:self.tunConfigurationIPv6.dnsAddresses];
    }
    
    if (self.tunConfigurationIPv4.dnsAddresses.count > 0) {
        [dnsAddresses addObjectsFromArray:self.tunConfigurationIPv4.dnsAddresses];
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
    
    [self.delegate configureTunnelWithSettings:networkSettings callback:^(id<OpenVPNAdapterPacketFlow> _Nullable flow) {
        self.packetFlow = flow;
        dispatch_semaphore_signal(sema);
    }];
    
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
        [userInfo setObject:@(eventIdentifier) forKey:OpenVPNAdapterErrorEventKey];
        
        if (eventMessage != nil && ![eventMessage isEqualToString:@""]) {
            [userInfo setObject:eventMessage forKey:NSLocalizedDescriptionKey];
        }
        
        NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                             code:OpenVPNErrorClientFailure
                                         userInfo:[userInfo copy]];
        
        [self.delegate handleError:error];
    } else {
        [self.delegate handleEvent:eventIdentifier message:eventMessage == nil || [eventMessage isEqualToString:@""] ? nil : eventMessage];
    }
}

- (void)handleLog:(const ClientAPI::LogInfo *)log {
    NSAssert(self.delegate != nil, @"delegate property should not be nil");
    
    NSString *message = [NSString stringWithCString:log->text.c_str() encoding:NSUTF8StringEncoding];
    [self.delegate handleLog:message];
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

#pragma mark Properties Gettters/Setters

- (void)setUsername:(NSString *)username {
    _username = username;
}

- (NSString *)username {
    return _username;
}

- (void)setPassword:(NSString *)password {
    _password = password;
}

- (NSString *)password {
    return _password;
}

- (void)setDelegate:(id<OpenVPNAdapterDelegate>)delegate {
    _delegate = delegate;
}

- (id<OpenVPNAdapterDelegate>)delegate {
    return _delegate;
}

#pragma mark Client Configuration

- (BOOL)configureUsingSettings:(NSData *)settings error:(out NSError * __autoreleasing _Nullable *)error {
    NSString *vpnConfiguration = [[NSString alloc] initWithData:settings encoding:NSUTF8StringEncoding];
    
    if (vpnConfiguration == nil) {
        if (error) *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: @"Failed to read VPN configuration"
        }];
        return NO;
    }
    
    ClientAPI::Config clientConfiguration;
    clientConfiguration.content = std::string([vpnConfiguration UTF8String]);
    clientConfiguration.connTimeout = 30;
    
    ClientAPI::EvalConfig eval = self.vpnClient->eval_config(clientConfiguration);
    if (eval.error) {
        if (error) *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNErrorConfigurationFailure userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithUTF8String:eval.message.c_str()]
        }];
        return NO;
    }

    ClientAPI::ProvideCreds creds;
    creds.username = self.username == nil? "" : [self.username UTF8String];
    creds.password = self.password == nil ? "" : [self.password UTF8String];
    
    ClientAPI::Status creds_status = self.vpnClient->provide_creds(creds);
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
    // TODO: Describe why we use async invocation here
    dispatch_queue_t connectQueue = dispatch_queue_create("me.ss-abramchuk.openvpn-ios-client.connection", NULL);
    dispatch_async(connectQueue, ^{
        self.tunConfigurationIPv6 = [TUNConfiguration new];
        self.tunConfigurationIPv4 = [TUNConfiguration new];
        
        self.searchDomains = [NSMutableArray new];
        
        OpenVPNClient::init_process();
        
        try {
            ClientAPI::Status status = self.vpnClient->connect();
            if (status.error) {
                NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                                     code:OpenVPNErrorClientFailure
                                                 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:status.message.c_str()],
                                                             OpenVPNAdapterErrorFatalKey: @(YES),
                                                             OpenVPNAdapterErrorEventKey: @(OpenVPNEventConnectionFailed) }];
                [self.delegate handleError:error];
            }
        } catch(const std::exception& e) {
            NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain
                                                 code:OpenVPNErrorClientFailure
                                             userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:e.what()],
                                                         OpenVPNAdapterErrorFatalKey: @(YES),
                                                         OpenVPNAdapterErrorEventKey: @(OpenVPNEventConnectionFailed) }];
            [self.delegate handleError:error];
        }
        
        OpenVPNClient::uninit_process();
        
        self.remoteAddress = nil;
        
        self.tunConfigurationIPv6 = nil;
        self.tunConfigurationIPv4 = nil;
        
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
    });
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
        _username = nil;
        _password = nil;
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
            [packet appendData:packet];
            
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

- (NSString *)getSubnetFromPrefixLength:(NSNumber *)prefixLength {
    uint32_t bitmask = UINT_MAX << (sizeof(uint32_t) * 8 - prefixLength.integerValue);
    
    uint8_t first = (bitmask >> 24) & 0xFF;
    uint8_t second = (bitmask >> 16) & 0xFF;
    uint8_t third = (bitmask >> 8) & 0xFF;
    uint8_t fourth = bitmask & 0xFF;
    
    return [NSString stringWithFormat:@"%hhu.%hhu.%hhu.%hhu", first, second, third, fourth];
}

#pragma mark Deallocation

- (void)dealloc {
    delete self.vpnClient;
}

@end

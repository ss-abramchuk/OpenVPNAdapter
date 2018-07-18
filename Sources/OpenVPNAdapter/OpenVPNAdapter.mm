//
//  OpenVPNAdapter.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#define OPENVPN_EXTERN extern

#import "OpenVPNAdapter.h"

#import <NetworkExtension/NetworkExtension.h>

#import "OpenVPNClient.h"
#import "OpenVPNError.h"
#import "OpenVPNAdapterEvent.h"
#import "OpenVPNPacketFlowBridge.h"
#import "OpenVPNNetworkSettingsBuilder.h"
#import "OpenVPNAdapterPacketFlow.h"
#import "OpenVPNCredentials+Internal.h"
#import "OpenVPNConfiguration+Internal.h"
#import "OpenVPNConnectionInfo+Internal.h"
#import "OpenVPNInterfaceStats+Internal.h"
#import "OpenVPNProperties+Internal.h"
#import "OpenVPNSessionToken+Internal.h"
#import "OpenVPNTransportStats+Internal.h"
#import "NSError+OpenVPNError.h"

@interface OpenVPNAdapter () <OpenVPNClientDelegate>

@property (nonatomic) OpenVPNClient *vpnClient;

@property (nonatomic) OpenVPNPacketFlowBridge *packetFlowBridge;
@property (nonatomic) OpenVPNNetworkSettingsBuilder *networkSettingsBuilder;

@end

@implementation OpenVPNAdapter

- (instancetype)init {
    if (self = [super init]) {
        _vpnClient = new OpenVPNClient(self);
    }
    return self;
}

#pragma mark - OpenVPNClient Lifecycle

- (OpenVPNProperties *)applyConfiguration:(OpenVPNConfiguration *)configuration error:(NSError * __autoreleasing *)error {
    ClientAPI::EvalConfig eval = self.vpnClient->eval_config(configuration.config);
    
    if (eval.error) {
        if (error) {
            NSString *message = [NSString stringWithUTF8String:eval.message.c_str()];
            *error = [NSError ovpn_errorObjectForAdapterError:OpenVPNAdapterErrorConfigurationFailure
                                          description:@"Failed to apply OpenVPN configuration"
                                              message:message
                                                fatal:YES];
        }
        
        return nil;
    }
    
    return [[OpenVPNProperties alloc] initWithEvalConfig:eval];
}

- (BOOL)provideCredentials:(OpenVPNCredentials *)credentials error:(NSError * __autoreleasing *)error {
    ClientAPI::Status status = self.vpnClient->provide_creds(credentials.credentials);
    
    if (status.error) {
        if (error) {
            NSString *message = [NSString stringWithUTF8String:status.message.c_str()];
            *error = [NSError ovpn_errorObjectForAdapterError:OpenVPNAdapterErrorCredentialsFailure
                                          description:@"Failed to provide OpenVPN credentials"
                                              message:message
                                                fatal:YES];
        }
        
        return NO;
    }
    
    return YES;
}

- (void)connect {
    dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
    dispatch_queue_t connectQueue = dispatch_queue_create("me.ss-abramchuk.openvpn-adapter.connection", attributes);
    dispatch_async(connectQueue, ^{
        OpenVPNClient::init_process();
        
        ClientAPI::Status status = self.vpnClient->connect();
        [self handleConnectionStatus:status];
        
        OpenVPNClient::uninit_process();
    });
}

- (void)reconnectAfterTimeInterval:(NSTimeInterval)timeInterval {
    self.vpnClient->reconnect(timeInterval);
}

- (void)disconnect {
    self.vpnClient->stop();
}

- (void)pauseWithReason:(NSString *)reason {
    self.vpnClient->pause(std::string(reason.UTF8String));
}

- (void)resume {
    self.vpnClient->resume();
}

- (void)handleConnectionStatus:(ClientAPI::Status)status {
    if (!status.error) { return; }
    
    OpenVPNAdapterError adapterError = !status.status.empty() ?
        [NSError ovpn_adapterErrorByName:[NSString stringWithUTF8String:status.status.c_str()]] :
        OpenVPNAdapterErrorUnknown;
    
    NSString *message = [NSString stringWithUTF8String:status.message.c_str()];
    NSError *error = [NSError ovpn_errorObjectForAdapterError:adapterError
                                          description:@"Failed to establish connection with OpenVPN server"
                                              message:message
                                                fatal:YES];

    [self.delegate openVPNAdapter:self handleError:error];
}

#pragma mark - OpenVPNClient Information

+ (NSString *)copyright {
    return [NSString stringWithUTF8String:OpenVPNClient::copyright().c_str()];
}

+ (NSString *)platform {
    return [NSString stringWithUTF8String:OpenVPNClient::platform().c_str()];
}

- (OpenVPNConnectionInfo *)connectionInformation {
    ClientAPI::ConnectionInfo information = self.vpnClient->connection_info();
    return information.defined ? [[OpenVPNConnectionInfo alloc] initWithConnectionInfo:information] : nil;
}

- (OpenVPNInterfaceStats *)interfaceStatistics {
    return [[OpenVPNInterfaceStats alloc] initWithInterfaceStats:self.vpnClient->tun_stats()];
}

- (OpenVPNSessionToken *)sessionToken {
    ClientAPI::SessionToken token;
    return self.vpnClient->session_token(token) ? [[OpenVPNSessionToken alloc] initWithSessionToken:token] : nil;
}

- (OpenVPNTransportStats *)transportStatistics {
    return [[OpenVPNTransportStats alloc] initWithTransportStats:self.vpnClient->transport_stats()];
}

#pragma mark - Lazy Initialization

- (OpenVPNNetworkSettingsBuilder *)networkSettingsBuilder {
    if (!_networkSettingsBuilder) { _networkSettingsBuilder = [[OpenVPNNetworkSettingsBuilder alloc] init]; }
    return _networkSettingsBuilder;
}

#pragma mark - OpenVPNClientDelegate

- (BOOL)setRemoteAddress:(NSString *)address {
    self.networkSettingsBuilder.remoteAddress = address;
    return YES;
}

- (BOOL)addIPV4Address:(NSString *)address subnetMask:(NSString *)subnetMask gateway:(NSString *)gateway {
    self.networkSettingsBuilder.ipv4DefaultGateway = gateway;
    [self.networkSettingsBuilder.ipv4LocalAddresses addObject:address];
    [self.networkSettingsBuilder.ipv4SubnetMasks addObject:subnetMask];
    
    return YES;
}

- (BOOL)addIPV6Address:(NSString *)address prefixLength:(NSNumber *)prefixLength gateway:(NSString *)gateway {
    self.networkSettingsBuilder.ipv6DefaultGateway = gateway;
    [self.networkSettingsBuilder.ipv6LocalAddresses addObject:address];
    [self.networkSettingsBuilder.ipv6NetworkPrefixLengths addObject:prefixLength];
    
    return YES;
}

- (BOOL)addIPV4Route:(NEIPv4Route *)route {
    route.gatewayAddress = self.networkSettingsBuilder.ipv4DefaultGateway;
    [self.networkSettingsBuilder.ipv4IncludedRoutes addObject:route];
    
    return YES;
}

- (BOOL)addIPV6Route:(NEIPv6Route *)route {
    route.gatewayAddress = self.networkSettingsBuilder.ipv6DefaultGateway;
    [self.networkSettingsBuilder.ipv6IncludedRoutes addObject:route];
    
    return YES;
}

- (BOOL)excludeIPV4Route:(NEIPv4Route *)route {
    [self.networkSettingsBuilder.ipv4ExcludedRoutes addObject:route];
    return YES;
}

- (BOOL)excludeIPV6Route:(NEIPv6Route *)route {
    [self.networkSettingsBuilder.ipv6ExcludedRoutes addObject:route];
    return YES;
}

- (BOOL)addDNS:(NSString *)dns {
    [self.networkSettingsBuilder.dnsServers addObject:dns];
    return YES;
}

- (BOOL)addSearchDomain:(NSString *)domain {
    [self.networkSettingsBuilder.searchDomains addObject:domain];
    return YES;
}

- (BOOL)setMTU:(NSNumber *)mtu {
    self.networkSettingsBuilder.mtu = mtu;
    return YES;
}

- (BOOL)setSessionName:(NSString *)name {
    _sessionName = name;
    return YES;
}

- (BOOL)addProxyBypassHost:(NSString *)bypassHost {
    [self.networkSettingsBuilder.proxyExceptionList addObject:bypassHost];
    return YES;
}

- (BOOL)setProxyAutoConfigurationURL:(NSURL *)url {
    self.networkSettingsBuilder.autoProxyConfigurationEnabled = YES;
    self.networkSettingsBuilder.proxyAutoConfigurationURL = url;
    
    return YES;
}

- (BOOL)setProxyServer:(NEProxyServer *)server protocol:(OpenVPNProxyServerProtocol)protocol {
    switch (protocol) {
        case OpenVPNProxyServerProtocolHTTP:
            self.networkSettingsBuilder.httpProxyServerEnabled = YES;
            self.networkSettingsBuilder.httpProxyServer = server;
            break;
        
        case OpenVPNProxyServerProtocolHTTPS:
            self.networkSettingsBuilder.httpsProxyServerEnabled = YES;
            self.networkSettingsBuilder.httpsProxyServer = server;
            break;
    }
    
    return YES;
}

- (BOOL)establishTunnel {
    NEPacketTunnelNetworkSettings *networkSettings = [self.networkSettingsBuilder networkSettings];
    if (!networkSettings) { return NO; }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __weak typeof(self) weakSelf = self;
    void (^completionHandler)(id<OpenVPNAdapterPacketFlow> _Nullable) = ^(id<OpenVPNAdapterPacketFlow> flow) {
        __strong typeof(self) self = weakSelf;
        
        if (flow) {
            self.packetFlowBridge = [[OpenVPNPacketFlowBridge alloc] initWithPacketFlow:flow];
        }
        
        dispatch_semaphore_signal(semaphore);
    };
    
    [self.delegate openVPNAdapter:self configureTunnelWithNetworkSettings:networkSettings completionHandler:completionHandler];
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    
    NSError *socketError;
    if (self.packetFlowBridge && [self.packetFlowBridge configureSocketsWithError:&socketError]) {
        [self.packetFlowBridge startReading];
        return YES;
    } else {
        if (socketError) { [self.delegate openVPNAdapter:self handleError:socketError]; }
        return NO;
    }
}

- (CFSocketNativeHandle)socketHandle {
    return CFSocketGetNative(self.packetFlowBridge.openVPNSocket);
}

- (void)clientEventName:(NSString *)eventName message:(NSString *)message {
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
    
    OpenVPNAdapterEvent event = events[eventName] != nil ?
        (OpenVPNAdapterEvent)[events[eventName] integerValue] : OpenVPNAdapterEventUnknown;
    
    [self.delegate openVPNAdapter:self handleEvent:event message:message];
}

- (void)clientErrorName:(NSString *)errorName fatal:(BOOL)fatal message:(NSString *)message {
    OpenVPNAdapterError adapterError = [NSError ovpn_adapterErrorByName:errorName];
    NSString *description = fatal ? @"OpenVPN fatal error occured" : @"OpenVPN error occured";
    
    NSError *error = [NSError ovpn_errorObjectForAdapterError:adapterError
                                                  description:description
                                                      message:message
                                                        fatal:fatal];

    [self.delegate openVPNAdapter:self handleError:error];
}

- (void)clientLogMessage:(NSString *)logMessage {
    if ([self.delegate respondsToSelector:@selector(openVPNAdapter:handleLogMessage:)]) {
        [self.delegate openVPNAdapter:self handleLogMessage:logMessage];
    }
}

- (void)tick {
    if ([self.delegate respondsToSelector:@selector(openVPNAdapterDidReceiveClockTick:)]) {
        [self.delegate openVPNAdapterDidReceiveClockTick:self];
    }
}

- (void)resetSettings {
    _sessionName = nil;
    _packetFlowBridge = nil;
    _networkSettingsBuilder = nil;
}

#pragma mark -

- (void)dealloc {
    delete _vpnClient;
}

@end

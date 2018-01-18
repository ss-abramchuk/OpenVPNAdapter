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
#import "OpenVPNCredentials+Internal.h"
#import "OpenVPNConfiguration+Internal.h"
#import "OpenVPNConnectionInfo+Internal.h"
#import "OpenVPNInterfaceStats+Internal.h"
#import "OpenVPNNetworkSettingsBuilder.h"
#import "OpenVPNPacketFlowBridge.h"
#import "OpenVPNProperties+Internal.h"
#import "OpenVPNSessionToken+Internal.h"
#import "OpenVPNTransportStats+Internal.h"
#import "OpenVPNAdapterPacketFlow.h"

@interface OpenVPNAdapter () <OpenVPNClientDelegate>

@property (nonatomic) OpenVPNClient *vpnClient;

@property (nonatomic) OpenVPNPacketFlowBridge *packetFlowBridge;
@property (nonatomic) OpenVPNNetworkSettingsBuilder *networkSettingsBuilder;

- (OpenVPNAdapterEvent)eventByName:(NSString *)eventName;
- (OpenVPNAdapterError)errorByName:(NSString *)errorName;
- (NSString *)reasonForError:(OpenVPNAdapterError)error;

@end

@implementation OpenVPNAdapter

- (instancetype)init {
    if (self = [super init]) {
        _vpnClient = new OpenVPNClient(self);
    }
    return self;
}

#pragma mark - OpenVPNClient Lifecycle

- (OpenVPNProperties *)applyConfiguration:(OpenVPNConfiguration *)configuration error:(NSError * _Nullable __autoreleasing *)error {
    ClientAPI::EvalConfig eval = self.vpnClient->eval_config(configuration.config);
    
    if (eval.error) {
        if (error) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
                NSLocalizedDescriptionKey: @"Failed to apply OpenVPN configuration",
                OpenVPNAdapterErrorFatalKey: @YES
            }];
            
            NSString *errorReason = [self reasonForError:OpenVPNAdapterErrorConfigurationFailure];
            if (errorReason) {
                userInfo[NSLocalizedFailureReasonErrorKey] = errorReason;
            }
            
            NSString *message = [[NSString alloc] initWithUTF8String:eval.message.c_str()];
            if (message.length) {
                userInfo[OpenVPNAdapterErrorMessageKey] = message;
            }
            
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNAdapterErrorConfigurationFailure userInfo: userInfo];
        }
        return nil;
    }
    
    return [[OpenVPNProperties alloc] initWithEvalConfig:eval];
}

- (BOOL)provideCredentials:(OpenVPNCredentials *)credentials error:(NSError * _Nullable __autoreleasing *)error {
    ClientAPI::Status status = self.vpnClient->provide_creds(credentials.credentials);
    
    if (status.error) {
        if (error) {
            OpenVPNAdapterError errorCode = !status.status.empty() ?
                [self errorByName:[[NSString alloc] initWithUTF8String:status.status.c_str()]] :
                OpenVPNAdapterErrorCredentialsFailure;
            
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
                NSLocalizedDescriptionKey: @"Failed to provide OpenVPN credentials",
                OpenVPNAdapterErrorFatalKey: @YES
            }];
            
            NSString *errorReason = [self reasonForError:errorCode];
            if (errorReason) {
                userInfo[NSLocalizedFailureReasonErrorKey] = errorReason;
            }
            
            NSString *message = [[NSString alloc] initWithUTF8String:status.message.c_str()];
            if (message.length) {
                userInfo[OpenVPNAdapterErrorMessageKey] = message;
            }
            
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:errorCode userInfo:userInfo];
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
    
    OpenVPNAdapterError errorCode = !status.status.empty() ?
        [self errorByName:[[NSString alloc] initWithUTF8String:status.status.c_str()]] : OpenVPNAdapterErrorUnknown;
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
        NSLocalizedDescriptionKey: @"Failed to establish connection with OpenVPN server",
        OpenVPNAdapterErrorFatalKey: @YES
    }];
    
    NSString *errorReason = [self reasonForError:errorCode];
    if (errorReason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = errorReason;
    }
    
    NSString *message = [[NSString alloc] initWithUTF8String:status.message.c_str()];
    if (message.length) {
        userInfo[OpenVPNAdapterErrorMessageKey] = message;
    }
    
    NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:errorCode userInfo:userInfo];
    [self.delegate openVPNAdapter:self handleError:error];
}

#pragma mark - OpenVPNClient Information

+ (NSString *)copyright {
    return [[NSString alloc] initWithUTF8String:OpenVPNClient::copyright().c_str()];
}

+ (NSString *)platform {
    return [[NSString alloc] initWithUTF8String:OpenVPNClient::platform().c_str()];
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

#pragma mark - OpenVPNAdapterEvent Helpers

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

#pragma mark - OpenVPNAdapterError Helpers

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
        @"EPKI_INVALID_ALIAS": @(OpenVPNAdapterErrorEPKIInvalidAlias)
    };
    
    OpenVPNAdapterError error = errors[errorName] != nil ?
        (OpenVPNAdapterError)[errors[errorName] integerValue] : OpenVPNAdapterErrorUnknown;
    
    return error;
}

- (NSString *)reasonForError:(OpenVPNAdapterError)error {
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
        case OpenVPNAdapterErrorSocketSetupFailed: return nil;
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
        case OpenVPNAdapterErrorPauseNumber: return nil;
        case OpenVPNAdapterErrorReconnectNumber: return nil;
        case OpenVPNAdapterErrorKeyLimitRenegNumber: return nil;
        case OpenVPNAdapterErrorKeyStateError: return @"Received packet didn't match expected key state.";
        case OpenVPNAdapterErrorProxyError: return @"HTTP proxy error.";
        case OpenVPNAdapterErrorProxyNeedCreds: return @"HTTP proxy needs credentials.";
        case OpenVPNAdapterErrorKevNegotiateError: return nil;
        case OpenVPNAdapterErrorKevPendingError: return nil;
        case OpenVPNAdapterErrorKevExpireNumber: return nil;
        case OpenVPNAdapterErrorPKTIDInvalid: return nil;
        case OpenVPNAdapterErrorPKTIDBacktrack: return nil;
        case OpenVPNAdapterErrorPKTIDExpire: return nil;
        case OpenVPNAdapterErrorPKTIDReplay: return nil;
        case OpenVPNAdapterErrorPKTIDTimeBacktrack: return nil;
        case OpenVPNAdapterErrorDynamicChallenge: return nil;
        case OpenVPNAdapterErrorEPKIError: return nil;
        case OpenVPNAdapterErrorEPKIInvalidAlias: return nil;
        case OpenVPNAdapterErrorUnknown: return @"Unknown error.";
    }
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
        __strong typeof(self) strongSelf = weakSelf;
        
        if (flow) {
            strongSelf.packetFlowBridge = [[OpenVPNPacketFlowBridge alloc] initWithPacketFlow:flow];
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
    OpenVPNAdapterEvent eventIdentifier = [self eventByName:eventName];
    [self.delegate openVPNAdapter:self handleEvent:eventIdentifier message:message];
}

- (void)clientErrorName:(NSString *)errorName fatal:(BOOL)fatal message:(NSString *)message {
    OpenVPNAdapterError errorCode = [self errorByName:errorName];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
        NSLocalizedDescriptionKey: fatal ? @"OpenVPN fatal error occured" : @"OpenVPN error occured",
        OpenVPNAdapterErrorFatalKey: @(fatal)
    }];
    
    NSString *errorReason = [self reasonForError:errorCode];
    if (errorReason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = errorReason;
    }
    
    if (message) {
        userInfo[OpenVPNAdapterErrorMessageKey] = message;
    }
    
    NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:errorCode userInfo:userInfo];
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

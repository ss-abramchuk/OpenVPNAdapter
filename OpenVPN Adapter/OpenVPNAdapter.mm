//
//  OpenVPNAdapter.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#define OPENVPN_EXTERN extern

#import <NetworkExtension/NetworkExtension.h>
#import <client/ovpncli.hpp>
#import <openvpn/tun/client/tunbase.hpp>
#import "OpenVPNAdapterEvent.h"
#import "OpenVPNCredentials+Internal.h"
#import "OpenVPNConfiguration+Internal.h"
#import "OpenVPNConnectionInfo+Internal.h"
#import "OpenVPNError.h"
#import "OpenVPNInterfaceStats+Internal.h"
#import "OpenVPNNetworkSettingsBuilder.h"
#import "OpenVPNPacketFlowAdapter.h"
#import "OpenVPNProperties+Internal.h"
#import "OpenVPNSessionToken+Internal.h"
#import "OpenVPNTransportStats+Internal.h"
#import "OpenVPNAdapter.h"

class Client;

@interface OpenVPNAdapter ()

@property (nonatomic) Client *client;

@property (nonatomic) NSString *sessionName;

@property (nonatomic) OpenVPNNetworkSettingsBuilder *networkSettingsBuilder;

@property (nonatomic) OpenVPNPacketFlowAdapter *packetFlowAdapter;

- (OpenVPNAdapterError)errorByName:(NSString *)errorName;
- (OpenVPNAdapterEvent)eventByName:(NSString *)errorName;
- (NSString *)reasonForError:(OpenVPNAdapterError)error;

@end

using namespace openvpn;

class Client : public ClientAPI::OpenVPNClient {
public:
    Client(OpenVPNAdapter *client) {
        this->client = client;
    }
    
    bool tun_builder_set_remote_address(const std::string& address, bool ipv6) override {
        NSString *remoteAddress = [[NSString alloc] initWithUTF8String:address.c_str()];
        client.networkSettingsBuilder.remoteAddress = remoteAddress;
        return true;
    }
    
    bool tun_builder_add_address(const std::string& address, int prefix_length, const std::string& gateway, bool ipv6, bool net30) override {
        NSString *localAddress = [[NSString alloc] initWithUTF8String:address.c_str()];
        NSString *gatewayAddress = [[NSString alloc] initWithUTF8String:gateway.c_str()];
        NSString *defaultGateway = gatewayAddress.length == 0 || [gatewayAddress isEqualToString:@"UNSPEC"] ? nil : gatewayAddress;
        if (ipv6) {
            client.networkSettingsBuilder.ipv6DefaultGateway = defaultGateway;
            [client.networkSettingsBuilder.ipv6LocalAddresses addObject:localAddress];
            [client.networkSettingsBuilder.ipv6NetworkPrefixLengths addObject:@(prefix_length)];
        } else {
            NSString *subnetMask = [[NSString alloc] initWithUTF8String:IPv4::Addr::netmask_from_prefix_len(prefix_length).to_string().c_str()];
            client.networkSettingsBuilder.ipv4DefaultGateway = defaultGateway;
            [client.networkSettingsBuilder.ipv4LocalAddresses addObject:localAddress];
            [client.networkSettingsBuilder.ipv4SubnetMasks addObject:subnetMask];
        }
        return true;
    }
    
    bool tun_builder_reroute_gw(bool ipv4, bool ipv6, unsigned int flags) override {
        if (ipv4) {
            NEIPv4Route *includedRoute = [NEIPv4Route defaultRoute];
            includedRoute.gatewayAddress = client.networkSettingsBuilder.ipv4DefaultGateway;
            [client.networkSettingsBuilder.ipv4IncludedRoutes addObject:includedRoute];
        }
        if (ipv6) {
            NEIPv6Route *includedRoute = [NEIPv6Route defaultRoute];
            includedRoute.gatewayAddress = client.networkSettingsBuilder.ipv6DefaultGateway;
            [client.networkSettingsBuilder.ipv6IncludedRoutes addObject:includedRoute];
        }
        return true;
    }
    
    bool tun_builder_add_route(const std::string& address, int prefix_length, int metric, bool ipv6) override {
        NSString *route = [[NSString alloc] initWithUTF8String:address.c_str()];
        if (ipv6) {
            NEIPv6Route *includedRoute = [[NEIPv6Route alloc] initWithDestinationAddress:route networkPrefixLength:@(prefix_length)];
            includedRoute.gatewayAddress = client.networkSettingsBuilder.ipv6DefaultGateway;
            [client.networkSettingsBuilder.ipv6IncludedRoutes addObject:includedRoute];
        } else {
            NSString *subnetMask = [[NSString alloc] initWithUTF8String:IPv4::Addr::netmask_from_prefix_len(prefix_length).to_string().c_str()];
            NEIPv4Route *includedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnetMask];
            includedRoute.gatewayAddress = client.networkSettingsBuilder.ipv4DefaultGateway;
            [client.networkSettingsBuilder.ipv4IncludedRoutes addObject:includedRoute];
        }
        return true;
    }
    
    bool tun_builder_exclude_route(const std::string& address, int prefix_length, int metric, bool ipv6) override {
        NSString *route = [[NSString alloc] initWithUTF8String:address.c_str()];
        if (ipv6) {
            NEIPv6Route *excludedRoute = [[NEIPv6Route alloc] initWithDestinationAddress:route networkPrefixLength:@(prefix_length)];
            [client.networkSettingsBuilder.ipv6ExcludedRoutes addObject:excludedRoute];
        } else {
            NSString *subnetMask = [[NSString alloc] initWithUTF8String:IPv4::Addr::netmask_from_prefix_len(prefix_length).to_string().c_str()];
            NEIPv4Route *excludedRoute = [[NEIPv4Route alloc] initWithDestinationAddress:route subnetMask:subnetMask];
            [client.networkSettingsBuilder.ipv4ExcludedRoutes addObject:excludedRoute];
        }
        return true;
    }
    
    bool tun_builder_add_dns_server(const std::string& address, bool ipv6) override {
        NSString *dnsAddress = [[NSString alloc] initWithUTF8String:address.c_str()];
        [client.networkSettingsBuilder.dnsServers addObject:dnsAddress];
        return true;
    }
    
    bool tun_builder_add_search_domain(const std::string& domain) override {
        NSString *searchDomain = [[NSString alloc] initWithUTF8String:domain.c_str()];
        [client.networkSettingsBuilder.searchDomains addObject:searchDomain];
        return true;
    }
    
    bool tun_builder_set_mtu(int mtu) override {
        client.networkSettingsBuilder.mtu = @(mtu);
        return true;
    }
    
    bool tun_builder_set_session_name(const std::string& name) override {
        client.sessionName = [[NSString alloc] initWithUTF8String:name.c_str()];
        return true;
    }
    
    bool tun_builder_add_proxy_bypass(const std::string& bypass_host) override {
        NSString *bypassHost = [[NSString alloc] initWithUTF8String:bypass_host.c_str()];
        [client.networkSettingsBuilder.proxyExceptionList addObject:bypassHost];
        return true;
    }
    
    bool tun_builder_set_proxy_auto_config_url(const std::string& urlString) override {
        NSURL *url = [[NSURL alloc] initWithString:[[NSString alloc] initWithUTF8String:urlString.c_str()]];
        client.networkSettingsBuilder.autoProxyConfigurationEnabled = url != nil;
        client.networkSettingsBuilder.proxyAutoConfigurationURL = url;
        return true;
    }
    
    bool tun_builder_set_proxy_http(const std::string& host, int port) override {
        NSString *address = [[NSString alloc] initWithUTF8String:host.c_str()];
        client.networkSettingsBuilder.httpProxyServerEnabled = YES;
        client.networkSettingsBuilder.httpProxyServer = [[NEProxyServer alloc] initWithAddress:address port:port];
        return true;
    }
    
    bool tun_builder_set_proxy_https(const std::string& host, int port) override {
        NSString *address = [[NSString alloc] initWithUTF8String:host.c_str()];
        client.networkSettingsBuilder.httpsProxyServerEnabled = YES;
        client.networkSettingsBuilder.httpsProxyServer = [[NEProxyServer alloc] initWithAddress:address port:port];
        return true;
    }
    
    bool tun_builder_set_block_ipv6(bool block_ipv6) override {
        return false;
    }
    
    bool tun_builder_new() override {
        reset_tun();
        return true;
    }
    
    int tun_builder_establish() override {
        NEPacketTunnelNetworkSettings *networkSettings = client.networkSettingsBuilder.networkSettings;
        if (!networkSettings) {
            return -1;
        }
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [client.delegate openVPNAdapter:client configureTunnelWithNetworkSettings:networkSettings completionHandler:^(NEPacketTunnelFlow * _Nullable flow) {
            client.packetFlowAdapter = [[OpenVPNPacketFlowAdapter alloc] initWithPacketFlow:flow];
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
        
        if (client.packetFlowAdapter) {
            return client.packetFlowAdapter.socketHandle;
        } else {
            return -1;
        }
    }
    
    void tun_builder_teardown(bool disconnect) override {
        reset_tun();
    }
    
    bool tun_builder_persist() override {
        return true;
    }
    
    bool socket_protect(int socket) override {
        return true;
    }
    
    bool pause_on_connection_timeout() override {
        return false;
    }
    
    void external_pki_cert_request(ClientAPI::ExternalPKICertRequest& certreq) override {
        
    }
    
    void external_pki_sign_request(ClientAPI::ExternalPKISignRequest& signreq) override {
        
    }
    
    void event(const ClientAPI::Event& event) override {
        NSString *name = [[NSString alloc] initWithUTF8String:event.name.c_str()];
        NSString *message = [[NSString alloc] initWithUTF8String:event.info.c_str()];
        
        if (event.error) {
            OpenVPNAdapterError errorCode = [client errorByName:name];
            NSString *errorReason = [client reasonForError:errorCode];
            NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: @"OpenVPN error occured.", NSLocalizedFailureReasonErrorKey: errorReason, OpenVPNAdapterErrorMessageKey: message != nil ? message : @"", OpenVPNAdapterErrorFatalKey: @(event.fatal)}];
            [client.delegate openVPNAdapter:client handleError:error];
        } else {
            OpenVPNAdapterEvent eventIdentifier = [client eventByName:name];
            [client.delegate openVPNAdapter:client handleEvent:eventIdentifier message:message.length ? message : nil];
        }
    }
    
    void log(const ClientAPI::LogInfo& log) override {
        if ([client.delegate respondsToSelector:@selector(openVPNAdapter:handleLogMessage:)]) {
            [client.delegate openVPNAdapter:client handleLogMessage:[[NSString alloc] initWithUTF8String:log.text.c_str()]];
        }
    }
    
    void clock_tick() override {
        if ([client.delegate respondsToSelector:@selector(openVPNAdapterDidReceiveClockTick:)]) {
            [client.delegate openVPNAdapterDidReceiveClockTick:client];
        }
    }
    
    void reset_tun() {
        client.packetFlowAdapter = nil;
        client.networkSettingsBuilder = nil;
        client.sessionName = nil;
    }
private:
    OpenVPNAdapter *client;
};

@implementation OpenVPNAdapter

#pragma mark - Initialization

- (instancetype)init {
    if ((self = [super init])) {
        self.client = new Client(self);
    }
    return self;
}

#pragma mark - OpenVPNClient Lifecycle

- (OpenVPNProperties *)applyConfiguration:(OpenVPNConfiguration *)configuration error:(NSError * _Nullable __autoreleasing *)error {
    ClientAPI::EvalConfig eval = self.client->eval_config(configuration.config);
    
    if (eval.error) {
        if (error) {
            NSString *errorReason = [self reasonForError:OpenVPNAdapterErrorConfigurationFailure];
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:OpenVPNAdapterErrorConfigurationFailure userInfo:@{NSLocalizedDescriptionKey: @"Failed to apply OpenVPN configuration.", NSLocalizedFailureReasonErrorKey: errorReason, OpenVPNAdapterErrorMessageKey: [[NSString alloc] initWithUTF8String:eval.message.c_str()], OpenVPNAdapterErrorFatalKey: @YES}];
        }
        return nil;
    }
    
    return [[OpenVPNProperties alloc] initWithEvalConfig:eval];
}

- (BOOL)provideCredentials:(OpenVPNCredentials *)credentials error:(NSError * _Nullable __autoreleasing *)error {
    ClientAPI::Status status = self.client->provide_creds(credentials.credentials);
    
    if (status.error) {
        if (error) {
            OpenVPNAdapterError errorCode = !status.status.empty() ? [self errorByName:[[NSString alloc] initWithUTF8String:status.status.c_str()]] : OpenVPNAdapterErrorCredentialsFailure;
            NSString *errorReason = [self reasonForError:errorCode];
            *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: @"Failed to provide OpenVPN credentials.", NSLocalizedFailureReasonErrorKey: errorReason, OpenVPNAdapterErrorMessageKey: [[NSString alloc] initWithUTF8String:status.message.c_str()], OpenVPNAdapterErrorFatalKey: @YES}];
        }
        return NO;
    }
    
    return YES;
}

- (void)connect {
    dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
    dispatch_queue_t connectQueue = dispatch_queue_create("com.openvpnadapter.connection", attributes);
    dispatch_async(connectQueue, ^{
        Client::init_process();
        ClientAPI::Status status = self.client->connect();
        [self handleConnectionStatus:status];
        Client::uninit_process();
    });
}

- (void)reconnectAfterTimeInterval:(NSTimeInterval)timeInterval {
    self.client->reconnect(timeInterval);
}

- (void)disconnect {
    self.client->stop();
}

- (void)pauseWithReason:(NSString *)reason {
    self.client->pause(std::string(reason.UTF8String));
}

- (void)resume {
    self.client->resume();
}

- (void)handleConnectionStatus:(ClientAPI::Status)status {
    if (!status.error) {
        return;
    }
    
    OpenVPNAdapterError errorCode = !status.status.empty() ? [self errorByName:[[NSString alloc] initWithUTF8String:status.status.c_str()]] : OpenVPNAdapterErrorUnknown;
    NSString *errorReason = [self reasonForError:errorCode];
    NSError *error = [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: @"Failed to establish connection with OpenVPN server.", NSLocalizedFailureReasonErrorKey: errorReason, OpenVPNAdapterErrorMessageKey: [[NSString alloc] initWithUTF8String:status.message.c_str()], OpenVPNAdapterErrorFatalKey: @YES}];
    [self.delegate openVPNAdapter:self handleError:error];
}

#pragma mark - OpenVPNClient Information

+ (NSString *)copyright {
    return [[NSString alloc] initWithUTF8String:Client::copyright().c_str()];
}

+ (NSString *)platform {
    return [[NSString alloc] initWithUTF8String:Client::platform().c_str()];
}

- (OpenVPNConnectionInfo *)connectionInformation {
    ClientAPI::ConnectionInfo information = self.client->connection_info();
    return information.defined ? [[OpenVPNConnectionInfo alloc] initWithConnectionInfo:information] : nil;
}

- (OpenVPNInterfaceStats *)interfaceStatistics {
    return [[OpenVPNInterfaceStats alloc] initWithInterfaceStats:self.client->tun_stats()];
}

- (OpenVPNSessionToken *)sessionToken {
    ClientAPI::SessionToken token;
    return self.client->session_token(token) ? [[OpenVPNSessionToken alloc] initWithSessionToken:token] : nil;
}

- (OpenVPNTransportStats *)transportStatistics {
    return [[OpenVPNTransportStats alloc] initWithTransportStats:self.client->transport_stats()];
}

#pragma mark - OpenVPNAdapterEvent Helpers

- (OpenVPNAdapterEvent)eventByName:(NSString *)eventName {
    NSDictionary *events = @{@"DISCONNECTED": @(OpenVPNAdapterEventDisconnected),
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
                             @"RELAY": @(OpenVPNAdapterEventRelay)};
    
    OpenVPNAdapterEvent event = events[eventName] != nil ? (OpenVPNAdapterEvent)[events[eventName] integerValue] : OpenVPNAdapterEventUnknown;
    return event;
}

#pragma mark - OpenVPNAdapterError Helpers

- (OpenVPNAdapterError)errorByName:(NSString *)errorName {
    NSDictionary *errors = @{@"NETWORK_RECV_ERROR": @(OpenVPNAdapterErrorNetworkRecvError),
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
                             @"EPKI_INVALID_ALIAS": @(OpenVPNAdapterErrorEPKIInvalidAlias)};
    
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

#pragma mark - Lazy Initialization

- (OpenVPNNetworkSettingsBuilder *)networkSettingsBuilder {
    if (!_networkSettingsBuilder) {
        _networkSettingsBuilder = [[OpenVPNNetworkSettingsBuilder alloc] init];
    }
    return _networkSettingsBuilder;
}

#pragma mark - Dealloc

- (void)dealloc {
    delete _client;
}

@end

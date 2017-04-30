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

NSString * const OpenVPNAdapterErrorDomain = @"me.ss-abramchuk.openvpn-adapter.error-domain";

NSString * const OpenVPNAdapterErrorFatalKey = @"me.ss-abramchuk.openvpn-adapter.error-key.fatal";
NSString * const OpenVPNAdapterErrorEventKey = @"me.ss-abramchuk.openvpn-adapter.error-key.event";

@interface OpenVPNAdapter () {
    __weak id<OpenVPNAdapterDelegate> _delegate;
}

@property OpenVPNClient *vpnClient;

@property (weak, nonatomic) id<OpenVPNAdapterPacketFlow> packetFlow;

- (NSString *)getSubnetFromPrefixLength:(NSNumber *)prefixLength;

@end

@implementation OpenVPNAdapter (Internal)

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
    
    if ([self.delegate respondsToSelector:@selector(handleLog:)]) {
        NSString *message = [NSString stringWithCString:log->text.c_str() encoding:NSUTF8StringEncoding];
        [self.delegate handleLog:message];
    }
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
    // TODO: Describe why we use async invocation here
    dispatch_queue_t connectQueue = dispatch_queue_create("me.ss-abramchuk.openvpn-adapter.connection", NULL);
    dispatch_async(connectQueue, ^{
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
        _delegate = nil;
        self.vpnClient = new OpenVPNClient((__bridge void *)self);
    }
    return self;
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

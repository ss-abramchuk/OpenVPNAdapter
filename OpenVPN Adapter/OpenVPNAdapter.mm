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

@property (weak, nonatomic) id<OpenVPNAdapterPacketFlow> packetFlow;

- (NSString *)getSubnetFromPrefixLength:(NSNumber *)prefixLength;

@end

@implementation OpenVPNAdapter (Client)

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

#pragma mark Properties

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
            NSLocalizedDescriptionKey: @"Failed to read OpenVPN configuration file"
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
    creds.username = self.username == nil ? "" : [self.username UTF8String];
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
        _username = nil;
        _password = nil;
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

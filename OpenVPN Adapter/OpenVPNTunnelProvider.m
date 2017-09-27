//
//  OpenVPNTunnelProvider.m
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 26/09/2017.
//

#import "OpenVPNTunnelProvider.h"

#import "OpenVPNAdapter.h"
#import "OpenVPNAdapter+Public.h"
#import "OpenVPNConfiguration.h"
#import "OpenVPNCredentials.h"
#import "OpenVPNError.h"
#import "OpenVPNProperties.h"
#import "OpenVPNReachability.h"

NSString * const OpenVPNTunnelProviderConfigurationKey = @"OpenVPNTunnelProviderConfigurationKey";

@interface NEPacketTunnelFlow () <OpenVPNAdapterPacketFlow>
@end

@interface OpenVPNTunnelProvider () <OpenVPNAdapterDelegate>
@property (nonatomic, copy) void (^startCompletionHandler)(NSError *);
@property (nonatomic, copy) void (^stopCompletionHandler)(void);
@property (nonatomic) OpenVPNAdapter *adapter;
@property (nonatomic) OpenVPNReachability *reachability;
@end

@implementation OpenVPNTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary<NSString *,NSObject *> *)options completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    NSError *error;
    
    if (!self.configuration) {
        completionHandler([NSError errorWithDomain:NEVPNErrorDomain code:NEVPNErrorConfigurationInvalid userInfo:nil]);
        return;
    }
    
    OpenVPNProperties *properties = [self.adapter applyConfiguration:self.configuration error:&error];
    
    if (!properties) {
        completionHandler(error);
        return;
    }
    
    if (!properties.autologin) {
        if (!self.credentials) {
            completionHandler([NSError errorWithDomain:NEVPNErrorDomain code:NEVPNErrorConfigurationInvalid userInfo:nil]);
            return;
        } else if (![self.adapter provideCredentials:self.credentials error:&error]) {
            completionHandler(error);
            return;
        }
    }
    
    self.startCompletionHandler = completionHandler;
    
    __weak typeof(self) weakSelf = self;
    [self.reachability startTrackingWithCallback:^(OpenVPNReachabilityStatus status) {
        typeof(self) strongSelf = weakSelf;
        if (status != OpenVPNReachabilityStatusNotReachable) {
            [strongSelf.adapter reconnectAfterTimeInterval:0];
        }
    }];
    
    [self.adapter connect];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    self.stopCompletionHandler = completionHandler;
    [self.adapter disconnect];
}

- (void)configureTunnelWithSettings:(NEPacketTunnelNetworkSettings *)settings callback:(void (^)(id<OpenVPNAdapterPacketFlow> _Nullable))callback {
    __weak typeof(self) weakSelf = self;
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        callback(!error ? strongSelf.packetFlow : nil);
    }];
}

- (void)handleEvent:(OpenVPNAdapterEvent)event message:(nullable NSString *)message {
    switch (event) {
        case OpenVPNAdapterEventConnected:
            self.reasserting = NO;
            if (self.startCompletionHandler) self.startCompletionHandler(nil);
            self.startCompletionHandler = nil;
            break;
        case OpenVPNAdapterEventReconnecting:
            self.reasserting = YES;
            break;
        case OpenVPNAdapterEventDisconnected:
            if (self.stopCompletionHandler) self.stopCompletionHandler();
            self.stopCompletionHandler = nil;
            break;
        default:
            break;
    }
}

- (void)handleError:(nonnull NSError *)error {
    id isFatal = error.userInfo[OpenVPNAdapterErrorFatalKey];
    if (!([isFatal respondsToSelector:@selector(boolValue)] && [isFatal boolValue])) {
        return;
    }
    if (self.startCompletionHandler) {
        self.startCompletionHandler(error);
        self.startCompletionHandler = nil;
    } else {
        [self cancelTunnelWithError:error];
    }
}

- (OpenVPNConfiguration *)configuration {
    if (![self.protocolConfiguration isKindOfClass:[NETunnelProviderProtocol class]]) return nil;
    id configurationData = ((NETunnelProviderProtocol *)self.protocolConfiguration).providerConfiguration[OpenVPNTunnelProviderConfigurationKey];
    if (![configurationData isKindOfClass:[NSData class]]) return nil;
    id configuration = [NSKeyedUnarchiver unarchiveObjectWithData:configurationData];
    if (![configuration isKindOfClass:[OpenVPNConfiguration class]]) return nil;
    return configuration;
}

- (OpenVPNCredentials *)credentials {
    if (!self.protocolConfiguration.username.length) return nil;
    if (!self.protocolConfiguration.passwordReference) return nil;
    
    CFTypeRef reference;
    NSDictionary *query = @{(id)kSecClass: (id)kSecClassGenericPassword,
                            (id)kSecReturnData: (id)kCFBooleanTrue,
                            (id)kSecValuePersistentRef: self.protocolConfiguration.passwordReference};
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &reference) != errSecSuccess) return nil;
    
    NSString *password = [[NSString alloc] initWithData:(__bridge NSData *)reference encoding:NSUTF8StringEncoding];
    if (!password.length) return nil;
    
    OpenVPNCredentials *credentials = [[OpenVPNCredentials alloc] init];
    credentials.username = self.protocolConfiguration.username;
    credentials.password = password;
    return credentials;
}

- (OpenVPNAdapter *)adapter {
    if (!_adapter) {
        _adapter = [[OpenVPNAdapter alloc] init];
        _adapter.delegate = self;
    }
    return _adapter;
}

- (OpenVPNReachability *)reachability {
    if (!_reachability) {
        _reachability = [[OpenVPNReachability alloc] init];
    }
    return _reachability;
}

@end

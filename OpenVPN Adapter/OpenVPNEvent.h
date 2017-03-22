//
//  ClientEvent.h
//  OpenVPN NEF Test
//
//  Created by Sergey Abramchuk on 05.11.16.
//  Copyright © 2016 ss-abramchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 <#Description#>

 - OpenVPNEventDisconnected: <#OpenVPNEventDisconnected description#>
 - OpenVPNEventConnected: <#OpenVPNEventConnected description#>
 - OpenVPNEventReconnecting: <#OpenVPNEventReconnecting description#>
 - OpenVPNEventResolve: <#OpenVPNEventResolve description#>
 - OpenVPNEventWait: <#OpenVPNEventWait description#>
 - OpenVPNEventWaitProxy: <#OpenVPNEventWaitProxy description#>
 - OpenVPNEventConnecting: <#OpenVPNEventConnecting description#>
 - OpenVPNEventGetConfig: <#OpenVPNEventGetConfig description#>
 - OpenVPNEventAssignIP: <#OpenVPNEventAssignIP description#>
 - OpenVPNEventAddRoutes: <#OpenVPNEventAddRoutes description#>
 - OpenVPNEventEcho: <#OpenVPNEventEcho description#>
 - OpenVPNEventInfo: <#OpenVPNEventInfo description#>
 - OpenVPNEventPause: <#OpenVPNEventPause description#>
 - OpenVPNEventResume: <#OpenVPNEventResume description#>
 - OpenVPNEventTransportError: <#OpenVPNEventTransportError description#>
 - OpenVPNEventTunError: <#OpenVPNEventTunError description#>
 - OpenVPNEventClientRestart: <#OpenVPNEventClientRestart description#>
 - OpenVPNEventAuthFailed: <#OpenVPNEventAuthFailed description#>
 - OpenVPNEventCertVerifyFail: <#OpenVPNEventCertVerifyFail description#>
 - OpenVPNEventTLSVersionMin: <#OpenVPNEventTLSVersionMin description#>
 - OpenVPNEventClientHalt: <#OpenVPNEventClientHalt description#>
 - OpenVPNEventConnectionTimeout: <#OpenVPNEventConnectionTimeout description#>
 - OpenVPNEventInactiveTimeout: <#OpenVPNEventInactiveTimeout description#>
 - OpenVPNEventDynamicChallenge: <#OpenVPNEventDynamicChallenge description#>
 - OpenVPNEventProxyNeedCreds: <#OpenVPNEventProxyNeedCreds description#>
 - OpenVPNEventProxyError: <#OpenVPNEventProxyError description#>
 - OpenVPNEventTunSetupFailed: <#OpenVPNEventTunSetupFailed description#>
 - OpenVPNEventTunIfaceCreate: <#OpenVPNEventTunIfaceCreate description#>
 - OpenVPNEventTunIfaceDisabled: <#OpenVPNEventTunIfaceDisabled description#>
 - OpenVPNEventEPKIError: <#OpenVPNEventEPKIError description#>
 - OpenVPNEventEPKIInvalidAlias: <#OpenVPNEventEPKIInvalidAlias description#>
 - OpenVPNEventInitializationFailed: <#OpenVPNEventInitializationFailed description#>
 - OpenVPNEventConnectionFailed: <#OpenVPNEventConnectionFailed description#>
 - OpenVPNEventUnknown: <#OpenVPNEventUnknown description#>
 */
typedef NS_ENUM(NSUInteger, OpenVPNEvent) {
    OpenVPNEventDisconnected,
    OpenVPNEventConnected,
    OpenVPNEventReconnecting,
    OpenVPNEventResolve,
    OpenVPNEventWait,
    OpenVPNEventWaitProxy,
    OpenVPNEventConnecting,
    OpenVPNEventGetConfig,
    OpenVPNEventAssignIP,
    OpenVPNEventAddRoutes,
    OpenVPNEventEcho,
    OpenVPNEventInfo,
    OpenVPNEventPause,
    OpenVPNEventResume,
    OpenVPNEventTransportError,
    OpenVPNEventTunError,
    OpenVPNEventClientRestart,
    OpenVPNEventAuthFailed,
    OpenVPNEventCertVerifyFail,
    OpenVPNEventTLSVersionMin,
    OpenVPNEventClientHalt,
    OpenVPNEventConnectionTimeout,
    OpenVPNEventInactiveTimeout,
    OpenVPNEventDynamicChallenge,
    OpenVPNEventProxyNeedCreds,
    OpenVPNEventProxyError,
    OpenVPNEventTunSetupFailed,
    OpenVPNEventTunIfaceCreate,
    OpenVPNEventTunIfaceDisabled,
    OpenVPNEventEPKIError,
    OpenVPNEventEPKIInvalidAlias,
    OpenVPNEventInitializationFailed,
    OpenVPNEventConnectionFailed,
    OpenVPNEventUnknown
};

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
    OpenVPNEventRelay,
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
    OpenVPNEventRelayError,
    OpenVPNEventInitializationFailed,
    OpenVPNEventConnectionFailed,
    OpenVPNEventUnknown
};

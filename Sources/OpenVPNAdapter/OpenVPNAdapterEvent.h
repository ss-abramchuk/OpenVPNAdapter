//
//  OpenVPNAdapterEvent.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 05.11.16.
//  Copyright © 2016 ss-abramchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 OpenVPN event codes
 */
typedef NS_ENUM(NSInteger, OpenVPNAdapterEvent) {
    OpenVPNAdapterEventDisconnected,
    OpenVPNAdapterEventConnected,
    OpenVPNAdapterEventReconnecting,
    OpenVPNAdapterEventAuthPending,
    OpenVPNAdapterEventResolve,
    OpenVPNAdapterEventWait,
    OpenVPNAdapterEventWaitProxy,
    OpenVPNAdapterEventConnecting,
    OpenVPNAdapterEventGetConfig,
    OpenVPNAdapterEventAssignIP,
    OpenVPNAdapterEventAddRoutes,
    OpenVPNAdapterEventEcho,
    OpenVPNAdapterEventInfo,
    OpenVPNAdapterEventWarn,
    OpenVPNAdapterEventPause,
    OpenVPNAdapterEventResume,
    OpenVPNAdapterEventRelay,
    OpenVPNAdapterEventCompressionEnabled,
    OpenVPNAdapterEventUnsupportedFeature,
    OpenVPNAdapterEventUnknown
};

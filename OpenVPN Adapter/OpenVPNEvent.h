//
//  ClientEvent.h
//  OpenVPN NEF Test
//
//  Created by Sergey Abramchuk on 05.11.16.
//  Copyright © 2016 ss-abramchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 OpenVPN event codes
 */
typedef NS_ENUM(NSInteger, OpenVPNEvent) {
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
    OpenVPNEventUnknown
};

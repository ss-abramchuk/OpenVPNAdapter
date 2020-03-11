//
//  OpenVPNReachabilityStatus.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNReachabilityStatus) {
    OpenVPNReachabilityStatusNotReachable,
    OpenVPNReachabilityStatusReachableViaWiFi,
    OpenVPNReachabilityStatusReachableViaWWAN
};

//
//  OpenVPNIPv6Preference.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 IPv6 preference options
 */
typedef NS_ENUM(NSInteger, OpenVPNIPv6Preference) {
    /// Request combined IPv4/IPv6 tunnel
    OpenVPNIPv6PreferenceEnabled,
    /// Disable IPv6, so tunnel will be IPv4-only
    OpenVPNIPv6PreferenceDisabled,
    /// Leave decision to server
    OpenVPNIPv6PreferenceDefault
};

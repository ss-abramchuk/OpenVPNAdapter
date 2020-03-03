//
//  OpenVPNMinTLSVersion.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Minimum TLS version options
 */
typedef NS_ENUM(NSInteger, OpenVPNMinTLSVersion) {
    /// Don't specify a minimum, and disable any minimum specified in profile
    OpenVPNMinTLSVersionDisabled,
    /// Use TLS 1.0 minimum (overrides profile)
    OpenVPNMinTLSVersion10,
    /// Use TLS 1.1 minimum (overrides profile)
    OpenVPNMinTLSVersion11,
    /// Use TLS 1.2 minimum (overrides profile)
    OpenVPNMinTLSVersion12,
    /// Use profile minimum
    OpenVPNMinTLSVersionDefault
};

//
//  OpenVPNTLSCertProfile.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Options of the tls-cert-profile setting
 */
typedef NS_ENUM(NSInteger, OpenVPNTLSCertProfile) {
    /// Allow 1024-bit RSA certs signed with SHA1
    OpenVPNTLSCertProfileLegacy,
    /// Require at least 2048-bit RSA certs signed with SHA256 or higher
    OpenVPNTLSCertProfilePreferred,
    /// Require NSA Suite-B
    OpenVPNTLSCertProfileSuiteB,
    /// Use legacy as the default if profile doesn't specify tls-cert-profile
    OpenVPNTLSCertProfileLegacyDefault,
    /// Use preferred as the default if profile doesn't specify tls-cert-profile
    OpenVPNTLSCertProfilePreferredDefault,
    /// Use profile default
    OpenVPNTLSCertProfileDefault
};

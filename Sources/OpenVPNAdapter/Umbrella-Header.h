//
//  OpenVPNAdapter.h
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 09.03.17.
//
//

@import Foundation;

//! Project version number for OpenVPNAdapter.
FOUNDATION_EXPORT double OpenVPNAdapterVersionNumber;

//! Project version string for OpenVPNAdapter.
FOUNDATION_EXPORT const unsigned char OpenVPNAdapterVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OpenVPNAdapter/PublicHeader.h>

#import <OpenVPNAdapter/OpenVPNError.h>
#import <OpenVPNAdapter/OpenVPNAdapterEvent.h>
#import <OpenVPNAdapter/OpenVPNTransportProtocol.h>
#import <OpenVPNAdapter/OpenVPNIPv6Preference.h>
#import <OpenVPNAdapter/OpenVPNCompressionMode.h>
#import <OpenVPNAdapter/OpenVPNMinTLSVersion.h>
#import <OpenVPNAdapter/OpenVPNTLSCertProfile.h>
#import <OpenVPNAdapter/OpenVPNConfiguration.h>
#import <OpenVPNAdapter/OpenVPNCredentials.h>
#import <OpenVPNAdapter/OpenVPNServerEntry.h>
#import <OpenVPNAdapter/OpenVPNConfigurationEvaluation.h>
#import <OpenVPNAdapter/OpenVPNConnectionInfo.h>
#import <OpenVPNAdapter/OpenVPNSessionToken.h>
#import <OpenVPNAdapter/OpenVPNTransportStats.h>
#import <OpenVPNAdapter/OpenVPNInterfaceStats.h>
#import <OpenVPNAdapter/OpenVPNAdapterImpl.h>
#import <OpenVPNAdapter/OpenVPNAdapterPacketFlow.h>
#import <OpenVPNAdapter/OpenVPNKeyType.h>
#import <OpenVPNAdapter/OpenVPNCertificate.h>
#import <OpenVPNAdapter/OpenVPNPrivateKey.h>
#import <OpenVPNAdapter/OpenVPNReachabilityStatus.h>
#import <OpenVPNAdapter/OpenVPNReachability.h>

//
//  OpenVPNAdapter.h
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 09.03.17.
//
//
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@import UIKit;
#else
@import AppKit;
#endif

//! Project version number for OpenVPNAdapter.
FOUNDATION_EXPORT double OpenVPNAdapterVersionNumber;

//! Project version string for OpenVPNAdapter.
FOUNDATION_EXPORT const unsigned char OpenVPNAdapterVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OpenVPNAdapter/PublicHeader.h>

#import <OpenVPNAdapter/OpenVPNError.h>
#import <OpenVPNAdapter/OpenVPNEvent.h>
#import <OpenVPNAdapter/OpenVPNAdapter.h>
#import <OpenVPNAdapter/OpenVPNAdapter+Public.h>

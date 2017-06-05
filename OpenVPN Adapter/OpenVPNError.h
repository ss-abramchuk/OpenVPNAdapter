//
//  OpenVPNError.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorDomain;

FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorFatalKey;
FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorEventIdentifierKey;

/**
 <#Description#>
 */
typedef NS_ENUM(NSUInteger, OpenVPNError) {
    OpenVPNErrorConfigurationFailure,
    OpenVPNErrorClientFailure
};

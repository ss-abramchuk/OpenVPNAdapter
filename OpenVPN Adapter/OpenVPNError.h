//
//  OpenVPNError.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const OpenVPNAdapterErrorDomain;

extern NSString * __nonnull const OpenVPNAdapterErrorFatalKey;
extern NSString * __nonnull const OpenVPNAdapterErrorEventIdentifierKey;

/**
 <#Description#>
 */
typedef NS_ENUM(NSUInteger, OpenVPNError) {
    OpenVPNErrorConfigurationFailure,
    OpenVPNErrorClientFailure
};

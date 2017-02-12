//
//  OpenVPNError.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const OpenVPNClientErrorDomain;

extern NSString *__nonnull const OpenVPNClientErrorFatalKey;
extern NSString *__nonnull const OpenVPNClientErrorEventKey;

typedef NS_ENUM(NSUInteger, OpenVPNError) {
    OpenVPNErrorConfigurationFailure,
    OpenVPNErrorClientFailure
};

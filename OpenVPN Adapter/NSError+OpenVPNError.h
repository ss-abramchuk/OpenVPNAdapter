//
//  NSError+OpenVPNError.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.01.2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const OpenVPNAdapterErrorDomain;

typedef NS_ERROR_ENUM(OpenVPNAdapterErrorDomain, OpenVPNAdapterError);

@interface NSError (OpenVPNAdapterErrorGeneration)

+ (NSError *)ovpn_errorObjectForAdapterError:(OpenVPNAdapterError)adapterError
                                 description:(NSString *)description
                                     message:(nullable NSString *)message
                                       fatal:(BOOL)fatal;

+ (OpenVPNAdapterError)ovpn_adapterErrorByName:(NSString *)errorName;

@end

@interface NSError (OpenVPNMbedTLSErrorGeneration)

+ (NSError *)ovpn_errorObjectForMbedTLSError:(NSInteger)errorCode description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END

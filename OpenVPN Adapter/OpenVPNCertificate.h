//
//  OpenVPNCertificate.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//

#import <Foundation/Foundation.h>

@interface OpenVPNCertificate : NSObject

+ (nullable OpenVPNCertificate *)certificateWithPEM:(nonnull NSData *)pemData
                                              error:(out NSError * _Nullable * _Nullable)error;

+ (nullable OpenVPNCertificate *)certificateWithDER:(nonnull NSData *)derData
                                              error:(out NSError * _Nullable * _Nullable)error;

- (nonnull instancetype) init NS_UNAVAILABLE;

- (nullable NSData *)pemData:(out NSError * _Nullable * _Nullable)error;
- (nullable NSData *)derData:(out NSError * _Nullable * _Nullable)error;

@end

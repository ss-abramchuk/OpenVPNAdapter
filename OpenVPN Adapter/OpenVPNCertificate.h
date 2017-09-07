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
                                              error:(out NSError * __nullable * __nullable)error;

+ (nullable OpenVPNCertificate *)certificateWithDER:(nonnull NSData *)derData
                                              error:(out NSError * __nullable * __nullable)error;

- (nonnull instancetype) __unavailable init;

- (nullable NSData *)pemData:(out NSError * __nullable * __nullable)error;
- (nullable NSData *)derData:(out NSError * __nullable * __nullable)error;

@end

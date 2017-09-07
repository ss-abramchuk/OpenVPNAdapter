//
//  OpenVPNPrivateKey.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

#import <Foundation/Foundation.h>

@interface OpenVPNPrivateKey : NSObject

+ (nullable OpenVPNPrivateKey *)keyWithPEM:(nonnull NSData *)pemData
                                  password:(nullable NSString *)password
                                     error:(out NSError * __nullable * __nullable)error;

+ (nullable OpenVPNPrivateKey *)keyWithDER:(nonnull NSData *)derData
                                  password:(nullable NSString *)password
                                     error:(out NSError * __nullable * __nullable)error;

- (nonnull instancetype) __unavailable init;

- (nullable NSData *)pemData:(out NSError * __nullable * __nullable)error;
- (nullable NSData *)derData:(out NSError * __nullable * __nullable)error;

@end

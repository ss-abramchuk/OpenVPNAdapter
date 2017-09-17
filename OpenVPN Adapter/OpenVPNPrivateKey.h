//
//  OpenVPNPrivateKey.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

#import <Foundation/Foundation.h>

#import "OpenVPNKeyType.h"

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNPrivateKey : NSObject

+ (nullable OpenVPNPrivateKey *)keyWithPEM:(NSData *)pemData
                                  password:(nullable NSString *)password
                                     error:(out NSError * __nullable * __nullable)error;

+ (nullable OpenVPNPrivateKey *)keyWithDER:(NSData *)derData
                                  password:(nullable NSString *)password
                                     error:(out NSError * __nullable * __nullable)error;

- (instancetype) __unavailable init;

@property (nonatomic, readonly) NSInteger size;
@property (nonatomic, readonly) OpenVPNKeyType type;

- (nullable NSData *)pemData:(out NSError * __nullable * __nullable)error;
- (nullable NSData *)derData:(out NSError * __nullable * __nullable)error;

@end

NS_ASSUME_NONNULL_END

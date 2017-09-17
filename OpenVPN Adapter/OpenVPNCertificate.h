//
//  OpenVPNCertificate.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNCertificate : NSObject

+ (nullable OpenVPNCertificate *)certificateWithPEM:(NSData *)pemData
                                              error:(out NSError * _Nullable * _Nullable)error;

+ (nullable OpenVPNCertificate *)certificateWithDER:(NSData *)derData
                                              error:(out NSError * _Nullable * _Nullable)error;

- (instancetype) __unavailable init;

- (nullable NSData *)pemData:(out NSError * _Nullable * _Nullable)error;
- (nullable NSData *)derData:(out NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

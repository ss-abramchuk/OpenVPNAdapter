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
                                     error:(out NSError * _Nullable * _Nullable)error;

+ (nullable OpenVPNPrivateKey *)keyWithDER:(NSData *)derData
                                  password:(nullable NSString *)password
                                     error:(out NSError * _Nullable * _Nullable)error;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) NSInteger size;
@property (nonatomic, readonly) OpenVPNKeyType type;

- (nullable NSData *)pemData:(out NSError * _Nullable * _Nullable)error;
- (nullable NSData *)derData:(out NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

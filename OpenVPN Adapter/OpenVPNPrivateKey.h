//
//  OpenVPNPrivateKey.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNKeyType);

@interface OpenVPNPrivateKey : NSObject

+ (nullable OpenVPNPrivateKey *)keyWithPEM:(nonnull NSData *)pemData
                                  password:(nullable NSString *)password
                                     error:(out NSError * _Nullable * _Nullable)error;

+ (nullable OpenVPNPrivateKey *)keyWithDER:(nonnull NSData *)derData
                                  password:(nullable NSString *)password
                                     error:(out NSError * _Nullable * _Nullable)error;

- (nonnull instancetype) init NS_UNAVAILABLE;

@property (nonatomic, readonly) NSInteger size;
@property (nonatomic, readonly) OpenVPNKeyType type;

- (nullable NSData *)pemData:(out NSError * _Nullable * _Nullable)error;
- (nullable NSData *)derData:(out NSError * _Nullable * _Nullable)error;

@end

//
//  OpenVPNPrivateKey.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNKeyType);

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNPrivateKey : NSObject

+ (nullable OpenVPNPrivateKey *)keyWithPEM:(NSData *)pemData
                                  password:(nullable NSString *)password
                                     error:(NSError **)error;

+ (nullable OpenVPNPrivateKey *)keyWithDER:(NSData *)derData
                                  password:(nullable NSString *)password
                                     error:(NSError **)error;

- (instancetype) init NS_UNAVAILABLE;

@property (nonatomic, readonly) NSInteger size;
@property (nonatomic, readonly) OpenVPNKeyType type;

- (nullable NSData *)pemData:(NSError **)error;
- (nullable NSData *)derData:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

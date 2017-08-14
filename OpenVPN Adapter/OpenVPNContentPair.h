//
//  OpenVPNContentPair.h
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 14/08/2017.
//

#import <Foundation/Foundation.h>

@interface OpenVPNContentPair : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly, nonnull, copy) NSString *key;

@property (nonatomic, readonly, nullable, copy) NSString *value;

- (nonnull instancetype)initWithKey:(nonnull NSString *)key;

- (nonnull instancetype)initWithKey:(nonnull NSString *)key value:(nullable NSString *)value;

@end

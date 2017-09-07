//
//  OpenVPNPrivateKey.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

#import <mbedtls/pk.h>

#import "NSError+Message.h"
#import "OpenVPNError.h"
#import "OpenVPNPrivateKey.h"

@interface OpenVPNPrivateKey ()

@property (nonatomic, assign) mbedtls_pk_context *ctx;

@end

@implementation OpenVPNPrivateKey

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ctx = malloc(sizeof(mbedtls_pk_context));
        mbedtls_pk_init(self.ctx);
    }
    return self;
}

- (NSInteger)size {
    return mbedtls_pk_get_bitlen(self.ctx);
}

- (OpenVPNKeyType)type {
    return (OpenVPNKeyType)mbedtls_pk_get_type(self.ctx);
}

+ (nullable OpenVPNPrivateKey *)keyWithPEM:(NSData *)pemData password:(NSString *)password error:(out NSError **)error {
    OpenVPNPrivateKey *key = [OpenVPNPrivateKey new];
    
    NSString *pemString = [[NSString alloc] initWithData:pemData encoding:NSUTF8StringEncoding];
    
    int result = mbedtls_pk_parse_key(key.ctx, (const unsigned char *)pemString.UTF8String, pemData.length + 1, (const unsigned char *)password.UTF8String, password.length + 1);
    if (result < 0) {
        if (error) {
            NSString *reason = [NSError reasonFromResult:result];
            *error = [NSError errorWithDomain:OpenVPNIdentityErrorDomain code:result userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to read PEM data.",
                NSLocalizedFailureReasonErrorKey: reason
            }];
        }
        
        return nil;
    }
    
    return key;
}

+ (nullable OpenVPNPrivateKey *)keyWithDER:(NSData *)derData password:(NSString *)password error:(out NSError **)error {
    OpenVPNPrivateKey *key = [OpenVPNPrivateKey new];
    
    int result = mbedtls_pk_parse_key(key.ctx, derData.bytes, derData.length, (const unsigned char *)password.UTF8String, password.length + 1);
    if (result < 0) {
        if (error) {
            NSString *reason = [NSError reasonFromResult:result];
            *error = [NSError errorWithDomain:OpenVPNIdentityErrorDomain code:result userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to read DER data.",
                NSLocalizedFailureReasonErrorKey: reason
            }];
        }
        
        return nil;
    }
    
    return key;
}

- (void)dealloc {
    mbedtls_pk_free(self.ctx);
    free(self.ctx);
}

@end

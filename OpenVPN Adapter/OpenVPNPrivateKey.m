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
    
    size_t pem_length = strlen(pemString.UTF8String) + 1;
    size_t password_length = password != nil ? strlen(password.UTF8String) : 0;
    
    int result = mbedtls_pk_parse_key(key.ctx, (const unsigned char *)pemString.UTF8String, pem_length, (const unsigned char *)password.UTF8String, password_length);
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
    
    size_t password_length = password != nil ? strlen(password.UTF8String) : 0;
    
    int result = mbedtls_pk_parse_key(key.ctx, derData.bytes, derData.length, (const unsigned char *)password.UTF8String, password_length);
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

- (NSData *)pemData:(out NSError **)error {
    size_t buffer_length = mbedtls_pk_get_len(self.ctx) * 10;
    unsigned char *pem_buffer = malloc(buffer_length);
    
    int result = mbedtls_pk_write_key_pem(self.ctx, pem_buffer, buffer_length);
    if (result < 0) {
        if (error) {
            NSString *reason = [NSError reasonFromResult:result];
            *error = [NSError errorWithDomain:OpenVPNIdentityErrorDomain code:result userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to write PEM data.",
                NSLocalizedFailureReasonErrorKey: reason
            }];
        }
        
        free(pem_buffer);
        return nil;
    }
    
    NSData *pemData = [[NSString stringWithCString:(const char *)pem_buffer encoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    
    free(pem_buffer);
    return pemData;
}

- (NSData *)derData:(out NSError **)error {
    size_t buffer_length = mbedtls_pk_get_len(self.ctx) * 10;
    unsigned char *der_buffer = malloc(buffer_length);
    
    int result = mbedtls_pk_write_key_der(self.ctx, der_buffer, buffer_length);
    if (result < 0) {
        if (error) {
            NSString *reason = [NSError reasonFromResult:result];
            *error = [NSError errorWithDomain:OpenVPNIdentityErrorDomain code:result userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to write DER data.",
                NSLocalizedFailureReasonErrorKey: reason
            }];
        }
        
        free(der_buffer);
        return nil;
    }
    
    NSUInteger location = buffer_length - result;
    NSRange range = NSMakeRange(location, result);
    
    NSData *derData = [[NSData dataWithBytes:der_buffer length:buffer_length] subdataWithRange:range];
    
    free(der_buffer);
    return derData;
}

- (void)dealloc {
    mbedtls_pk_free(self.ctx);
    free(self.ctx);
}

@end

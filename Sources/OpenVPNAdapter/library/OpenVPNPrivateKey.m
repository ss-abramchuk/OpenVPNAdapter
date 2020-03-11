//
//  OpenVPNPrivateKey.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

#import "OpenVPNPrivateKey.h"

#include <mbedtls/pk.h>

#import "OpenVPNKeyType.h"
#import "NSError+OpenVPNError.h"

@interface OpenVPNPrivateKey ()

@property (nonatomic, assign) mbedtls_pk_context *ctx;

@end

@implementation OpenVPNPrivateKey

+ (OpenVPNPrivateKey *)keyWithPEM:(NSData *)pemData password:(NSString *)password error:(NSError * __autoreleasing *)error {
    OpenVPNPrivateKey *key = [OpenVPNPrivateKey new];
    
    NSString *pemString = [[NSString alloc] initWithData:pemData encoding:NSUTF8StringEncoding];
    
    size_t pem_length = strlen(pemString.UTF8String) + 1;
    size_t password_length = password != nil ? strlen(password.UTF8String) : 0;
    
    int result = mbedtls_pk_parse_key(key.ctx, (const unsigned char *)pemString.UTF8String,
                                      pem_length, (const unsigned char *)password.UTF8String, password_length);
    
    if (result < 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:result description:@"Failed to read PEM data"];
        }
        
        return nil;
    }
    
    return key;
}

+ (OpenVPNPrivateKey *)keyWithDER:(NSData *)derData password:(NSString *)password error:(NSError * __autoreleasing *)error {
    OpenVPNPrivateKey *key = [OpenVPNPrivateKey new];
    
    size_t password_length = password != nil ? strlen(password.UTF8String) : 0;
    
    int result = mbedtls_pk_parse_key(key.ctx, derData.bytes,
                                      derData.length, (const unsigned char *)password.UTF8String, password_length);
    
    if (result < 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:result description:@"Failed to read DER data"];
        }
        
        return nil;
    }
    
    return key;
}

- (instancetype)init {
    if (self = [super init]) {
        _ctx = malloc(sizeof(mbedtls_pk_context));
        mbedtls_pk_init(_ctx);
    }
    return self;
}

- (NSInteger)size {
    return mbedtls_pk_get_bitlen(self.ctx);
}

- (OpenVPNKeyType)type {
    return (OpenVPNKeyType)mbedtls_pk_get_type(self.ctx);
}

- (NSData *)pemData:(NSError * __autoreleasing *)error {
    size_t buffer_length = mbedtls_pk_get_len(self.ctx) * 10;
    unsigned char *pem_buffer = malloc(buffer_length);
    
    int result = mbedtls_pk_write_key_pem(self.ctx, pem_buffer, buffer_length);
    if (result < 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:result description:@"Failed to write PEM data"];
        }
        
        free(pem_buffer);
        return nil;
    }
    
    NSData *pemData = [[NSString stringWithCString:(const char *)pem_buffer
                                          encoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    
    free(pem_buffer);
    return pemData;
}

- (NSData *)derData:(NSError * __autoreleasing *)error {
    size_t buffer_length = mbedtls_pk_get_len(self.ctx) * 10;
    unsigned char *der_buffer = malloc(buffer_length);
    
    int result = mbedtls_pk_write_key_der(self.ctx, der_buffer, buffer_length);
    if (result < 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:result description:@"Failed to write DER data"];
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
    mbedtls_pk_free(_ctx);
    free(_ctx);
}

@end

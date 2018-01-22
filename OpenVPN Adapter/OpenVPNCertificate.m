//
//  OpenVPNCertificate.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//
#import "OpenVPNCertificate.h"

#include <mbedtls/x509_crt.h>
#include <mbedtls/pem.h>

#import "NSError+OpenVPNError.h"

@interface OpenVPNCertificate ()

@property (nonatomic, assign) mbedtls_x509_crt *crt;

@end

@implementation OpenVPNCertificate

+ (OpenVPNCertificate *)certificateWithPEM:(NSData *)pemData error:(out NSError **)error {
    OpenVPNCertificate *certificate = [OpenVPNCertificate new];
    
    NSString *pemString = [[NSString alloc] initWithData:pemData encoding:NSUTF8StringEncoding];
    
    int result = mbedtls_x509_crt_parse(certificate.crt, (const unsigned char *)pemString.UTF8String, pemData.length + 1);
    if (result < 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:result description:@"Failed to read PEM data"];
        }
        
        return nil;
    }
    
    return certificate;
}

+ (OpenVPNCertificate *)certificateWithDER:(NSData *)derData error:(out NSError **)error {
    OpenVPNCertificate *certificate = [OpenVPNCertificate new];
    
    int result = mbedtls_x509_crt_parse_der(certificate.crt, derData.bytes, derData.length);
    if (result < 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:result description:@"Failed to read DER data"];
        }
        
        return nil;
    }
    
    return certificate;
}

- (instancetype)init
{
    if (self = [super init]) {
        _crt = malloc(sizeof(mbedtls_x509_crt));
        mbedtls_x509_crt_init(_crt);
    }
    return self;
}

- (NSData *)pemData:(out NSError **)error {
    NSString *header = @"-----BEGIN CERTIFICATE-----\n";
    NSString *footer = @"-----END CERTIFICATE-----\n";
    
    size_t buffer_length = self.crt->raw.len * 10;
    unsigned char *pem_buffer = malloc(buffer_length);
    
    size_t output_length = 0;
    
    int result = mbedtls_pem_write_buffer(header.UTF8String, footer.UTF8String, self.crt->raw.p,
                                          self.crt->raw.len, pem_buffer, buffer_length, &output_length);
    if (result < 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:result description: @"Failed to write PEM data"];
        }
        
        free(pem_buffer);
        return nil;
    }
    
    NSData *pemData = [NSData dataWithBytes:pem_buffer length:output_length - 1];
    
    free(pem_buffer);    
    return pemData;
}

- (NSData *)derData:(out NSError **)error {
    if (self.crt->raw.p == NULL || self.crt->raw.len == 0) {
        if (error) {
            *error = [NSError ovpn_errorObjectForMbedTLSError:MBEDTLS_ERR_X509_BAD_INPUT_DATA
                                                  description: @"Failed to write DER data"];
        }
        
        return nil;
    }
    
    return [NSData dataWithBytes:self.crt->raw.p length:self.crt->raw.len];
}

- (void)dealloc {
    mbedtls_x509_crt_free(_crt);
    free(_crt);
}

@end

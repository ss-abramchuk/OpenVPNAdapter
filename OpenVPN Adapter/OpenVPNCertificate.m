//
//  OpenVPNCertificate.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//

#import <mbedtls/x509_crt.h>
#import <mbedtls/pem.h>

#import "NSError+Message.h"
#import "OpenVPNError.h"
#import "OpenVPNCertificate.h"

@interface OpenVPNCertificate ()

@property (nonatomic, assign) mbedtls_x509_crt *crt;

@end

@implementation OpenVPNCertificate

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.crt = malloc(sizeof(mbedtls_x509_crt));
        mbedtls_x509_crt_init(self.crt);
    }
    return self;
}

+ (OpenVPNCertificate *)certificateWithPEM:(NSData *)pemData error:(out NSError **)error {
    OpenVPNCertificate *certificate = [OpenVPNCertificate new];
    
    NSString *pemString = [[NSString alloc] initWithData:pemData encoding:NSUTF8StringEncoding];
    
    int result = mbedtls_x509_crt_parse(certificate.crt, (const unsigned char *)pemString.UTF8String, pemData.length + 1);
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
    
    return certificate;
}

+ (OpenVPNCertificate *)certificateWithDER:(NSData *)derData error:(out NSError **)error {
    OpenVPNCertificate *certificate = [OpenVPNCertificate new];
    
    int result = mbedtls_x509_crt_parse_der(certificate.crt, derData.bytes, derData.length);
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
    
    return certificate;
}

- (NSData *)pemData:(out NSError **)error {
    NSString *header = @"-----BEGIN CERTIFICATE-----\n";
    NSString *footer = @"-----END CERTIFICATE-----\n";
    
    size_t buffer_length = self.crt->raw.len * 10;
    unsigned char *pem_buffer = malloc(buffer_length);
    
    size_t output_length = 0;
    
    int result = mbedtls_pem_write_buffer(header.UTF8String, footer.UTF8String, self.crt->raw.p, self.crt->raw.len, pem_buffer, buffer_length, &output_length);
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
    
    NSData *pemData = [NSData dataWithBytes:pem_buffer length:output_length - 1];
    
    free(pem_buffer);    
    return pemData;
}

- (NSData *)derData:(out NSError **)error {
    if (self.crt->raw.p == NULL || self.crt->raw.len == 0) {
        if (error) {
            NSString *reason = [NSError reasonFromResult:MBEDTLS_ERR_X509_BAD_INPUT_DATA];
            *error = [NSError errorWithDomain:OpenVPNIdentityErrorDomain code:MBEDTLS_ERR_X509_BAD_INPUT_DATA userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to write DER data.",
                NSLocalizedFailureReasonErrorKey:reason
            }];
        }
        
        return nil;
    }
    
    return [NSData dataWithBytes:self.crt->raw.p length:self.crt->raw.len];
}

- (void)dealloc {
    mbedtls_x509_crt_free(self.crt);
    free(self.crt);
}

@end

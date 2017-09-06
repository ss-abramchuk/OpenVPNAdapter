//
//  OpenVPNCertificate.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//

#import <mbedtls/x509_crt.h>

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

+ (OpenVPNCertificate *)certificateWithPEM:(NSData *)pemData error:(out NSError * __nullable * __nullable)error {
    OpenVPNCertificate *certificate = [OpenVPNCertificate new];
    
    NSString *pemString = [[NSString alloc] initWithData:pemData encoding:NSUTF8StringEncoding];
    
    int result = mbedtls_x509_crt_parse(certificate.crt, (const unsigned char *)pemString.UTF8String, pemData.length + 1);
    if (result != 0) {
        if (error) {
            // TODO: Return parse error
        }
        
        return nil;
    }
    
    return certificate;
}

+ (OpenVPNCertificate *)certificateWithDER:(NSData *)derData error:(out NSError * __nullable * __nullable)error {
    OpenVPNCertificate *certificate = [OpenVPNCertificate new];
    
    int result = mbedtls_x509_crt_parse_der(certificate.crt, derData.bytes, derData.length);
    if (result != 0) {
        if (error) {
            // TODO: Return parse error
        }
        
        return nil;
    }
    
    return certificate;
}

- (void)dealloc {
    if (self.crt) {
        mbedtls_x509_crt_free(self.crt);
        free(self.crt);
    }
}

@end

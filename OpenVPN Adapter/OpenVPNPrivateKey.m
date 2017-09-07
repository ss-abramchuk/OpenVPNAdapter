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

@property (nonatomic, assign) mbedtls_pk_context *key;

@end

@implementation OpenVPNPrivateKey

- (instancetype)init {
    self = [super init];
    if (self) {
        self.key = malloc(sizeof(mbedtls_pk_context));
        mbedtls_pk_init(self.key);
    }
    return self;
}

+ (nullable OpenVPNPrivateKey *)keyWithPEM:(NSData *)pemData password:(NSString *)password error:(out NSError **)error {
    OpenVPNPrivateKey *key = [OpenVPNPrivateKey new];
    
    return key;
}

+ (nullable OpenVPNPrivateKey *)keyWithDER:(NSData *)derData password:(NSString *)password error:(out NSError **)error {
    OpenVPNPrivateKey *key = [OpenVPNPrivateKey new];
    
    return key;
}

- (void)dealloc {
    mbedtls_pk_free(self.key);
    free(self.key);
}

@end

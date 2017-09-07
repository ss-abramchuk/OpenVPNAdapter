//
//  NSError+Message.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//

#import <mbedtls/error.h>

#import "NSError+Message.h"

@implementation NSError (Message)

+ (NSString *)reasonFromResult:(NSInteger)result {
    size_t length = 1024;
    char *buffer = malloc(length);
    
    mbedtls_strerror(result, buffer, length);
    
    NSString *reason = [NSString stringWithUTF8String:buffer];
    
    free(buffer);
    
    return reason;
}

@end

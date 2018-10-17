//
//  NSSet+OpenVPNAdditions.m
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 16/10/2018.
//

#import "NSSet+OpenVPNAdditions.h"

@implementation NSSet (OpenVPNEmptySet)

- (BOOL)ovpn_isNotEmpty {
    return (self.count > 0) ? YES : NO;
}

@end

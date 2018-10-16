//
//  NSSet+Empty.m
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 16/10/2018.
//

#import "NSSet+Empty.h"

@implementation NSSet (Empty)

- (BOOL)isNotEmpty {
    return (self.count > 0) ? YES : NO;
}

@end

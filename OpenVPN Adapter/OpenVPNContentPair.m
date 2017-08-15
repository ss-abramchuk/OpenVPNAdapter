//
//  OpenVPNContentPair.m
//  OpenVPN Adapter
//
//  Created by Jonathan Downing on 14/08/2017.
//

#import "OpenVPNContentPair.h"

@interface OpenVPNContentPair ()
@property (nonatomic, readwrite, nonnull) NSString *key;
@property (nonatomic, readwrite, nullable) NSString *value;
@end

@implementation OpenVPNContentPair

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithKey:key value:nil];
}

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value {
    if (self = [self init]) {
        self.key = key;
        self.value = value;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        self.key = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(key))];
        self.value = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(value))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.key forKey:NSStringFromSelector(@selector(key))];
    [aCoder encodeObject:self.value forKey:NSStringFromSelector(@selector(value))];
}

- (id)copyWithZone:(NSZone *)zone {
    OpenVPNContentPair *contentPair = [[OpenVPNContentPair allocWithZone:zone] init];
    contentPair.key = [self.key copyWithZone:zone];
    contentPair.value = [self.value copyWithZone:zone];
    return contentPair;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", self.key, self.value ?: @""];
}

@end

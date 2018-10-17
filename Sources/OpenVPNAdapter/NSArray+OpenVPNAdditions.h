//
//  NSArray+OpenVPNAdditions.h
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 16/10/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (OpenVPNEmptyArray)

@property (nonatomic, readonly) BOOL ovpn_isNotEmpty;

@end

NS_ASSUME_NONNULL_END

//
//  NSSet+Empty.h
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 16/10/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSSet (Empty)

@property (nonatomic, readonly) BOOL isNotEmpty;

@end

NS_ASSUME_NONNULL_END

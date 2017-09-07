//
//  NSError+Message.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//

#import <Foundation/Foundation.h>

@interface NSError (Message)

+ (NSString *)reasonFromResult:(NSInteger)result;

@end

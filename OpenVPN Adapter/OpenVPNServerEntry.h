//
//  OpenVPNServerEntry.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNServerEntry : NSObject

@property (nullable, readonly, nonatomic) NSString *server;
@property (nullable, readonly, nonatomic) NSString *friendlyName;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

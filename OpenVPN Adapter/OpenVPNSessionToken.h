//
//  OpenVPNSessionToken.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Class used to get session token from VPN core
 */
@interface OpenVPNSessionToken : NSObject

@property (nullable, readonly, nonatomic) NSString *username;

/**
 An OpenVPN Session ID, used as a proxy for password
 */
@property (nullable, readonly, nonatomic) NSString *session;

- (nonnull instancetype) __unavailable init;

@end

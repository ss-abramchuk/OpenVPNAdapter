//
//  OpenVPNCredentials.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 24.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Class used to pass credentials
 */
@interface OpenVPNCredentials : NSObject

/**
 Client username
 */
@property (nullable, nonatomic) NSString *username;

/**
 Client password
 */
@property (nullable, nonatomic) NSString *password;

/**
 Response to challenge
 */
@property (nullable, nonatomic) NSString *response;

/**
 Dynamic challenge/response cookie
 */
@property (nullable, nonatomic) NSString *dynamicChallengeCookie;

/**
 If YES, on successful connect, we will replace the password
 with the session ID we receive from the server (if provided).
 If NO, the password will be cached for future reconnects
 and will not be replaced with a session ID, even if the
 server provides one.
 */
@property (nonatomic) BOOL replacePasswordWithSessionID;

/**
 If YES, and if replacePasswordWithSessionID is YES, and if
 we actually receive a session ID from the server, cache
 the user-provided password for future use before replacing
 the active password with the session ID.
 */
@property (nonatomic) BOOL cachePassword;

@end

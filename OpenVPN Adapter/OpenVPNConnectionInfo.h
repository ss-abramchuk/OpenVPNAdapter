//
//  OpenVPNConnectionInfo.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Class used to provide extra details about successful connection
 */
@interface OpenVPNConnectionInfo : NSObject <NSCopying, NSSecureCoding>

@property (nullable, readonly, nonatomic) NSString *user;
@property (nullable, readonly, nonatomic) NSString *serverHost;
@property (nullable, readonly, nonatomic) NSString *serverPort;
@property (nullable, readonly, nonatomic) NSString *serverProto;
@property (nullable, readonly, nonatomic) NSString *serverIP;
@property (nullable, readonly, nonatomic) NSString *vpnIPv4;
@property (nullable, readonly, nonatomic) NSString *vpnIPv6;
@property (nullable, readonly, nonatomic) NSString *gatewayIPv4;
@property (nullable, readonly, nonatomic) NSString *gatewayIPv6;
@property (nullable, readonly, nonatomic) NSString *clientIP;
@property (nullable, readonly, nonatomic) NSString *tunName;

@end

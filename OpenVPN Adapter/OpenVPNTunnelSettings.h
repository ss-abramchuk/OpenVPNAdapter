//
//  OpenVPNTunnelSettings.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.02.17.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenVPNTunnelSettings : NSObject

@property (nonatomic) BOOL initialized;

@property (readonly, strong, nonatomic) NSMutableArray *localAddresses;
@property (readonly, strong, nonatomic) NSMutableArray *prefixLengths;

@property (readonly, strong, nonatomic) NSMutableArray *includedRoutes;
@property (readonly, strong, nonatomic) NSMutableArray *excludedRoutes;

@property (readonly, strong, nonatomic) NSMutableArray *dnsAddresses;

@end

NS_ASSUME_NONNULL_END

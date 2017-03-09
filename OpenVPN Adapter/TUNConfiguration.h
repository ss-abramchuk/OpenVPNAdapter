//
//  TUNConfiguration.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 26.02.17.
//
//

#import <Foundation/Foundation.h>

@class NEIPv4Route;

@interface TUNConfiguration : NSObject

@property (strong, nonatomic) NSString *remoteAddress;

@property (readonly, strong, nonatomic) NSMutableArray<NSString *> *localAddresses;
@property (readonly, strong, nonatomic) NSMutableArray<NSString *> *subnets;

@property (readonly, strong, nonatomic) NSMutableArray<NEIPv4Route *> *includedRoutes;
@property (readonly, strong, nonatomic) NSMutableArray<NEIPv4Route *> *excludedRoutes;

@property (readonly, strong, nonatomic) NSMutableArray<NSString *> *dnsAddresses;
@property (readonly, strong, nonatomic) NSMutableArray<NSString *> *searchDomains;

@property (strong, nonatomic) NSNumber *mtu;

@end

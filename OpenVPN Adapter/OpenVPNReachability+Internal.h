//
//  OpenVPNReachability+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.07.17.
//
//

#import "OpenVPNReachability.h"

@interface OpenVPNReachability (Internal)

- (void)updateReachabilityStatus:(OpenVPNReachabilityStatus)status;

@end

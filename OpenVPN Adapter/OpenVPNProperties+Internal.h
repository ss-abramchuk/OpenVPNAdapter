//
//  OpenVPNProperties+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import <client/ovpncli.hpp>

#import "OpenVPNProperties.h"

using namespace openvpn;

@interface OpenVPNProperties (Internal)

- (instancetype)initWithEvalConfig:(ClientAPI::EvalConfig)eval;

@end

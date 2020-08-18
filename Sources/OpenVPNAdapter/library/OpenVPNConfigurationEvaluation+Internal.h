//
//  OpenVPNConfigurationEvaluation+Internal.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 26.04.17.
//
//

#import "OpenVPNConfigurationEvaluation.h"

#include <ovpnapi.hpp>

using namespace openvpn;

@interface OpenVPNConfigurationEvaluation (Internal)

- (instancetype)initWithEvalConfig:(ClientAPI::EvalConfig)eval;

@end

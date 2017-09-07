//
//  OpenVPNKeyType.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNKeyType) {
    OpenVPNKeyTypeNone = 0,
    OpenVPNKeyTypeRSA,
    OpenVPNKeyTypeECKEY,
    OpenVPNKeyTypeECKEYDH,
    OpenVPNKeyTypeECDSA,
    OpenVPNKeyTypeRSAALT,
    OpenVPNKeyTypeRSASSAPSS,
};

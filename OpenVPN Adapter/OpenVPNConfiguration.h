//
//  OpenVPNConfiguration.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

#import <Foundation/Foundation.h>

// TODO: Wrap ClientAPI::Config into Objective-C class

@interface OpenVPNConfiguration : NSObject

/**
 OpenVPN profile as a NSData
 */
@property (nullable, nonatomic) NSData *fileContent;

/**
 OpenVPN profile as series of key/value pairs (may be provided exclusively
 or in addition to file content).
 */
@property (nullable, nonatomic) NSDictionary<NSString *, NSString *> *settings;

/**
 Set to identity OpenVPN GUI version.
 Format should be "<gui_identifier><space><version>"
 Passed to server as IV_GUI_VER.
 */
@property (nullable, nonatomic) NSString *guiVersion;

/**
 Use a different server than that specified in "remote"
 option of profile
 */
@property (nullable, nonatomic) NSString *serverOverride;

/**
 Force a given transport protocol
 Should be tcp, udp, or adaptive.
 */
@property (nullable, nonatomic) NSString *protoOverride;

@end

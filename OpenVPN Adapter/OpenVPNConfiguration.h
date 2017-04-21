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

@property (nullable, nonatomic) NSData *fileContent;

@end

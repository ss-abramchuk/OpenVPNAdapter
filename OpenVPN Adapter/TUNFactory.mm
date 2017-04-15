//
//  TUNFactory.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.04.17.
//
//

#import "TUNFactory.h"

// !!! tuncli.hpp may be used as example of implementation

TunClient::Ptr TUNFactory::new_tun_client_obj(openvpn_io::io_context& io_context,
                                              TunClientParent& parent,
                                              TransportClient* transcli)
{
    return nullptr;
}

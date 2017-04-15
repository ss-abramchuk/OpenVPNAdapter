//
//  TUNFactory.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.04.17.
//
//

#import <openvpn/tun/client/tunbase.hpp>

using namespace openvpn;

class TUNFactory: public TunClientFactory {
public:
    virtual TunClient::Ptr new_tun_client_obj(openvpn_io::io_context& io_context,
                                              TunClientParent& parent,
                                              TransportClient* transcli) override;
};

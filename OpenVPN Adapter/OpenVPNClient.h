//
//  OpenVPNClient+Internal.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <openvpn/tun/client/tunbase.hpp>
#import <client/ovpncli.hpp>

using namespace openvpn;

class OpenVPNClient : public ClientAPI::OpenVPNClient, public TunClientFactory
{
public:
    OpenVPNClient(void* adapter);
    
    virtual TunClientFactory* new_tun_factory(const ExternalTun::Config& conf, const OptionList& opt) override;
    virtual TunClient::Ptr new_tun_client_obj(openvpn_io::io_context& io_context, TunClientParent& parent, TransportClient* transcli) override;
    
    virtual bool socket_protect(int socket) override;
    virtual bool pause_on_connection_timeout() override;
    
    virtual void external_pki_cert_request(ClientAPI::ExternalPKICertRequest& certreq) override;
    virtual void external_pki_sign_request(ClientAPI::ExternalPKISignRequest& signreq) override;
    
    virtual void event(const ClientAPI::Event& ev) override;
    virtual void log(const ClientAPI::LogInfo& log) override;
    
private:
    void* adapter;
};

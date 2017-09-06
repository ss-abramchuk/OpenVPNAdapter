//
//  OpenVPNClient.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <openvpn/tun/client/tunbase.hpp>
#import <client/ovpncli.hpp>

using namespace openvpn;

class OpenVPNClient : public ClientAPI::OpenVPNClient
{
public:
    OpenVPNClient(void * adapter);
    
    virtual bool tun_builder_new() override;
    
    virtual bool tun_builder_set_remote_address(const std::string& address, bool ipv6) override;
    virtual bool tun_builder_add_address(const std::string& address,
                                         int prefix_length,
                                         const std::string& gateway,
                                         bool ipv6,
                                         bool net30) override;
    virtual bool tun_builder_reroute_gw(bool ipv4,
                                        bool ipv6,
                                        unsigned int flags) override;
    virtual bool tun_builder_add_route(const std::string& address,
                                       int prefix_length,
                                       int metric,
                                       bool ipv6) override;
    virtual bool tun_builder_exclude_route(const std::string& address,
                                           int prefix_length,
                                           int metric,
                                           bool ipv6) override;
    virtual bool tun_builder_add_dns_server(const std::string& address, bool ipv6) override;
    virtual bool tun_builder_add_search_domain(const std::string& domain) override;
    virtual bool tun_builder_set_mtu(int mtu) override;
    virtual bool tun_builder_set_session_name(const std::string& name) override;
    virtual bool tun_builder_add_proxy_bypass(const std::string& bypass_host) override;
    virtual bool tun_builder_set_proxy_auto_config_url(const std::string& url) override;
    virtual bool tun_builder_set_proxy_http(const std::string& host, int port) override;
    virtual bool tun_builder_set_proxy_https(const std::string& host, int port) override;
    virtual bool tun_builder_add_wins_server(const std::string& address) override;
    
    virtual int tun_builder_establish() override;
    
    virtual bool tun_builder_persist() override;
    virtual void tun_builder_establish_lite() override;
    
    virtual void tun_builder_teardown(bool disconnect) override;
    
    virtual bool socket_protect(int socket) override;
    
    virtual bool pause_on_connection_timeout() override;
    
    virtual void external_pki_cert_request(ClientAPI::ExternalPKICertRequest& certreq) override;
    virtual void external_pki_sign_request(ClientAPI::ExternalPKISignRequest& signreq) override;
    
    virtual void event(const ClientAPI::Event& ev) override;
    virtual void log(const ClientAPI::LogInfo& log) override;
    
    virtual void clock_tick() override;
    
private:
    void* adapter;
};

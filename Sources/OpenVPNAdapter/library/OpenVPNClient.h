//
//  OpenVPNClient.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.01.2018.
//

#import <Foundation/Foundation.h>

#include <ovpnapi.hpp>

@class NEIPv4Route;
@class NEIPv6Route;
@class NEProxyServer;

typedef NS_ENUM(NSInteger, OpenVPNProxyServerProtocol) {
    OpenVPNProxyServerProtocolHTTP,
    OpenVPNProxyServerProtocolHTTPS
};

NS_ASSUME_NONNULL_BEGIN

@protocol OpenVPNClientDelegate <NSObject>
- (BOOL)setRemoteAddress:(NSString *)address;

- (BOOL)addIPV4Address:(NSString *)address subnetMask:(NSString *)subnetMask gateway:(nullable NSString *)gateway;
- (BOOL)addIPV6Address:(NSString *)address prefixLength:(NSNumber *)prefixLength gateway:(nullable NSString *)gateway;

- (BOOL)addIPV4Route:(NEIPv4Route *)route;
- (BOOL)addIPV6Route:(NEIPv6Route *)route;
- (BOOL)excludeIPV4Route:(NEIPv4Route *)route;
- (BOOL)excludeIPV6Route:(NEIPv6Route *)route;

- (BOOL)addDNS:(NSString *)dns;
- (BOOL)addSearchDomain:(NSString *)domain;

- (BOOL)setMTU:(NSNumber *)mtu;
- (BOOL)setSessionName:(NSString *)name;

- (BOOL)addProxyBypassHost:(NSString *)bypassHost;
- (BOOL)setProxyAutoConfigurationURL:(NSURL *)url;
- (BOOL)setProxyServer:(NEProxyServer *)server protocol:(OpenVPNProxyServerProtocol)protocol;

- (BOOL)establishTunnel;
- (CFSocketNativeHandle)socketHandle;

- (void)clientEventName:(NSString *)eventName message:(nullable NSString *)message;
- (void)clientErrorName:(NSString *)errorName fatal:(BOOL)fatal message:(nullable NSString *)message;
- (void)clientLogMessage:(NSString *)logMessage;

- (void)tick;

- (void)resetSettings;
- (void)resetTun;
@end

NS_ASSUME_NONNULL_END

using namespace openvpn;

class OpenVPNClient : public ClientAPI::OpenVPNClient {
public:
    OpenVPNClient(id<OpenVPNClientDelegate> _Nonnull delegate);
    ~OpenVPNClient();
    
    ClientAPI::EvalConfig apply_config(const ClientAPI::Config& config);
    
    bool tun_builder_new() override;
    
    bool tun_builder_set_remote_address(const std::string& address, bool ipv6) override;
    bool tun_builder_add_address(const std::string& address, int prefix_length, const std::string& gateway,
                                 bool ipv6, bool net30) override;
    bool tun_builder_reroute_gw(bool ipv4, bool ipv6, unsigned int flags) override;
    bool tun_builder_add_route(const std::string& address, int prefix_length, int metric, bool ipv6) override;
    bool tun_builder_exclude_route(const std::string& address, int prefix_length, int metric, bool ipv6) override;
    bool tun_builder_add_dns_server(const std::string& address, bool ipv6) override;
    bool tun_builder_add_search_domain(const std::string& domain) override;
    bool tun_builder_set_mtu(int mtu) override;
    bool tun_builder_set_session_name(const std::string& name) override;
    bool tun_builder_add_proxy_bypass(const std::string& bypass_host) override;
    bool tun_builder_set_proxy_auto_config_url(const std::string& urlString) override;
    bool tun_builder_set_proxy_http(const std::string& host, int port) override;
    bool tun_builder_set_proxy_https(const std::string& host, int port) override;
    bool tun_builder_set_block_ipv6(bool block_ipv6) override;
    
    int tun_builder_establish() override;
    bool tun_builder_persist() override;
    void tun_builder_teardown(bool disconnect) override;
    
    bool socket_protect(int socket, std::string remote, bool ipv6) override;
    bool pause_on_connection_timeout() override;
    
    void external_pki_cert_request(ClientAPI::ExternalPKICertRequest& certreq) override;
    void external_pki_sign_request(ClientAPI::ExternalPKISignRequest& signreq) override;
    
    void event(const ClientAPI::Event& event) override;
    void log(const ClientAPI::LogInfo& log) override;
    
    void clock_tick() override;
    
private:
    __weak id<OpenVPNClientDelegate> _Nonnull delegate;
    ClientAPI::Config * _Nullable config;
};



//
//  OpenVPNClient.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.01.2018.
//

#define INVALID_SOCKET -1

#import "OpenVPNClient.h"

#import <NetworkExtension/NetworkExtension.h>

#include <openvpn/addr/ipv4.hpp>

using ::IPv4::Addr;

OpenVPNClient::OpenVPNClient(id<OpenVPNClientDelegate> delegate): ClientAPI::OpenVPNClient() {
    this->delegate = delegate;
    this->config = nullptr;
}

OpenVPNClient::~OpenVPNClient() {
    if (this->config != nullptr) { delete this->config; }
}

ClientAPI::EvalConfig OpenVPNClient::apply_config(const ClientAPI::Config& config) {
    if (this->config != nullptr) { delete this->config; }
    this->config = new ClientAPI::Config(config);
    
    return eval_config(config);
}

bool OpenVPNClient::tun_builder_new() {
    [this->delegate resetSettings];
    [this->delegate resetTun];
    
    return true;
}

bool OpenVPNClient::tun_builder_set_remote_address(const std::string &address, bool ipv6) {
    NSString *remoteAddress = [NSString stringWithUTF8String:address.c_str()];
    return [this->delegate setRemoteAddress:remoteAddress];
}

bool OpenVPNClient::tun_builder_add_address(const std::string &address, int prefix_length, const std::string &gateway, bool ipv6, bool net30) {
    NSString *localAddress = [NSString stringWithUTF8String:address.c_str()];
    NSString *gatewayAddress = gateway.length() == 0 || gateway.compare("UNSPEC") == 0 ? nil :
        [NSString stringWithUTF8String:gateway.c_str()];
    
    if (ipv6) {
        return [this->delegate addIPV6Address:localAddress prefixLength:@(prefix_length) gateway:gatewayAddress];
    } else {
        NSString *subnetMask = [NSString stringWithUTF8String:Addr::netmask_from_prefix_len(prefix_length).to_string().c_str()];
        return [this->delegate addIPV4Address:localAddress subnetMask:subnetMask gateway:gatewayAddress];
    }
}

bool OpenVPNClient::tun_builder_reroute_gw(bool ipv4, bool ipv6, unsigned int flags) {
    if (ipv4 && ![this->delegate addIPV4Route:[NEIPv4Route defaultRoute]]) {
        return false;
    }
    
    if (ipv6 && ![this->delegate addIPV6Route:[NEIPv6Route defaultRoute]]) {
        return false;
    }
    
    return true;
}

bool OpenVPNClient::tun_builder_add_route(const std::string& address, int prefix_length, int metric, bool ipv6) {
    NSString *routeAddress = [NSString stringWithUTF8String:address.c_str()];
    
    if (ipv6) {
        NEIPv6Route *route = [[NEIPv6Route alloc] initWithDestinationAddress:routeAddress networkPrefixLength:@(prefix_length)];
        return [this->delegate addIPV6Route:route];
    } else {
        NSString *subnetMask = [NSString stringWithUTF8String:Addr::netmask_from_prefix_len(prefix_length).to_string().c_str()];
        NEIPv4Route *route = [[NEIPv4Route alloc] initWithDestinationAddress:routeAddress subnetMask:subnetMask];
        return [this->delegate addIPV4Route:route];
    }
}

bool OpenVPNClient::tun_builder_exclude_route(const std::string& address, int prefix_length, int metric, bool ipv6) {
    NSString *routeAddress = [NSString stringWithUTF8String:address.c_str()];
    
    if (ipv6) {
        NEIPv6Route *route = [[NEIPv6Route alloc] initWithDestinationAddress:routeAddress networkPrefixLength:@(prefix_length)];
        return [this->delegate excludeIPV6Route:route];
    } else {
        NSString *subnetMask = [NSString stringWithUTF8String:Addr::netmask_from_prefix_len(prefix_length).to_string().c_str()];
        NEIPv4Route *route = [[NEIPv4Route alloc] initWithDestinationAddress:routeAddress subnetMask:subnetMask];
        return [this->delegate excludeIPV4Route:route];
    }
}

bool OpenVPNClient::tun_builder_add_dns_server(const std::string& address, bool ipv6) {
    NSString *dns = [NSString stringWithUTF8String:address.c_str()];
    return [this->delegate addDNS:dns];
}

bool OpenVPNClient::tun_builder_add_search_domain(const std::string& domain) {
    NSString *searchDomain = [NSString stringWithUTF8String:domain.c_str()];
    return [this->delegate addSearchDomain:searchDomain];
}

bool OpenVPNClient::tun_builder_set_mtu(int mtu) {
    return [this->delegate setMTU:@(mtu)];
}

bool OpenVPNClient::tun_builder_set_session_name(const std::string& name) {
    NSString *sessionName = [NSString stringWithUTF8String:name.c_str()];
    return [this->delegate setSessionName:sessionName];
}

bool OpenVPNClient::tun_builder_add_proxy_bypass(const std::string& bypass_host) {
    NSString *bypassHost = [NSString stringWithUTF8String:bypass_host.c_str()];
    return [this->delegate addProxyBypassHost:bypassHost];
}

bool OpenVPNClient::tun_builder_set_proxy_auto_config_url(const std::string& url) {
    NSURL *configURL = [[NSURL alloc] initWithString:[NSString stringWithUTF8String:url.c_str()]];
    if (configURL) {
        return [this->delegate setProxyAutoConfigurationURL:configURL];
    } else {
        return false;
    }
}

bool OpenVPNClient::tun_builder_set_proxy_http(const std::string& host, int port) {
    NSString *proxyHost = [NSString stringWithUTF8String:host.c_str()];
    NEProxyServer *proxyServer = [[NEProxyServer alloc] initWithAddress:proxyHost port:port];
    return [this->delegate setProxyServer:proxyServer protocol:OpenVPNProxyServerProtocolHTTP];
}

bool OpenVPNClient::tun_builder_set_proxy_https(const std::string& host, int port) {
    NSString *proxyHost = [NSString stringWithUTF8String:host.c_str()];
    NEProxyServer *proxyServer = [[NEProxyServer alloc] initWithAddress:proxyHost port:port];
    return [this->delegate setProxyServer:proxyServer protocol:OpenVPNProxyServerProtocolHTTPS];
}

bool OpenVPNClient::tun_builder_set_block_ipv6(bool block_ipv6) {
    return block_ipv6;
}

int OpenVPNClient::tun_builder_establish() {
    return [this->delegate establishTunnel] ? [this->delegate socketHandle] : INVALID_SOCKET;
}

bool OpenVPNClient::tun_builder_persist() {
    return config->tunPersist;
}

void OpenVPNClient::tun_builder_teardown(bool disconnect) {
    [this->delegate resetSettings];
    [this->delegate resetTun];
}

bool OpenVPNClient::socket_protect(int socket, std::string remote, bool ipv6) {
    return true;
}

bool OpenVPNClient::pause_on_connection_timeout() {
    return false;
}

void OpenVPNClient::external_pki_cert_request(ClientAPI::ExternalPKICertRequest& certreq) { }
void OpenVPNClient::external_pki_sign_request(ClientAPI::ExternalPKISignRequest& signreq) { }

void OpenVPNClient::event(const ClientAPI::Event& ev) {
    NSString *name = [NSString stringWithUTF8String:ev.name.c_str()];
    NSString *message = [NSString stringWithUTF8String:ev.info.c_str()];
    
    if (ev.error) {
        [this->delegate clientErrorName:name fatal:ev.fatal message:message.length ? message : nil];
    } else {
        [this->delegate clientEventName:name message:message.length ? message : nil];
    }
}

void OpenVPNClient::log(const ClientAPI::LogInfo& log) {
    NSString *logMessage = [NSString stringWithUTF8String:log.text.c_str()];
    [this->delegate clientLogMessage:logMessage];
}

void OpenVPNClient::clock_tick() {
    [this->delegate tick];
}

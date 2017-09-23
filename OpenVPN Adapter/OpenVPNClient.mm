//
//  OpenVPNClient.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

#import "OpenVPNAdapter+Internal.h"
#import "OpenVPNClient.h"

OpenVPNClient::OpenVPNClient(void *adapter) : ClientAPI::OpenVPNClient() {
    this->adapter = adapter;
}

bool OpenVPNClient::tun_builder_new() {
    return [(__bridge OpenVPNAdapter *)adapter configureSockets];
}

bool OpenVPNClient::tun_builder_set_remote_address(const std::string &address, bool ipv6) {
    NSString *remoteAddress = [NSString stringWithUTF8String:address.c_str()];
    return [(__bridge OpenVPNAdapter *)adapter setRemoteAddress:remoteAddress isIPv6:ipv6];
}

bool OpenVPNClient::tun_builder_add_address(const std::string &address, int prefix_length, const std::string &gateway, bool ipv6, bool net30) {
    NSString *localAddress = [NSString stringWithUTF8String:address.c_str()];
    NSString *gatewayAddress = [NSString stringWithUTF8String:gateway.c_str()];
    
    return [(__bridge OpenVPNAdapter *)adapter addLocalAddress:localAddress prefixLength:@(prefix_length) gateway:gatewayAddress isIPv6:ipv6];
}

bool OpenVPNClient::tun_builder_reroute_gw(bool ipv4, bool ipv6, unsigned int flags) {
    return [(__bridge OpenVPNAdapter *)adapter defaultGatewayRerouteIPv4:ipv4 rerouteIPv6:ipv6];
}

bool OpenVPNClient::tun_builder_add_route(const std::string& address, int prefix_length, int metric, bool ipv6) {
    NSString *route = [NSString stringWithUTF8String:address.c_str()];
    return [(__bridge OpenVPNAdapter *)adapter addRoute:route prefixLength:@(prefix_length) isIPv6:ipv6];
}

bool OpenVPNClient::tun_builder_exclude_route(const std::string& address, int prefix_length, int metric, bool ipv6) {
    NSString *route = [NSString stringWithUTF8String:address.c_str()];
    return [(__bridge OpenVPNAdapter *)adapter excludeRoute:route prefixLength:@(prefix_length) isIPv6:ipv6];
}

bool OpenVPNClient::tun_builder_add_dns_server(const std::string& address, bool ipv6) {
    NSString *dnsAddress = [NSString stringWithUTF8String:address.c_str()];
    return [(__bridge OpenVPNAdapter *)adapter addDNSAddress:dnsAddress isIPv6:ipv6];
}

bool OpenVPNClient::tun_builder_add_search_domain(const std::string& domain) {
    NSString *searchDomain = [NSString stringWithUTF8String:domain.c_str()];
    return [(__bridge OpenVPNAdapter *)adapter addSearchDomain:searchDomain];
}

bool OpenVPNClient::tun_builder_set_mtu(int mtu) {
    return [(__bridge OpenVPNAdapter *)adapter setMTU:@(mtu)];
}

bool OpenVPNClient::tun_builder_set_session_name(const std::string& name) {
    return true;
}

bool OpenVPNClient::tun_builder_add_proxy_bypass(const std::string& bypass_host) {
    return true;
}

bool OpenVPNClient::tun_builder_set_proxy_auto_config_url(const std::string& url) {
    return true;
}

bool OpenVPNClient::tun_builder_set_proxy_http(const std::string& host, int port) {
    return true;
}

bool OpenVPNClient::tun_builder_set_proxy_https(const std::string& host, int port) {
    return true;
}

bool OpenVPNClient::tun_builder_add_wins_server(const std::string& address) {
    return true;
}

int OpenVPNClient::tun_builder_establish() {
    return (int)[(__bridge OpenVPNAdapter *)adapter establishTunnel];
}

bool OpenVPNClient::tun_builder_persist() {
    return true;
}

void OpenVPNClient::tun_builder_establish_lite() { }

void OpenVPNClient::tun_builder_teardown(bool disconnect) {
    [(__bridge OpenVPNAdapter *)adapter teardownTunnel:disconnect];
}

bool OpenVPNClient::socket_protect(int socket) {
    return true;
}

bool OpenVPNClient::pause_on_connection_timeout() {
    return false;
}

void OpenVPNClient::external_pki_cert_request(ClientAPI::ExternalPKICertRequest& certreq) { }
void OpenVPNClient::external_pki_sign_request(ClientAPI::ExternalPKISignRequest& signreq) { }

void OpenVPNClient::event(const ClientAPI::Event& ev) {
    [(__bridge OpenVPNAdapter* )adapter handleEvent:&ev];
}

void OpenVPNClient::log(const ClientAPI::LogInfo& log) {
    [(__bridge OpenVPNAdapter* )adapter handleLog:&log];
}

void OpenVPNClient::clock_tick() {
    [(__bridge OpenVPNAdapter* )adapter tick];
}

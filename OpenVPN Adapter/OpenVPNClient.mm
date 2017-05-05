//
//  OpenVPNClient.m
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

#import "OpenVPNAdapter+Internal.h"
#import "OpenVPNClient.h"

OpenVPNClient::OpenVPNClient(void* adapter) : ClientAPI::OpenVPNClient() {
    this->adapter = adapter;
}

TunClientFactory* OpenVPNClient::new_tun_factory(const ExternalTun::Config& conf, const OptionList& opt) {
    return this;
}

TunClient::Ptr OpenVPNClient::new_tun_client_obj(openvpn_io::io_context& io_context, TunClientParent& parent, TransportClient* transcli) {
    return nullptr;
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

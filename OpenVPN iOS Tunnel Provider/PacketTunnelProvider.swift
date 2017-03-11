//
//  PacketTunnelProvider.swift
//  OpenVPN Tunnel Provider
//
//  Created by Sergey Abramchuk on 05.02.17.
//
//

import NetworkExtension
import KeychainAccess
import OpenVPNAdapter

enum PacketTunnelProviderError: Error {
    case fatalError(message: String)
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let keychain = Keychain(service: "me.ss-abramchuk.openvpn-ios-client", accessGroup: "2TWXCGG7R3.keychain-shared")
    
    lazy var vpnAdapter: OpenVPNAdapter = {
        return OpenVPNAdapter().then { $0.delegate = self }
    }()
    
    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        guard let settings = options?["Settings"] as? Data else {
            let error = PacketTunnelProviderError.fatalError(message: "Failed to retrieve OpenVPN settings from options")
            completionHandler(error)
            
            return
        }
        
        if let username = protocolConfiguration.username {
            vpnAdapter.username = username
        }
        
        if let reference = protocolConfiguration.passwordReference {
            do {
                guard let password = try keychain.get(ref: reference) else {
                    throw PacketTunnelProviderError.fatalError(message: "Failed to retrieve password from keychain")
                }
                
                vpnAdapter.password = password
            } catch {
                completionHandler(error)
                return
            }
        }
        
        do {
            try vpnAdapter.configure(using: settings)
        } catch {
            completionHandler(error)
            return
        }

        startHandler = completionHandler
        vpnAdapter.connect()
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopHandler = completionHandler
        vpnAdapter.disconnect()
    }
    
}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    
    func configureTunnel(settings: NEPacketTunnelNetworkSettings, callback: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        setTunnelNetworkSettings(settings) { (error) in
            callback(error == nil ? self.packetFlow : nil)
        }
    }
    
    func handle(event: OpenVPNEvent, message: String?) {
        
    }
    
    func handle(error: Error) {

    }
    
}

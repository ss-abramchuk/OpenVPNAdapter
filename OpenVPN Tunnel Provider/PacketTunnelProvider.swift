//
//  PacketTunnelProvider.swift
//  OpenVPN Tunnel Provider
//
//  Created by Sergey Abramchuk on 05.02.17.
//
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        // TODO: Some
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        
    }
    
}

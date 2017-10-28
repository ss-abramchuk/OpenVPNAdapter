//
//  CustomFlow.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.10.2017.
//

import NetworkExtension

class CustomFlow: NEPacketTunnelFlow {

    override func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) {
        
    }
    
    override func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
        return true
    }
    
    override func readPacketObjects(completionHandler: @escaping ([NEPacket]) -> Void) {
        
    }
    
    override func writePacketObjects(_ packets: [NEPacket]) -> Bool {
        return true
    }
    
}

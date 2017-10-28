//
//  CustomFlow.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.10.2017.
//

import NetworkExtension

class CustomFlow: NEPacketTunnelFlow {

    override func readPacketObjects(completionHandler: @escaping ([NEPacket]) -> Void) {
        super.readPacketObjects(completionHandler: completionHandler)
    }
    
    override func writePacketObjects(_ packets: [NEPacket]) -> Bool {
        return super.writePacketObjects(packets)
    }
    
}

//
//  CustomFlow.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 28.10.2017.
//

import NetworkExtension
@testable import OpenVPNAdapter

class CustomFlow: NSObject, OpenVPNAdapterPacketFlow {
    
    func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) {
        
    }
    
    func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
        return true
    }
    
}

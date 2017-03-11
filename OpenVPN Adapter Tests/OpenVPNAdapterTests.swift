//
//  OpenVPN_Adapter_Tests.swift
//  OpenVPN Adapter Tests
//
//  Created by Sergey Abramchuk on 09.03.17.
//
//

import XCTest
import NetworkExtension
@testable import OpenVPNAdapter

class OpenVPNAdapterTests: XCTestCase {
    
    let vpnConfiguration = "free_openvpn_udp"
    
    var vpnAdapterExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        vpnAdapterExpectation = nil
        
        super.tearDown()
    }
    
    // Test connection without specifying username and password
    func testConectionWithoutCredentials() {
        let configuration = getVPNConfiguration()

        let adapter = OpenVPNAdapter()
        do {
            try adapter.configure(using: configuration)
        } catch {
            XCTFail("Failed to configure OpenVPN adapted due to error: \(error)")
        }
        
        vpnAdapterExpectation = expectation(description: "me.ss-abramchuk.openvpn-adapter.connection-w/o-credentials")
        
        adapter.delegate = self
        adapter.connect()
        
        waitForExpectations(timeout: 10.0) { (error) in
            adapter.disconnect()
        }
    }
    
}

extension OpenVPNAdapterTests {
    
    func getVPNConfiguration() -> Data {
        guard
            let path = Bundle.current.url(forResource: vpnConfiguration, withExtension: "ovpn"),
            let configuration = try? Data(contentsOf: path)
        else {
            fatalError("Failed to retrieve OpenVPN configuration")
        }
        
        return configuration
    }
    
}

extension OpenVPNAdapterTests: OpenVPNAdapterDelegate {
    
    func configureTunnel(settings: NEPacketTunnelNetworkSettings, callback: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        callback(self)
    }
    
    func handle(event: OpenVPNEvent, message: String?) {
        
    }
    
    func handle(error: Error) {
        
    }
    
}

extension OpenVPNAdapterTests: OpenVPNAdapterPacketFlow {
    
    func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) { }
    
    func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool { return true }
    
}

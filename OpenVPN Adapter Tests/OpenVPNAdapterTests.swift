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
    
    enum ConfigurationType {
        case withoutCredentials, withCredentials
    }
    
    enum ExpectationsType {
        case connection
    }
    
    let configurations: [ConfigurationType : String] = [
        .withoutCredentials: "free_openvpn_udp_us"
    ]
    
    var expectations = [ExpectationsType : XCTestExpectation]()
    
    override func setUp() {
        super.setUp()
        expectations.removeAll()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // Test connection without specifying username and password
    func testConectionWithoutCredentials() {
        let configuration = getVPNConfiguration(type: .withoutCredentials)

        let adapter = OpenVPNAdapter()
        do {
            try adapter.configure(using: configuration)
        } catch {
            XCTFail("Failed to configure OpenVPN adapted due to error: \(error)")
        }
        
        expectations[.connection] = expectation(description: "me.ss-abramchuk.openvpn-adapter.connection-w/o-credentials")
        
        adapter.delegate = self
        adapter.connect()
        
        waitForExpectations(timeout: 10.0) { (error) in
            adapter.disconnect()
        }
    }
    
}

extension OpenVPNAdapterTests {
    
    func getVPNConfiguration(type: ConfigurationType) -> Data {
        guard
            let fileName = configurations[type],
            let path = Bundle.current.url(forResource: fileName, withExtension: "ovpn"),
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
        switch event {
        case .connected:
            guard let connectionExpectation = expectations[.connection] else { return }
            connectionExpectation.fulfill()
            
        case .disconnected:
            break
            
        default:
            break
        }
    }
    
    func handle(error: Error) {
        
    }
    
    func handle(logMessage: String) {
        print("\(logMessage)")
    }
    
}

extension OpenVPNAdapterTests: OpenVPNAdapterPacketFlow {
    
    func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) { }
    
    func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool { return true }
    
}

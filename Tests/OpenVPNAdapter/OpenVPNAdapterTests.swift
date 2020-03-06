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
    
    enum ExpectationsType {
        case connection
    }
    
    let customFlow = CustomFlow()
    
    var expectations = [ExpectationsType : XCTestExpectation]()
    
    override func setUp() {
        super.setUp()
        expectations.removeAll()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testApplyConfiguration() {
        guard let vpnConfiguration = VPNProfile.configuration.data(using: .utf8) else { fatalError() }
        
        let adapter = OpenVPNAdapter()

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = vpnConfiguration
        configuration.settings = ["auth-user-pass": ""]

        let result: OpenVPNProperties
        do {
            result = try adapter.apply(configuration: configuration)
        } catch {
            XCTFail("Failed to configure OpenVPN adapted due to error: \(error)")
            return
        }

        XCTAssert(result.remoteHost == VPNProfile.remoteHost)
        XCTAssert(result.remotePort == VPNProfile.remotePort)
        XCTAssert(result.autologin == false)
    }
    
    func testProvideCredentials() {
        let adapter = OpenVPNAdapter()
        
        let credentials = OpenVPNCredentials()
        credentials.username = "username"
        credentials.password = "password"
        
        do {
            try adapter.provide(credentials: credentials)
        } catch {
            XCTFail("Failed to provide credentials. \(error)")
            return
        }
    }
    
    
    // Test connection to the VPN server
    func testConnection() {
        guard let vpnConfiguration = VPNProfile.configuration.data(using: .utf8) else { fatalError() }
        
        let adapter = OpenVPNAdapter()

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = vpnConfiguration
        
        let result: OpenVPNProperties
        do {
            result = try adapter.apply(configuration: configuration)
        } catch {
            XCTFail("Failed to configure OpenVPN adapted due to error: \(error)")
            return
        }
        
        if !result.autologin {
            let credentials = OpenVPNCredentials()
            credentials.username = VPNProfile.username
            credentials.password = VPNProfile.password
            
            do {
                try adapter.provide(credentials: credentials)
            } catch {
                XCTFail("Failed to provide credentials. \(error)")
                return
            }
        }

        expectations[.connection] = expectation(description: "me.ss-abramchuk.openvpn-adapter.connection")

        adapter.delegate = self
        adapter.connect()

        waitForExpectations(timeout: 30.0) { (error) in
            adapter.disconnect()
        }
    }
    
}

extension OpenVPNAdapterTests: OpenVPNAdapterDelegate {
    
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        completionHandler(customFlow)
    }
    
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
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
    
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        if let connectionExpectation = expectations[.connection] {
            XCTFail("Failed to establish conection.")
            connectionExpectation.fulfill()
        }
        
        dump(error)
    }
    
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        print(logMessage)
    }
    
}

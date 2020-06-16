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
    
    // Test connection to the VPN server without cert and key
    func testConnectionCAOnly() {
        guard let vpnConfiguration = VPNProfile.caOnly.configuration.data(using: .utf8) else { fatalError() }
        
        let adapter = OpenVPNAdapter()

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = vpnConfiguration
        configuration.settings = VPNProfile.caOnly.settings
        configuration.disableClientCert = true
        
        let result: OpenVPNProperties
        do {
            result = try adapter.apply(configuration: configuration)
        } catch {
            XCTFail("Failed to configure OpenVPN adapted due to error: \(error)")
            return
        }
        
        if !result.autologin {
            let credentials = OpenVPNCredentials()
            credentials.username = VPNProfile.caOnly.username
            credentials.password = VPNProfile.caOnly.password
            
            do {
                try adapter.provide(credentials: credentials)
            } catch {
                XCTFail("Failed to provide credentials. \(error)")
                return
            }
        }

        expectations[.connection] = expectation(description: "me.ss-abramchuk.openvpn-adapter.connection")

        adapter.delegate = self
        adapter.connect(using: customFlow)

        waitForExpectations(timeout: 30.0) { (error) in
            adapter.disconnect()
        }
    }
    
    // Test connection to the VPN server with cert and key
    func testConnectionCAWithCertAndKey() {
        guard let vpnConfiguration = VPNProfile.caWithCertAndKey.configuration.data(using: .utf8) else { fatalError() }
        
        let adapter = OpenVPNAdapter()

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = vpnConfiguration
        configuration.settings = VPNProfile.caWithCertAndKey.settings
        
        let result: OpenVPNProperties
        do {
            result = try adapter.apply(configuration: configuration)
        } catch {
            XCTFail("Failed to configure OpenVPN adapted due to error: \(error)")
            return
        }
        
        if !result.autologin {
            let credentials = OpenVPNCredentials()
            credentials.username = VPNProfile.caWithCertAndKey.username
            credentials.password = VPNProfile.caWithCertAndKey.password
            
            do {
                try adapter.provide(credentials: credentials)
            } catch {
                XCTFail("Failed to provide credentials. \(error)")
                return
            }
        }

        expectations[.connection] = expectation(description: "me.ss-abramchuk.openvpn-adapter.connection")

        adapter.delegate = self
        adapter.connect(using: customFlow)

        waitForExpectations(timeout: 30.0) { (error) in
            adapter.disconnect()
        }
    }
    
    // Test connection to the VPN server without credentials
    func testConnectionWithoutCredentials() {
        guard let vpnConfiguration = VPNProfile.withoutCredentials.configuration.data(using: .utf8) else { fatalError() }
        
        let adapter = OpenVPNAdapter()

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = vpnConfiguration
        configuration.settings = VPNProfile.withoutCredentials.settings
        
        let result: OpenVPNProperties
        do {
            result = try adapter.apply(configuration: configuration)
        } catch {
            XCTFail("Failed to configure OpenVPN adapted due to error: \(error)")
            return
        }
        
        XCTAssertTrue(result.autologin)

        expectations[.connection] = expectation(description: "me.ss-abramchuk.openvpn-adapter.connection")

        adapter.delegate = self
        adapter.connect(using: customFlow)

        waitForExpectations(timeout: 30.0) { (error) in
            adapter.disconnect()
        }
    }
    
}

extension OpenVPNAdapterTests: OpenVPNAdapterDelegate {
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
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

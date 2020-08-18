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
    
    private class CustomFlow: NSObject, OpenVPNAdapterPacketFlow {
        
        func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) {
            
        }
        
        func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
            return true
        }
        
    }
    
    private class AdapterDelegate: NSObject, OpenVPNAdapterDelegate {
        
        let settingsHandler: (NEPacketTunnelNetworkSettings?) -> Void
        let errorHandler: (Error) -> Void
        let eventHandler: (OpenVPNAdapterEvent) -> Void
        
        init(
            settingsHandler: @escaping (NEPacketTunnelNetworkSettings?) -> Void,
            errorHandler: @escaping (Error) -> Void,
            eventHandler: @escaping (OpenVPNAdapterEvent) -> Void
        ) {
            self.settingsHandler = settingsHandler
            self.errorHandler = errorHandler
            self.eventHandler = eventHandler
            
            super.init()
        }
        
        func openVPNAdapter(
            _ openVPNAdapter: OpenVPNAdapter,
            configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?,
            completionHandler: @escaping (Error?) -> Void
        ) {
            settingsHandler(networkSettings)
            completionHandler(nil)
        }
        
        func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
            errorHandler(error)
        }
        
        func openVPNAdapter(
            _ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?
        ) {
            eventHandler(event)
        }
        
        func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
            print(logMessage)
        }
    }
    
    private let customFlow = CustomFlow()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testVPNConnection() {
        let configuration = OpenVPNConfiguration()
        configuration.fileContent = VPNProfile.live.configuration.data(using: .utf8)
         
        var settings = VPNProfile.live.settings ?? [:]
        
        if let key = VPNProfile.live.key, let cert = VPNProfile.live.cert {
            settings["cert"] = cert.replacingOccurrences(of: "\n", with: "\\n")
            settings["key"] = key.replacingOccurrences(of: "\n", with: "\\n")
        }
        
        configuration.settings = settings
        
        let preEvaluation: OpenVPNConfigurationEvaluation
        do {
            preEvaluation = try OpenVPNAdapter.evaluate(configuration: configuration)
        } catch {
            XCTFail("Evaluation failed due to error: \(error)")
            return
        }
        
        guard !preEvaluation.externalPki else {
            XCTFail("Currently profile cannot be External PKI as it is not imlemented yet.")
            return
        }
        
        if preEvaluation.isPrivateKeyPasswordRequired {
            guard let keyPassword = VPNProfile.live.keyPassword else {
                XCTFail("Private key password required.")
                return
            }
            
            configuration.privateKeyPassword = keyPassword
        }
        
        let adapter = OpenVPNAdapter()
        
        let finalEvaluation: OpenVPNConfigurationEvaluation
        do {
            finalEvaluation = try adapter.apply(configuration: configuration)
        } catch {
            XCTFail("Failed to apply OpenVPN configuration due to error: \(error)")
            return
        }
        
        if !finalEvaluation.autologin {
            guard let username = VPNProfile.live.username, let password = VPNProfile.live.password else {
                XCTFail("If unable to autologin, username and password must be provided.")
                return
            }
            
            let credentials = OpenVPNCredentials()
            credentials.username = username
            credentials.password = password
            
            do {
                try adapter.provide(credentials: credentials)
            } catch {
                XCTFail("Failed to provide credentials. \(error)")
                return
            }
        }

        let connectionExpectation = XCTestExpectation(
            description: "Establish connection using \(VPNProfile.live.profileName)"
        )
        
        let adapterDelegate = AdapterDelegate(
            settingsHandler: { (settings) in
                
            },
            errorHandler: { (error) in
                XCTFail("Failed to establish conection due to error: \(error)")
            },
            eventHandler: { (event) in
                guard event == .connected else { return }
                
                connectionExpectation.fulfill()
                adapter.disconnect()
            }
        )
        
        adapter.delegate = adapterDelegate
        adapter.connect(using: customFlow)
        
        wait(for: [connectionExpectation], timeout: 15.0)
    }
}

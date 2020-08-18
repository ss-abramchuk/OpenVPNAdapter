//
//  OpenVPNConfigurationTests.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

import XCTest
@testable import OpenVPNAdapter

class OpenVPNConfigurationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEvaluateEmptyConfig() {
        let configuration = OpenVPNConfiguration()
        
        do {
            let _ = try OpenVPNAdapter.evaluate(configuration: configuration)
            XCTFail("We shouldn't be here, evaluation should fail.")
        } catch {
            guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool else {
                XCTFail("Error should contain OpenVPNAdapterErrorFatalKey.")
                return
            }
            
            XCTAssert(fatal)
        }
    }
    
    func testEvaluateManuallyPopulatedConfig() {
        let configuration = OpenVPNConfiguration()
        
        guard let caURL = Bundle.current.url(forResource: "ca", withExtension: "crt"),
            let caContent = try? String(contentsOf: caURL, encoding: .utf8)
        else {
            fatalError("Failed to get ca.crt, check its existance in the Resources folder.")
        }
        
        guard let certURL = Bundle.current.url(forResource: "client", withExtension: "crt"),
            let certContent = try? String(contentsOf: certURL, encoding: .utf8)
        else {
            fatalError("Failed to get client.crt, check its existance in the Resources folder.")
        }
        
        guard let keyURL = Bundle.current.url(forResource: "client", withExtension: "key"),
            let keyContent = try? String(contentsOf: keyURL, encoding: .utf8)
        else {
            fatalError("Failed to get client.key, check its existance in the Resources folder.")
        }
        
        configuration.settings = [
            "client": "",
            "dev": "tun",
            "proto": "udp",
            "remote": "my-server.com 1194",
            "resolv-retry": "infinite",
            "nobind": "",
            "auth-user-pass": "",
            "cipher": "AES-256-CBC",
            "comp-lzo": "",
            "verb": "3",
            "ca": caContent.replacingOccurrences(of: "\n", with: "\\n"),
            "cert": certContent.replacingOccurrences(of: "\n", with: "\\n"),
            "key": keyContent.replacingOccurrences(of: "\n", with: "\\n")
        ]
        
        let evaluation: OpenVPNConfigurationEvaluation
        do {
            evaluation = try OpenVPNAdapter.evaluate(configuration: configuration)
        } catch {
            XCTFail("Evaluation failed due to error: \(error)")
            return
        }
        
        XCTAssert(evaluation.remoteHost == "my-server.com")
        XCTAssert(evaluation.remotePort == 1194)
        
        XCTAssert(
            !evaluation.autologin, "Username and password are required so autologin should be false."
        )
        
        XCTAssert(
            !evaluation.externalPki,
            "Key and cert were provided to the configuration so it shouldn't be External PKI profile."
        )
    }
    
    func testEvaluateConfigFromFile() {
        let configuration = OpenVPNConfiguration()
        
        guard let configURL = Bundle.current.url(forResource: "client", withExtension: "ovpn"),
            let configContent = try? Data(contentsOf: configURL)
        else {
            fatalError("Failed to get client.ovpn, check its existance in the Resources folder.")
        }
        
        configuration.fileContent = configContent
        
        let evaluation: OpenVPNConfigurationEvaluation
        do {
            evaluation = try OpenVPNAdapter.evaluate(configuration: configuration)
        } catch {
            XCTFail("Evaluation failed due to error: \(error)")
            return
        }
        
        XCTAssert(evaluation.remoteHost == "my-server.com")
        XCTAssert(evaluation.remotePort == 1194)
        
        XCTAssert(
            !evaluation.autologin, "Username and password required so autologin should be false."
        )
        
        XCTAssert(
            evaluation.externalPki,
            "Key and cert were not provided to the configuration so it should be External PKI profile."
        )
    }
    
    func testSetConfigurationProperties() {
        let configuration = OpenVPNConfiguration()
        
        guard let configURL = Bundle.current.url(forResource: "client", withExtension: "ovpn"),
            let configContent = try? Data(contentsOf: configURL)
        else {
            fatalError("Failed to get client.ovpn, check its existance in the Resources folder.")
        }
        
        configuration.fileContent = configContent
        configuration.settings = [
            "persist-key": "",
            "persist-tun": ""
        ]
        
        configuration.server = "another-server.com"
        configuration.port = 5000
        
        XCTAssert(configuration.proto == .default)
        
        configuration.proto = .adaptive
        configuration.tlsCertProfile = .preferred
        
        XCTAssert(configuration.fileContent?.elementsEqual(configContent) == true)
        XCTAssert(configuration.settings?["persist-key"] != nil)
        XCTAssert(configuration.settings?["persist-tun"] != nil)
        
        XCTAssert(configuration.server == "another-server.com")
        XCTAssert(configuration.port == 5000)
        
        XCTAssert(configuration.proto == .adaptive)
        XCTAssert(configuration.tlsCertProfile == .preferred)
        
        XCTAssert(configuration.ipv6 == .default)
        
        configuration.ipv6 = .enabled
        XCTAssert(configuration.ipv6 == .enabled)
    }
}

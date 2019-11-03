//
//  OpenVPNConfigurationTests.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 21.04.17.
//
//

import XCTest
@testable import OpenVPNAdapter

// TODO: Test getting/setting of all properties of OpenVPNConfiguration

class OpenVPNConfigurationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetSetProfile() {
        guard let originalProfile = VPNProfile.configuration.data(using: .utf8) else { fatalError() }
        
        let configuration = OpenVPNConfiguration()
        
        guard configuration.fileContent == nil else {
            XCTFail("Empty file content should return nil")
            return
        }
        
        configuration.fileContent = originalProfile
        
        guard let returnedProfile = configuration.fileContent else {
            XCTFail("Returned file content should not be nil")
            return
        }
        
        XCTAssert(originalProfile.elementsEqual(returnedProfile))
        
        configuration.fileContent = nil
        XCTAssert(configuration.fileContent == nil, "Empty file content should return nil")
        
        configuration.fileContent = Data()
        XCTAssert(configuration.fileContent == nil, "Empty file content should return nil")
    }
    
    func testGetSetSettings() {
        let originalSettings = [
            "client": "",
            "dev": "tun",
            "remote-cert-tls" : "server"
        ]
        
        let configuration = OpenVPNConfiguration()
        
        guard configuration.settings == nil else {
            XCTFail("Empty settings should return nil")
            return
        }
        
        configuration.settings = originalSettings
        
        guard let returnedSettings = configuration.settings else {
            XCTFail("Returned settings should not be nil")
            return
        }
        
        let equals = originalSettings.allSatisfy { (key, value) in
            returnedSettings[key] == value
        }
        
        XCTAssert(equals)
        
        configuration.settings = [:]
        XCTAssert(configuration.settings == nil, "Empty settings should return nil")
        
        configuration.settings = nil
        XCTAssert(configuration.settings == nil, "Empty settings should return nil")
    }
    
    func testGetSetRemote() {
        guard let originalProfile = VPNProfile.configuration.data(using: .utf8) else { fatalError() }
        
        let originalServer = "192.168.1.200"
        let originalPort: UInt = 12000
        
        let configuration = OpenVPNConfiguration()        
        configuration.fileContent = originalProfile
        
        XCTAssertNil(configuration.server)
        XCTAssertEqual(configuration.port, 0)
        
        configuration.server = originalServer
        configuration.port = originalPort
        
        XCTAssertNotNil(configuration.server)
        XCTAssertEqual(configuration.server, originalServer)
        XCTAssertEqual(configuration.port, originalPort)
    }
    
    func testGetSetProto() {
        let originalOption: OpenVPNTransportProtocol = .UDP
        
        let configuration = OpenVPNConfiguration()
        
        guard configuration.proto == .default else {
            XCTFail("proto option should return default value")
            return
        }
        
        configuration.proto = originalOption
        guard configuration.proto == originalOption else {
            XCTFail("proto option should be equal to original value (enabled)")
            return
        }
    }
    
    func testGetSetIPv6() {  
        let originalOption: OpenVPNIPv6Preference = .enabled
        
        let configuration = OpenVPNConfiguration()
        
        guard configuration.ipv6 == .default else {
            XCTFail("IPv6 option should return default value")
            return
        }
        
        configuration.ipv6 = originalOption
        guard configuration.ipv6 == originalOption else {
            XCTFail("IPv6 option should be equal to original value (enabled)")
            return
        }
    }
    
    func testGetSetTLSCertProfile() {
        let originalOption: OpenVPNTLSCertProfile = .preferred
        
        let configuration = OpenVPNConfiguration()
        
        guard configuration.tlsCertProfile == .default else {
            XCTFail("TLS Cert Profile option should return default value")
            return
        }
        
        configuration.tlsCertProfile = originalOption
        guard configuration.tlsCertProfile == originalOption else {
            XCTFail("TLS Cert Profile option should be equal to original value (preferred)")
            return
        }
    }
    
}

//
//  OpenVPNCertificateTests.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 06.09.17.
//
//

import XCTest
@testable import OpenVPNAdapter

class OpenVPNCertificateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCertificateFromPEM() {
        guard
            let caURL = Bundle.current.url(forResource: "ca", withExtension: "crt"),
            let caData = try? Data(contentsOf: caURL)
//            let caContent = try? String(contentsOf: caURL, encoding: .utf8).cString(using: .utf8)
        else {
            XCTFail("")
            return
        }
        
        let certificate: OpenVPNCertificate
        do {
            certificate = try OpenVPNCertificate(pem: caData)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }
    
    func testCertificateFromEmptyPEM() {
        let caData = Data(count: 1024)
        
        let certificate: OpenVPNCertificate
        do {
            certificate = try OpenVPNCertificate(pem: caData)
        } catch {
            return
        }
        
        XCTFail("Initialization with empty PEM data should fail")
    }

}

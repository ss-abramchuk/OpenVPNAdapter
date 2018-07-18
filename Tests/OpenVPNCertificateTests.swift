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

    func testCertificatePEMandDER() {
        guard
            let caURL = Bundle.current.url(forResource: "test-ca", withExtension: "crt"),
            let caOriginalPEMData = try? Data(contentsOf: caURL)
        else {
            XCTFail()
            return
        }
        
        let certificateFromPEM: OpenVPNCertificate
        do {
            certificateFromPEM = try OpenVPNCertificate(pem: caOriginalPEMData)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        let caDERData: Data
        do {
            caDERData = try certificateFromPEM.derData()
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        let certificateFromDER: OpenVPNCertificate
        do {
            certificateFromDER = try OpenVPNCertificate(der: caDERData)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        let caGeneratedPEMData: Data
        do {
            caGeneratedPEMData = try certificateFromDER.pemData()
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        XCTAssert(caGeneratedPEMData.elementsEqual(caOriginalPEMData))
    }
    
    func testCertificateFromEmptyPEM() {
        let caData = Data(count: 1024)
        
        do {
            let _ = try OpenVPNCertificate(pem: caData)
        } catch {
            return
        }
        
        XCTFail("Initialization with empty PEM data should fail")
    }
    
    func testReadSerial() {
        guard
            let caURL = Bundle.current.url(forResource: "test-ca", withExtension: "crt"),
            let caOriginalPEMData = try? Data(contentsOf: caURL)
        else {
            XCTFail()
            return
        }
        
        let certificateFromPEM: OpenVPNCertificate
        do {
            certificateFromPEM = try OpenVPNCertificate(pem: caOriginalPEMData)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        XCTAssert(!certificateFromPEM.serial.isEmpty)
    }

}

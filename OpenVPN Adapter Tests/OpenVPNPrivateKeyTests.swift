//
//  OpenVPNPrivateKeyTests.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 07.09.17.
//
//

import XCTest
@testable import OpenVPNAdapter

class OpenVPNPrivateKeyTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testKeyPEMandDERWithoutPassword() {
        guard
            let caURL = Bundle.current.url(forResource: "keyfile-decrypted", withExtension: "3des"),
            let caOriginalPEMData = try? Data(contentsOf: caURL)
        else {
            XCTFail()
            return
        }
        
        let keyFromPEM: OpenVPNPrivateKey
        do {
            keyFromPEM = try OpenVPNPrivateKey(pem: caOriginalPEMData, password: nil)
        } catch {
            XCTFail("\(error)")
            return
        }
        
        XCTAssert(keyFromPEM.type == .RSA)
        
        let keyDERData: Data
        do {
            keyDERData = try keyFromPEM.derData()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        let keyFromDER: OpenVPNPrivateKey
        do {
            keyFromDER = try OpenVPNPrivateKey(der: keyDERData, password: nil)
        } catch {
            XCTFail("\(error)")
            return
        }
        
        XCTAssert(keyFromDER.type == .RSA)
        
        let keyGeneratedPEMData: Data
        do {
            keyGeneratedPEMData = try keyFromDER.pemData()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        XCTAssert(keyGeneratedPEMData.elementsEqual(caOriginalPEMData))
    }
    
    func testKeyPEMandDERWithPassword() {
        guard
            let keyURL = Bundle.current.url(forResource: "keyfile-encrypted", withExtension: "3des"),
            let keyOriginalPEMData = try? Data(contentsOf: keyURL)
        else {
            XCTFail()
            return
        }
        
        let keyFromPEM: OpenVPNPrivateKey
        do {
            keyFromPEM = try OpenVPNPrivateKey(pem: keyOriginalPEMData, password: "testkey")
        } catch {
            XCTFail("\(error)")
            return
        }
        
        let keyDERData: Data
        do {
            keyDERData = try keyFromPEM.derData()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        let keyFromDER: OpenVPNPrivateKey
        do {
            keyFromDER = try OpenVPNPrivateKey(der: keyDERData, password: nil)
        } catch {
            XCTFail("\(error)")
            return
        }
        
        let keyGeneratedPEMData: Data
        do {
            keyGeneratedPEMData = try keyFromDER.pemData()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        guard
            let keySampleURL = Bundle.current.url(forResource: "keyfile-decrypted", withExtension: "3des"),
            let keySamplePEMData = try? Data(contentsOf: keySampleURL)
        else {
            XCTFail()
            return
        }
        
        XCTAssert(keyGeneratedPEMData.elementsEqual(keySamplePEMData))
    }

}

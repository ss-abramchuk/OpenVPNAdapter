//
//  OpenVPNReachabilityTests.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 18.07.17.
//
//

import XCTest

#if os(macOS)
import CoreWLAN
#endif

@testable import OpenVPNAdapter

class OpenVPNReachabilityTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    #if os(macOS)
    func testReachability() {
        let wifiClient = CWWiFiClient.shared()
        guard let interface = wifiClient.interface() else {
            XCTFail()
            return
        }
        
        XCTAssert(interface.powerOn())
        
        let reachability = OpenVPNReachability()
        XCTAssert(reachability.reachabilityStatus == .reachableViaWiFi)
    }
    
    func testReachabilityTracking() {
        let wifiClient = CWWiFiClient.shared()
        guard let interface = wifiClient.interface() else {
            XCTFail()
            return
        }
        
        let reachabilityExpectation = expectation(description: "me.ss-abramchuk.openvpn-adapter.reachability")
        
        let reachability = OpenVPNReachability()
        reachability.startTracking { (status) in
            if case OpenVPNReachabilityStatus.reachableViaWiFi = status {
                reachabilityExpectation.fulfill()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()) { 
            try? interface.setPower(false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            try? interface.setPower(true)
        }
        
        waitForExpectations(timeout: 30.0, handler: nil)
    }
    
    #endif
}

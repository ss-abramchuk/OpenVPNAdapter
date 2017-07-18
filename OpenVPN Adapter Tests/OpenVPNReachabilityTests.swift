//
//  OpenVPNReachabilityTests.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 18.07.17.
//
//

import XCTest
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
    
    func testReachability() {
        let reachabilityExpectation = expectation(description: "me.ss-abramchuk.openvpn-adapter.reachability")
        
        let reachability = OpenVPNReachability()
        reachability.reachabilityStatusChangedBlock = { status in
            print("Current Status: \(status.rawValue)")
        }
        
        reachability.startTracking()
        
        waitForExpectations(timeout: 120.0, handler: nil)
    }
    
}

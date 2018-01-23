//
//  ProfileLoader.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 22.04.17.
//
//

import Foundation

enum ProfileType: String {
    case localVPNServer = "local_vpn_server"
    case remoteVPNServer = "remote_vpn_server"
}

struct ProfileLoader {
    
    static func getVPNProfile(type: ProfileType) -> Data {
        let fileName = type.rawValue
        
        guard
            let path = Bundle.current.url(forResource: fileName, withExtension: "ovpn"),
            let profile = try? Data(contentsOf: path)
        else {
            fatalError("Failed to retrieve OpenVPN profile")
        }
        
        return profile
    }
    
}


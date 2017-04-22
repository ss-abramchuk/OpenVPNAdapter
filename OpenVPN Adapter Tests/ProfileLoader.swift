//
//  ProfileLoader.swift
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 22.04.17.
//
//

import Foundation

enum ProfileType: String {
    case localKeyAuthentication = "local_key_auth"
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


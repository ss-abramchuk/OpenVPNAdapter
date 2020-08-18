//
//  VPNProfile.swift
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 27/09/2018.
//
//  Do not commit changes of this file to the repo!

import Foundation

struct VPNProfile {
    let profileName: String
    
    let configuration: String
    
    let cert: String?
    let key: String?
    
    let keyPassword: String?
    
    let username: String?
    let password: String?
    
    let settings: [String: String]?
}

extension VPNProfile {

    static let live: VPNProfile = {
        let profileName: String = <#OPENVPN_PROFILE_NAME#>

        let configuration: String = <#OPENVPN_CONFIGURATION#>

        let cert: String? = <#OPENVPN_CERT#>
        let key: String? = <#OPENVPN_KEY#>

        let keyPassword: String? = <#PRIVATE_KEY_PASSWORD#>
        
        let username: String? = <#OPENVPN_USERNAME#>
        let password: String? = <#OPENVPN_PASSWORD#>

        let settings: [String: String]? = <#OPENVPN_ADDITIONAL_SETTINGS#>

        return VPNProfile(
            profileName: profileName, configuration: configuration, cert: cert, key: key, keyPassword: keyPassword,
            username: username, password: password, settings: settings
        )
    }()
}

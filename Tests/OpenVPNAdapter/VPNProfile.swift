//
//  VPNProfile.swift
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 27/09/2018.
//
//  Do not commit changes of this file to the repo!

import Foundation

struct VPNProfile {
    let name: String
    
    let configuration: String
    
    let ca: String?
    let cert: String?
    let key: String?
    
    let username: String?
    let password: String?
    
    let settings: [String: String]?
}

extension VPNProfile {
    ///
    static let general: VPNProfile = {
        let name: String = <#OPENVPN_PROFILE_NAME#>
        
        let configuration: String = <#OPENVPN_CONFIGURATION#>
        
        let ca: String? = <#OPENVPN_CA#>
        let cert: String? = <#OPENVPN_CERT#>
        let key: String? = <#OPENVPN_KEY#>
        
        let username: String? = <#OPENVPN_USERNAME#>
        let password: String? = <#OPENVPN_PASSWORD#>
        
        let settings: [String: String]? = <#OPENVPN_ADDITIONAL_SETTINGS#>
        
        return VPNProfile(
            name: name, configuration: configuration, ca: ca, cert: cert, key: key,
            username: username, password: password, settings: settings
        )
    }()
}

extension VPNProfile {
    static let profileCollection = [
        VPNProfile.general
    ]
}

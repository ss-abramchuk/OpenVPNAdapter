//
//  VPNProfile.swift
//  OpenVPNAdapter
//
//  Created by Sergey Abramchuk on 27/09/2018.
//
//  Do not commit changes of this file to the repo!

import Foundation

struct VPNProfile {
    let configuration: String
    
    let username: String?
    let password: String?
    
    let settings: [String: String]?
}

extension VPNProfile {
    ///
    static let tlsClient: VPNProfile = {
        let configuration: String = <#OPENVPN_CONFIGURATION#>
        
        let username: String? = <#OPENVPN_USERNAME#>
        let password: String? = <#OPENVPN_PASSWORD#>
        
        let settings: [String: String]? = <#OPENVPN_ADDITIONAL_SETTINGS#>
        
        return VPNProfile(configuration: configuration, username: username, password: password, settings: settings)
    }()
    
    ///
    static let certWithKey: VPNProfile = {
        let configuration: String = <#OPENVPN_CONFIGURATION#>
        
        let username: String? = <#OPENVPN_USERNAME#>
        let password: String? = <#OPENVPN_PASSWORD#>
        
        let settings: [String: String]? = <#OPENVPN_ADDITIONAL_SETTINGS#>
        
        return VPNProfile(configuration: configuration, username: username, password: password, settings: settings)
    }()
}

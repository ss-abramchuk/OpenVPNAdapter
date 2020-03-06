//
//  Bundle.swift
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 09.03.17.
//
//

import Foundation

private final class BundleHelper {}

extension Bundle {
    
    static var current: Bundle {
        return Bundle(for: BundleHelper.self)
    }
    
}

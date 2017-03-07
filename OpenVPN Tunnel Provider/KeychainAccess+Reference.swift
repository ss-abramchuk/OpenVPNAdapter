//
//  KeychainAccess+Reference.swift
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 07.03.17.
//
//

import Foundation
import KeychainAccess

extension Keychain {
    
    public func get(ref: Data) throws -> String? {
        guard let data = try getData(ref: ref) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    public func getData(ref: Data) throws -> Data? {
        let query: [String: Any] = [
            String(kSecClass): itemClass.rawValue,
            String(kSecReturnData): kCFBooleanTrue,
            String(kSecValuePersistentRef): ref as CFData
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw Status.unexpectedError
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw Status(status: status)
        }
    }
    
}

//
//  OSStatus+Checks.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/5/25.
//

import Foundation

internal extension OSStatus {
    
    /**
     Check for and throw an error
     */
    func check() throws {
        if self != noErr {
            let message = SecCopyErrorMessageString(self, nil) as String? ?? "Error \(self)"
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(self), userInfo: [NSLocalizedDescriptionKey : message ])
            throw error
        }
    }
    
}

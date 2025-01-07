//
//  SecCertificate+Hash.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/6/25.
//

import Foundation
import CommonCrypto

extension SecCertificate {
    
    func publicKey() -> SecKey? {
        // Extract the public key
        var publicKey: SecKey?
    
        if #available(iOS 13.0, macOS 10.14, *) {
            publicKey = SecCertificateCopyKey(self)

        } else {
            #if os(macOS)
            let status = withUnsafeMutablePointer(to: &publicKey) {
                SecCertificateCopyPublicKey(self, $0)
            }
            if status != noErr {
                return nil
            }
            #endif
        }
        return publicKey
    }

}

//
//  PEMTools.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/5/21.
//

import Foundation

class PEMTools {
    
    static func wrap(_ csr: CertificationRequest) throws -> String {
        
        let encoder = DEREncoder()
        encoder.tagStrategy = CertificationRequest.TagStrategy()
        
        let derData = try encoder.encode(csr)
        
        var pem = derData.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
                
        pem.insert(contentsOf: "-----BEGIN CERTIFICATE REQUEST-----\n", at: pem.startIndex)
        pem.append("\n-----END CERTIFICATE REQUEST-----")
        
        return pem
    }
    
}

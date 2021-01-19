//
//  PEMTools.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/5/21.
//

import Foundation

public class PEMTools {
    
    public static func wrap(_ csr: CertificationRequest) throws -> String {
        
        let encoder = DEREncoder()
        
        let derData = try encoder.encode(csr)
        
        var pem = derData.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
                
        pem.insert(contentsOf: "-----BEGIN CERTIFICATE REQUEST-----\n", at: pem.startIndex)
        pem.append("\n-----END CERTIFICATE REQUEST-----")
        
        return pem
    }
    
    public static func unwrap<T: Decodable>(_ type: T.Type, pem: String) throws -> T {
        
        let b64 = pem.replacingOccurrences(of: "^-----BEGIN (.*)-----", with: "", options: .regularExpression)
            .replacingOccurrences(of: "-----END (.*)-----$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let data = Data(base64Encoded: b64) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Could not decode Base64 data"))
        }
        let decoder = DERDecoder()
        return try decoder.decode(type, from: data)
    }
    
}

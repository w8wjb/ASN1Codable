//
//  AlgorithmIdentifier.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/3/25.
//

public struct AlgorithmIdentifier: Codable, Hashable {
    
    public let identifier: OID
    
    enum CodingKeys: String, CodingKey {
        case identifier = "identifier"
        case parameters = "parameters"
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(OID.self, forKey: .identifier)
        
        
        switch identifier {
        case .rsaEncryption,
                .sha256WithRSAEncryption,
                .SHA256,
                .SHA384,
                .SHA512,
                .DSA,
                .HMAC_MD5,
                .HMAC_SHA1:
            do {
                let _ = try container.decodeNil(forKey: .parameters)
            } catch {
                // The null can be omitted entirely
            }
            
        default:
            throw DecodingError.dataCorruptedError(forKey: .parameters, in: container, debugDescription: "Unsupported algorithm: \(self.identifier)")
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encodeNil(forKey: .parameters)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
}

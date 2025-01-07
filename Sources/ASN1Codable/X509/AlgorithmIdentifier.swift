//
//  AlgorithmIdentifier.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/3/25.
//
import Security

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
                .SHA1,
                .SHA256,
                .SHA384,
                .SHA512,
                .DSA,
                .HMAC_MD5,
                .HMAC_SHA1,
                .sha1WithRSAEncryption,
                .sha224WithRSAEncryption,
                .sha256WithRSAEncryption,
                .sha384WithRSAEncryption,
                .sha512WithRSAEncryption,
                .ecdsa_with_SHA1,
                .ecdsa_with_SHA224,
                .ecdsa_with_SHA256,
                .ecdsa_with_SHA384,
                .ecdsa_with_SHA512            
            :
            let _ = try container.decodeNil(forKey: .parameters)
            
        default:
            throw DecodingError.dataCorruptedError(forKey: .parameters, in: container, debugDescription: "Unsupported algorithm: \(self.identifier)")
        }
    }
    
    
    public func signatureAlgorithm(digestAlgorithm: AlgorithmIdentifier? = nil) -> SecKeyAlgorithm? {
        
        if let hashAlgorithm = digestAlgorithm {
            
            switch self.identifier {
                
            case .rsaEncryption:
                switch hashAlgorithm.identifier {
                case .SHA256:
                    return .rsaSignatureMessagePKCS1v15SHA256
                case .SHA384:
                    return .rsaSignatureMessagePKCS1v15SHA384
                case .SHA512:
                    return .rsaSignatureMessagePKCS1v15SHA512
                case .SHA224:
                    return .rsaSignatureMessagePKCS1v15SHA224
                default:
                    break
                }
                
            default:
                break
            }
            
        }
        
        return switch self.identifier {
        case .sha1WithRSAEncryption: .rsaSignatureMessagePKCS1v15SHA1
        case .sha224WithRSAEncryption: .rsaSignatureMessagePKCS1v15SHA224
        case .sha256WithRSAEncryption: .rsaSignatureMessagePKCS1v15SHA256
        case .sha384WithRSAEncryption: .rsaSignatureMessagePKCS1v15SHA384
        case .sha512WithRSAEncryption: .rsaSignatureMessagePKCS1v15SHA512
        case .ecdsa_with_SHA1: .ecdsaSignatureMessageX962SHA1
        case .ecdsa_with_SHA224: .ecdsaSignatureMessageX962SHA224
        case .ecdsa_with_SHA256: .ecdsaSignatureMessageX962SHA256
        case .ecdsa_with_SHA384: .ecdsaSignatureMessageX962SHA384
        case .ecdsa_with_SHA512: .ecdsaSignatureMessageX962SHA512
        default: nil
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

//
//  Certificate.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/14/21.
//

import Foundation

public struct Certificate : Decodable {
    
    public var tbsCertificate: TBSCertificate
    public var signatureAlgorithm: SecKeyAlgorithm?
    public var signature: Data?

    enum CodingKeys: String, CodingKey {
        case tbsCertificate = "tbsCertificate"
        case signatureAlgorithm = "signatureAlgorithm"
        case signature = "signatureValue"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tbsCertificate = try container.decode(TBSCertificate.self, forKey: .tbsCertificate)
        
        var algorithmContainer = try container.nestedUnkeyedContainer(forKey: .signatureAlgorithm)
        if let signatureAlgorithmOID = try algorithmContainer.decodeIfPresent(OID.self) {
            
            let _ = try algorithmContainer.decodeNil()
            
            let signatureAlgorithm: SecKeyAlgorithm
            
            switch signatureAlgorithmOID {
            case .sha1WithRSAEncryption:
                signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA1
            case .sha224WithRSAEncryption:
                signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA224
            case .sha256WithRSAEncryption:
                signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
            case .sha384WithRSAEncryption:
                signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA384
            case .sha512WithRSAEncryption:
                signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
            case .ecdsa_with_SHA1:
                signatureAlgorithm = .ecdsaSignatureMessageX962SHA1
            case .ecdsa_with_SHA224:
                signatureAlgorithm = .ecdsaSignatureMessageX962SHA224
            case .ecdsa_with_SHA256:
                signatureAlgorithm = .ecdsaSignatureMessageX962SHA256
            case .ecdsa_with_SHA384:
                signatureAlgorithm = .ecdsaSignatureMessageX962SHA384
            case .ecdsa_with_SHA512:
                signatureAlgorithm = .ecdsaSignatureMessageX962SHA512
            default:
                throw DecodingError.typeMismatch(OID.self, DecodingError.Context(codingPath: algorithmContainer.codingPath, debugDescription: "Unsupported encryption type: \(signatureAlgorithmOID)"))
            }
            self.signatureAlgorithm = signatureAlgorithm
            
            self.signature = try container.decode(Data.self, forKey: .signature)
        }

    }
    
//    public func verify() throws -> Bool {
//
//        guard let signatureAlgorithm = self.signatureAlgorithm else {
//            throw NSError(domain: "Security", code: Int(errSecInvalidAlgorithm), userInfo: nil)
//        }
//
//        guard let signatureData = self.signature else {
//            throw NSError(domain: "Security", code: Int(errSecInvalidSignature), userInfo: nil)
//        }
//
//        let encoder = DEREncoder()
//        let tbsData = try encoder.encode(tbsCertificate)
//
//        let publicKey = tbsCertificate.publicKey
//
//        var error: Unmanaged<CFError>?
//        let result = SecKeyVerifySignature(publicKey, signatureAlgorithm, criData as CFData, signatureData as CFData, &error)
//        if let error = error {
//            throw error.takeRetainedValue()
//        }
//
//        return result
//    }
}


public struct TBSCertificate : Decodable, DERTagAware {
    
    public static var tag: DERTagOptions? = nil
    
    public static var childTagStrategy: DERTagStrategy? = TagStrategy()

    public enum Version: Int, Comparable, Codable {
        public static func < (lhs: TBSCertificate.Version, rhs: TBSCertificate.Version) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        case v1 = 0
        case v2 = 1
        case v3 = 2
        
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let rawValue = try container.decode(Int.self)
            self.init(rawValue: rawValue)!
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(rawValue)
        }
    }
    
    public struct Extension: Decodable {
        let id: OID
        let critical: Bool
        let value: Data
        
        public init(id: OID, critical: Bool, value: Data) {
            self.id = id
            self.critical = critical
            self.value = value
        }

        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            self.id = try container.decode(OID.self)
            self.critical = try container.decodeIfPresent(Bool.self) ?? false
            self.value = try container.decode(Data.self)
        }
        
    }

    public let version: Version
    
    public let serialNumber: BInt
    
    public let signatureAlgorithm: SecKeyAlgorithm
    
    public let issuer: DistinguishedName
    
    public let notBefore: Date
    
    public let notAfter: Date
    
    public let subject: DistinguishedName
    
    public var publicKey: SecKey
    
    public var issuerUniqueIdentifier: Data?
    
    public var subjectUniqueIdentifier: Data?
    
    public var extensions: [Extension]?
    
    enum CodingKeys: String, CodingKey {
        case version = "version"
        case serialNumber = "serialNumber"
        case signatureAlgorithm = "signature"
        case issuer = "issuer"
        case validity = "validity"
        case subject = "subject"
        case subjectPublicKeyInfo = "subjectPublicKeyInfo"
        case algorithm = "algorithm"
        case subjectPublicKey = "subjectPublicKey"
        case issuerUniqueID = "issuerUniqueID"
        case subjectUniqueID = "subjectUniqueID"
        case extensions = "extensions"
    }
    
    
    class TagStrategy : DefaultDERTagStrategy {
        
        override func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions {
            
            if let lastKey = codingPath.last as? CodingKeys {
                switch lastKey {
                case .version:
                    // version [0] EXPLICIT Version DEFAULT v1,
                    return DERTagOptions.contextSpecific(0)
                case .issuerUniqueID:
                    // issuerUniqueID [1] IMPLICIT UniqueIdentifier OPTIONAL,
                    return DERTagOptions.contextSpecific(1)
                case .subjectUniqueID:
                    // subjectUniqueID [2] IMPLICIT UniqueIdentifier OPTIONAL,
                    return DERTagOptions.contextSpecific(2)
                case .extensions:
                    // extensions [3] EXPLICIT Extensions OPTIONAL
                    return DERTagOptions.contextSpecific(3)
                default:
                    break
                }
            }
            
            return super.tag(forType: type, atPath: codingPath)
        }
        
    }
    
    public init(from decoder: Decoder) throws {
        
        
        //    TBSCertificate ::= SEQUENCE {
        //        version [0] EXPLICIT Version DEFAULT v1,
        //        serialNumber CertificateSerialNumber,
        //        signature AlgorithmIdentifier,
        //        issuer Name,
        //        validity Validity,
        //        subject Name,
        //        subjectPublicKeyInfo SubjectPublicKeyInfo,
        //        issuerUniqueID [1] IMPLICIT UniqueIdentifier OPTIONAL,
        //        subjectUniqueID [2] IMPLICIT UniqueIdentifier OPTIONAL,
        //        extensions [3] EXPLICIT Extensions OPTIONAL }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.version = try container.decodeIfPresent(Version.self, forKey: .version) ?? .v1
        self.serialNumber = try container.decode(BInt.self, forKey: .serialNumber)
        
        var signatureAlgorithmContainer = try container.nestedUnkeyedContainer(forKey: .signatureAlgorithm)
        
        let signatureAlgorithmOID = try signatureAlgorithmContainer.decode(OID.self)
        
        switch signatureAlgorithmOID {
        case .sha1WithRSAEncryption:
            signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA1
        case .sha224WithRSAEncryption:
            signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA224
        case .sha256WithRSAEncryption:
            signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
        case .sha384WithRSAEncryption:
            signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA384
        case .sha512WithRSAEncryption:
            signatureAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
        case .ecdsa_with_SHA1:
            signatureAlgorithm = .ecdsaSignatureMessageX962SHA1
        case .ecdsa_with_SHA224:
            signatureAlgorithm = .ecdsaSignatureMessageX962SHA224
        case .ecdsa_with_SHA256:
            signatureAlgorithm = .ecdsaSignatureMessageX962SHA256
        case .ecdsa_with_SHA384:
            signatureAlgorithm = .ecdsaSignatureMessageX962SHA384
        case .ecdsa_with_SHA512:
            signatureAlgorithm = .ecdsaSignatureMessageX962SHA512
        default:
            throw DecodingError.typeMismatch(OID.self, DecodingError.Context(codingPath: signatureAlgorithmContainer.codingPath, debugDescription: "Unsupported encryption type: \(signatureAlgorithmOID)"))
        }
        
        let _ = try signatureAlgorithmContainer.decodeNil()
        
        self.issuer = try container.decode(DistinguishedName.self, forKey: .issuer)
        
        var validityContainer = try container.nestedUnkeyedContainer(forKey: .validity)
        
        self.notBefore = try validityContainer.decode(Date.self)
        self.notAfter = try validityContainer.decode(Date.self)        
        
        self.subject = try container.decode(DistinguishedName.self, forKey: .subject)
        
        let subjectPKInfoContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .subjectPublicKeyInfo)
        
        var algorithmContainer = try subjectPKInfoContainer.nestedUnkeyedContainer(forKey: .algorithm)
        let algorithmOID = try algorithmContainer.decode(OID.self)
        let _ = try algorithmContainer.decodeNil()
        let keyData = try subjectPKInfoContainer.decode(Data.self, forKey: .subjectPublicKey)
        
        var attributes: [CFString : Any] = [
            kSecAttrKeyClass: kSecAttrKeyClassPublic
        ]

        switch algorithmOID {
        case .rsaEncryption:
            attributes[kSecAttrKeyType] = kSecAttrKeyTypeRSA
        case .id_ecPublicKey:
            attributes[kSecAttrKeyType] = kSecAttrKeyTypeECSECPrimeRandom
        default:
            throw DecodingError.typeMismatch(OID.self, DecodingError.Context(codingPath: subjectPKInfoContainer.codingPath, debugDescription: "Unsupported encryption type: \(algorithmOID)"))
        }
        
        
        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.subjectPublicKey, in: subjectPKInfoContainer, debugDescription: "Could not read public key")
        }
        if let error = error {
            throw error.takeRetainedValue()
        }
        self.publicKey = publicKey
        
        if self.version >= .v2 {
        
            self.issuerUniqueIdentifier = try container.decodeIfPresent(Data.self, forKey: .issuerUniqueID)
            self.subjectUniqueIdentifier = try container.decodeIfPresent(Data.self, forKey: .subjectUniqueID)
            
            if self.version >= .v3 {
                
                do {
                    var extensionsContainer = try container.nestedUnkeyedContainer(forKey: .extensions)
                    self.extensions = try extensionsContainer.decode([Extension].self)
                    
                } catch is DecodingError {
                    
                }
                
                
            }
            
        }
        
    }
    
    

}

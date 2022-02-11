//
//  Certificate.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/14/21.
//

import Foundation

public struct Certificate : Codable {
    
    public var tbsCertificate: TBSCertificate
    public var signatureAlgorithm: SecKeyAlgorithm?
    public var signature: Data?

    enum CodingKeys: String, CodingKey {
        case tbsCertificate = "tbsCertificate"
        case signatureAlgorithm = "signatureAlgorithm"
        case signature = "signatureValue"
    }
    
    public init(tbsCertificate: TBSCertificate) {
        self.tbsCertificate = tbsCertificate
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
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tbsCertificate, forKey: .tbsCertificate)
        
        if let signature = self.signature, let signatureAlgorithm = self.signatureAlgorithm {

            var algorithmContainer = container.nestedUnkeyedContainer(forKey: .signatureAlgorithm)
            
            switch signatureAlgorithm {
            case .rsaSignatureMessagePKCS1v15SHA1:
                try algorithmContainer.encode(OID.sha1WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA224:
                try algorithmContainer.encode(OID.sha224WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA256:
                try algorithmContainer.encode(OID.sha256WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA384:
                try algorithmContainer.encode(OID.sha384WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA512:
                try algorithmContainer.encode(OID.sha512WithRSAEncryption)
            case .ecdsaSignatureMessageX962SHA1:
                try algorithmContainer.encode(OID.ecdsa_with_SHA1)
            case .ecdsaSignatureMessageX962SHA224:
                try algorithmContainer.encode(OID.ecdsa_with_SHA224)
            case .ecdsaSignatureMessageX962SHA256:
                try algorithmContainer.encode(OID.ecdsa_with_SHA256)
            case .ecdsaSignatureMessageX962SHA384:
                try algorithmContainer.encode(OID.ecdsa_with_SHA384)
            case .ecdsaSignatureMessageX962SHA512:
                try algorithmContainer.encode(OID.ecdsa_with_SHA512)
            default:
                throw EncodingError.invalidValue(signatureAlgorithm,
                                                 EncodingError.Context(codingPath: [], debugDescription: "Unsupported signing algorithm"))

            }
            try algorithmContainer.encodeNil()
            
            try container.encode(signature, forKey: .signature)
            
        }
    }
    
    public mutating func sign(privateKey: SecKey, algorithm: SecKeyAlgorithm) throws {
        
        signatureAlgorithm = algorithm
        
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw NSError(domain: "Security", code: Int(errSecAlgorithmMismatch), userInfo: nil)
        }
        
        
        let encoder = DEREncoder()
        
        let criData = try encoder.encode(tbsCertificate)
        
        var error: Unmanaged<CFError>?
        signature = SecKeyCreateSignature(privateKey, algorithm, criData as CFData, &error) as Data?
        if let error = error {
            throw error.takeRetainedValue()
        }
        
    }
    
    public func verify() throws -> Bool {
        
        guard let signatureAlgorithm = self.signatureAlgorithm else {
            throw NSError(domain: "Security", code: Int(errSecInvalidAlgorithm), userInfo: nil)
        }
        
        guard let signatureData = self.signature else {
            throw NSError(domain: "Security", code: Int(errSecInvalidSignature), userInfo: nil)
        }
        
        let encoder = DEREncoder()
        let tbsCertData = try encoder.encode(tbsCertificate)
        
        let publicKey = tbsCertificate.publicKey
        
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(publicKey, signatureAlgorithm, tbsCertData as CFData, signatureData as CFData, &error)
        if let error = error {
            throw error.takeRetainedValue()
        }

        return result
    }
    
}


public struct TBSCertificate : Codable, DERTagAware {
    
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
    
    public struct Extension: Codable, DERTagAware {
        public static var tag: DERTagOptions? = nil
        public static var childTagStrategy: DERTagStrategy? = TagStrategy()
        
        class TagStrategy : DefaultDERTagStrategy {
            override func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions {
                if value is Data {
                    return .OCTET_STRING
                }
                return super.tag(forValue: value, atPath: codingPath)
            }
        }
        
        
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
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(id)
            if critical {
                try container.encode(critical)
            }
            try container.encode(value)
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
        
        override func tag(forPath codingPath: [CodingKey]) -> DERTagOptions {
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
            return super.tag(forPath: codingPath)
        }
        
        override func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions {
            
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

            return super.tag(forValue: value, atPath: codingPath)
        }
        
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
    
    public init(version: Version = .v1,
                signatureAlgorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA1,
                serialNumber: BInt,
                issuer: DistinguishedName,
                notBefore: Date,
                notAfter: Date,
                subject: DistinguishedName,
                publicKey: SecKey) {
        self.version = version
        self.serialNumber = serialNumber
        self.signatureAlgorithm = signatureAlgorithm
        self.issuer = issuer
        self.notBefore = notBefore
        self.notAfter = notAfter
        self.subject = subject
        self.publicKey = publicKey
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if version > .v1 {
            try container.encode(version, forKey: .version)
        }
        try container.encode(serialNumber, forKey: .serialNumber)
        
        var signatureAlgorithmContainer = container.nestedUnkeyedContainer(forKey: .signatureAlgorithm)
        
        switch signatureAlgorithm {
        case .rsaSignatureMessagePKCS1v15SHA1:
            try signatureAlgorithmContainer.encode(OID.sha1WithRSAEncryption)
        case .rsaSignatureMessagePKCS1v15SHA224:
            try signatureAlgorithmContainer.encode(OID.sha224WithRSAEncryption)
        case .rsaSignatureMessagePKCS1v15SHA256:
            try signatureAlgorithmContainer.encode(OID.sha256WithRSAEncryption)
        case .rsaSignatureMessagePKCS1v15SHA384:
            try signatureAlgorithmContainer.encode(OID.sha384WithRSAEncryption)
        case .rsaSignatureMessagePKCS1v15SHA512:
            try signatureAlgorithmContainer.encode(OID.sha512WithRSAEncryption)
        case .ecdsaSignatureMessageX962SHA1:
            try signatureAlgorithmContainer.encode(OID.ecdsa_with_SHA1)
        case .ecdsaSignatureMessageX962SHA224:
            try signatureAlgorithmContainer.encode(OID.ecdsa_with_SHA224)
        case .ecdsaSignatureMessageX962SHA256:
            try signatureAlgorithmContainer.encode(OID.ecdsa_with_SHA256)
        case .ecdsaSignatureMessageX962SHA384:
            try signatureAlgorithmContainer.encode(OID.ecdsa_with_SHA384)
        case .ecdsaSignatureMessageX962SHA512:
            try signatureAlgorithmContainer.encode(OID.ecdsa_with_SHA512)
        default:
            throw EncodingError.invalidValue(signatureAlgorithm,
                                             EncodingError.Context(codingPath: [], debugDescription: "Unsupported signing algorithm"))

        }
        try signatureAlgorithmContainer.encodeNil()
        
        try container.encode(issuer, forKey: .issuer)
        
        var validityContainer = container.nestedUnkeyedContainer(forKey: .validity)
        try validityContainer.encode(notBefore)
        try validityContainer.encode(notAfter)


        try container.encode(subject, forKey: .subject)
        
        let attrs = SecKeyCopyAttributes(publicKey) as! [CFString:Any]
        let keyType = attrs[kSecAttrKeyType] as! CFString

        var subjectPKInfoContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .subjectPublicKeyInfo)

        var algorithmContainer = subjectPKInfoContainer.nestedUnkeyedContainer(forKey: .algorithm)
        
        switch keyType {
        case kSecAttrKeyTypeRSA:
            try algorithmContainer.encode(OID.rsaEncryption)
        case kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeyTypeEC:
            try algorithmContainer.encode(OID.id_ecPublicKey)
        default:
            throw EncodingError.invalidValue(keyType,
                                             EncodingError.Context(codingPath: [], debugDescription: "Unsupported key algorithm"))
        }
        try algorithmContainer.encodeNil()

        
        var error: Unmanaged<CFError>?
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw EncodingError.invalidValue(publicKey,
                                             EncodingError.Context(codingPath: [], debugDescription: "Could not encode public key data"))

        }
        if let error = error {
            throw error.takeRetainedValue()
        }

        try subjectPKInfoContainer.encode(keyData, forKey: .subjectPublicKey)

        if self.version >= .v2 {
        
            if let issuerUniqueIdentifier = self.issuerUniqueIdentifier {
                try container.encode(issuerUniqueIdentifier, forKey: .issuerUniqueID)
            }
            
            if let subjectUniqueIdentifier = self.subjectUniqueIdentifier {
                try container.encode(subjectUniqueIdentifier, forKey: .subjectUniqueID)
            }
            
            if self.version >= .v3 {
                if let extensions = self.extensions {
                    var extensionsContainer = container.nestedUnkeyedContainer(forKey: .extensions)
                    try extensionsContainer.encode(extensions)
                }
            }
        }
    }
    

}

//
//  CertificationRequest.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

public struct CertificationRequest : Codable {
    
    public let certificationRequestInfo: CertificationRequestInfo
    public var signatureAlgorithm: SecKeyAlgorithm?
    public var signature: Data?
    
    public init(info: CertificationRequestInfo) {
        self.certificationRequestInfo = info
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        certificationRequestInfo = try container.decode(CertificationRequestInfo.self, forKey: .certificationRequestInfo)
        
        let algorithmIdentifier = try container.decode(AlgorithmIdentifier.self, forKey: .signatureAlgorithm)
        
        guard let signatureAlgorithm = algorithmIdentifier.signatureAlgorithm() else {
            throw DecodingError.typeMismatch(OID.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported encryption type: \(algorithmIdentifier)"))
        }
        
        self.signatureAlgorithm = signatureAlgorithm
        self.signature = try container.decode(Data.self, forKey: .signature)
    }
    
    public mutating func sign(privateKey: SecKey, algorithm: SecKeyAlgorithm) throws {
        
        signatureAlgorithm = algorithm
        
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw NSError(domain: "Security", code: Int(errSecAlgorithmMismatch), userInfo: nil)
        }
        
        
        let encoder = DEREncoder()
        
        let criData = try encoder.encode(certificationRequestInfo)
        
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
        let criData = try encoder.encode(certificationRequestInfo)
        
        let publicKey = certificationRequestInfo.publicKey
        
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(publicKey, signatureAlgorithm, criData as CFData, signatureData as CFData, &error)
        if let error = error {
            throw error.takeRetainedValue()
        }

        return result
    }
    
    enum CodingKeys: String, CodingKey {
        case certificationRequestInfo = "certificationRequestInfo"
        case signatureAlgorithm = "signatureAlgorithm"
        case signature = "signature"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(certificationRequestInfo, forKey: .certificationRequestInfo)
        
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

}


public struct CertificationRequestInfo : Codable, DERTagAware {
    
    public static var tag: DERTagOptions? = .SEQUENCE
    
    public static var childTagStrategy: DERTagStrategy? = TagStrategy()
    
    public enum Version: Int {
        case v1 = 0
    }
    
    public var version = Version.v1
    public var subject: DistinguishedName
    public var publicKey: SecKey
    public var attributes = [Attribute<String>]()
    
    public init(subject: DistinguishedName, publicKey: SecKey) {
        self.subject = subject
        self.publicKey = publicKey
    }

    enum CodingKeys: String, CodingKey {
        case version = "version"
        case subject = "subject"
        case subjectPKInfo = "subjectPKInfo"
        case attributes = "attributes"
        case algorithm = "algorithm"
        case subjectPublicKey = "subjectPublicKey"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let versionRaw = try container.decode(Int.self, forKey: .version)
        self.version = Version(rawValue: versionRaw) ?? .v1
        self.subject = try container.decode(DistinguishedName.self, forKey: .subject)
        
        let subjectPKInfoContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .subjectPKInfo)
        
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
        
        self.attributes = try container.decode([Attribute<String>].self, forKey: .attributes)
        
    }
    
    public class TagStrategy : DefaultDERTagStrategy {
        
        public override func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions {
            if let lastKey = codingPath.last as? CodingKeys {
                if lastKey == .attributes {
                    // attributes    [0] Attributes{{ CRIAttributes }}
                    return DERTagOptions.contextSpecific(0)
                }
            }

            return super.tag(forType: type, atPath: codingPath)
        }
        
        public override func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions {
            
            if let lastKey = codingPath.last as? CodingKeys {
                if lastKey == .attributes {
                    // attributes    [0] Attributes{{ CRIAttributes }}
                    return DERTagOptions.contextSpecific(0)
                }
            }
            return super.tag(forValue: value, atPath: codingPath)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version.rawValue, forKey: .version)
        try container.encode(subject, forKey: .subject)
        
        
        let attrs = SecKeyCopyAttributes(publicKey) as! [CFString:Any]
        let keyType = attrs[kSecAttrKeyType] as! CFString

        var subjectPKInfoContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .subjectPKInfo)

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
        
        try container.encode(attributes, forKey: .attributes)
        
    }
    
}

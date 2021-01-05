//
//  CertificationRequest.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

struct CertificationRequest : Encodable {
    
    let certificationRequestInfo: CertificationRequestInfo
    var signatureAlgorithm: SecKeyAlgorithm?
    var signature: Data?
    
    init(info: CertificationRequestInfo) {
        self.certificationRequestInfo = info
    }
    
    
    mutating func sign(privateKey: SecKey, algorithm: SecKeyAlgorithm) throws {
        
        signatureAlgorithm = algorithm
        
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw NSError(domain: "Security", code: Int(errSecAlgorithmMismatch), userInfo: nil)
        }
        
        
        let encoder = DEREncoder()
        encoder.tagStrategy = CertificationRequest.TagStrategy()
        
        let criData = try encoder.encode(certificationRequestInfo)
        
        var error: Unmanaged<CFError>?
        signature = SecKeyCreateSignature(privateKey, algorithm, criData as CFData, &error) as Data?
        if let error = error {
            throw error.takeRetainedValue()
        }
        
    }
    
    enum CodingKeys: String, CodingKey {
        case certificationRequestInfo = "certificationRequestInfo"
        case signatureAlgorithm = "signatureAlgorithm"
        case signature = "signature"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(certificationRequestInfo, forKey: .certificationRequestInfo)
        
        if let signature = self.signature, let signatureAlgorithm = self.signatureAlgorithm {
            
            
            var algorithmContainer = container.nestedUnkeyedContainer(forKey: .signatureAlgorithm)
            
            switch signatureAlgorithm {
            case .rsaSignatureMessagePKCS1v15SHA1:
                try algorithmContainer.encode(ObjectIdentifier.sha1WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA224:
                try algorithmContainer.encode(ObjectIdentifier.sha224WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA256:
                try algorithmContainer.encode(ObjectIdentifier.sha256WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA384:
                try algorithmContainer.encode(ObjectIdentifier.sha384WithRSAEncryption)
            case .rsaSignatureMessagePKCS1v15SHA512:
                try algorithmContainer.encode(ObjectIdentifier.sha512WithRSAEncryption)
            case .ecdsaSignatureMessageX962SHA1:
                try algorithmContainer.encode(ObjectIdentifier.ecdsa_with_SHA1)
            case .ecdsaSignatureMessageX962SHA224:
                try algorithmContainer.encode(ObjectIdentifier.ecdsa_with_SHA224)
            case .ecdsaSignatureMessageX962SHA256:
                try algorithmContainer.encode(ObjectIdentifier.ecdsa_with_SHA256)
            case .ecdsaSignatureMessageX962SHA384:
                try algorithmContainer.encode(ObjectIdentifier.ecdsa_with_SHA384)
            case .ecdsaSignatureMessageX962SHA512:
                try algorithmContainer.encode(ObjectIdentifier.ecdsa_with_SHA512)
            default:
                throw EncodingError.invalidValue(signatureAlgorithm,
                                                 EncodingError.Context(codingPath: [], debugDescription: "Unsupported signing algorithm"))

            }
            try algorithmContainer.encodeNil()
            
            try container.encode(signature, forKey: .signature)
            
        }
        
    }

    
    class TagStrategy : CertificationRequestInfo.TagStrategy { }
}


struct CertificationRequestInfo : Encodable {
    
    enum Version: Int {
        case v1 = 0
    }
    
    var version = Version.v1
    var subject: DistinguishedName
    var publicKey: SecKey
    var attributes = [Attribute<String>]()
    
    init(subject: DistinguishedName, publicKey: SecKey) {
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
    
    class TagStrategy : DefaultDERTagStrategy {
        
        override func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions {
            
            if let lastKey = codingPath.last as? CodingKeys {
                if lastKey == .attributes {
                    // attributes    [0] Attributes{{ CRIAttributes }}
                    return DERTagOptions.contextSpecific(0)
                }
            }
            return super.tag(forValue: value, atPath: codingPath)
        }
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version.rawValue, forKey: .version)
        try container.encode(subject, forKey: .subject)
        
        
        let attrs = SecKeyCopyAttributes(publicKey) as! [CFString:Any]
        let keyType = attrs[kSecAttrKeyType] as! CFString

        var subjectPKInfoContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .subjectPKInfo)

        var algorithmContainer = subjectPKInfoContainer.nestedUnkeyedContainer(forKey: .algorithm)
        
        switch keyType {
        case kSecAttrKeyTypeRSA:
            try algorithmContainer.encode(ObjectIdentifier.rsaEncryption)
        case kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeyTypeEC:
            try algorithmContainer.encode(ObjectIdentifier.id_ecPublicKey)
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

//
//  PKCS7Container.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/3/25.
//
import Foundation
import CryptoKit

public struct PKCS7Container: Decodable, DERTagAware {

    public static var tag: DERTagOptions? {
        return .SEQUENCE
    }

    public static var childTagStrategy: DERTagStrategy? {
        return TagStrategy()
    }

    
    public let version: Int
    public let digestAlgorithms: Set<AlgorithmIdentifier>
    
    public let data: Data
    
    public let certificates: Array<SecCertificate>
    public let signerInfo: Array<SignerInfo>

    private enum CodingKeys: String, CodingKey {
        case signedDataContent = "signedDataContent"
        case content = "content"
        case signedData = "SignedData"
        case version = "CMSVersion"
        case digestAlgorithms = "digestAlgorithms"
        case encapContentInfo = "encapContentInfo"
        case contentType = "contentType"
        case eContentType = "eContentType"
        case wrappedData = "wrappedData"
        case certificates = "certificates"
        case signerInfos = "signerInfos"
    }
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let contentType = try container.decode(OID.self, forKey: .contentType)
        
        guard contentType == OID.pkcs7_signedData else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.contentType, in: container, debugDescription: "Only supports signed data")
        }
        
        var signedDataContent = try container.nestedUnkeyedContainer(forKey: .signedDataContent)
        let signedData = try signedDataContent.nestedContainer(keyedBy: CodingKeys.self)
        
        self.version = try signedData.decode(Int.self, forKey: .version)
        self.digestAlgorithms = try container.decode(Set<AlgorithmIdentifier>.self, forKey: .digestAlgorithms)

        let encapContentInfo = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .encapContentInfo)
        let eContentType = try encapContentInfo.decode(OID.self, forKey: .eContentType)
        
        guard eContentType == .pkcs7_data else {
            throw DecodingError.dataCorruptedError(forKey: .contentType, in: encapContentInfo, debugDescription: "Unsupported content type \(eContentType)")
        }
        
        let eContent = try encapContentInfo.nestedContainer(keyedBy: CodingKeys.self, forKey: .content)
        data = try eContent.decode(Data.self, forKey: .content)

        var certificateSequence = try signedData.nestedUnkeyedContainer(forKey: .certificates)
        
        var certs = [SecCertificate]()
        
        while !certificateSequence.isAtEnd {
            var certData = try certificateSequence.decode(Data.self)
            // Decoding as Data "uses up" the header, but it's needed to be a proper cert, so we put it back
            let wrapper = DERPrimitive(tag: .SEQUENCE, value: certData)
            certData = wrapper.toData()
            guard let cert = SecCertificateCreateWithData(nil, certData as CFData) else {
                throw DecodingError.dataCorruptedError(in: signedDataContent, debugDescription: "Could not read certificate")
            }
            certs.append(cert)
        }
        
        self.certificates = certs
        
        self.signerInfo = try signedData.decode(Array<SignerInfo>.self, forKey: .signerInfos)
    }
    
    public func getContent<T>(as contentType: T.Type) throws -> T? where T : Decodable {
        let decoder = DERDecoder()
        return try decoder.decode(contentType, from: self.data)
    }
    
    
    public func verifyTrust(rootCert: SecCertificate, certChain: [SecCertificate], verifyDate: Date) throws {
        
        let policy = SecPolicyCreateBasicX509()
        
        var trust: SecTrust!
        
        let extCertChain: [SecCertificate] = certChain + [rootCert]

        try SecTrustCreateWithCertificates(extCertChain as AnyObject, policy, &trust).check()
        try SecTrustSetAnchorCertificates(trust, [rootCert] as CFArray).check()
        SecTrustSetVerifyDate(trust, verifyDate as CFDate)
        
        var error: CFError?
        if #available(macOS 10.14, *) {
            guard SecTrustEvaluateWithError(trust, &error) else {
                if let error = error {
                    throw error
                }
                throw ValidationError.certificateNotTrusted
            }

        } else {
            
            var trustResult = SecTrustResultType(rawValue: 0)!
            SecTrustEvaluate(trust, &trustResult)
            
            switch trustResult {
            case .proceed:
                return
            case .unspecified:
                return
            default:
                throw ValidationError.certificateNotTrusted
            }
            
        }
    }
    
    public func verify(rootCert: SecCertificate, verifyDate: Date) throws {
        
        guard self.signerInfo.count > 0 else  {
            // Has to be at least one signer
            throw ValidationError.containerNotSigned
        }
   
        for signerInfo in self.signerInfo {

            guard let signatureAlgorithm = signerInfo.signatureAlgorithm else {
                throw ValidationError.missingSignatureAlgorithm
            }

            let signatureData = signerInfo.signature
            
            try verifyTrust(rootCert: rootCert, certChain: self.certificates, verifyDate: verifyDate)
            
            guard let signerCert = certificates.first else {
                throw ValidationError.missingData(field: "certificate")
            }
            
            guard let publicKey = signerCert.publicKey() else {
                throw ValidationError.missingCertificate(serial: signerInfo.serialNumber)
            }
            
            var error: Unmanaged<CFError>?
            let verified = SecKeyVerifySignature(publicKey, signatureAlgorithm, self.data as CFData, signatureData as CFData, &error)
            if let error = error {
                throw error.takeRetainedValue()
            }
            
            guard verified else {
                throw ValidationError.signatureInvalid
            }
        }
    }
    
    
    private class TagStrategy : DefaultDERTagStrategy {
        
        public override func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions {
            if let lastKey = codingPath.last as? CodingKeys {
                if lastKey == .content {
                    //content [0] EXPLICIT ANY DEFINED BY contentType OPTIONAL }
                    return DERTagOptions.contextSpecific(0)
                }
                
                if lastKey == .certificates {
                    return DERTagOptions.contextSpecific(0)
                }
                
                if lastKey == .signerInfos {
                    return .SET
                }
            }
            
            if type is Data.Type, codingPath.contains(where: { $0.stringValue == "certificates" }) {
                return .SEQUENCE
            }

            return super.tag(forType: type, atPath: codingPath)
        }

    }

    public struct SignerInfo: Decodable, Hashable {
        
        public let version: Int
        public let issuer: DistinguishedName
        public let serialNumber: BInt
        public let digestAlgorithm: AlgorithmIdentifier
        public var signatureAlgorithm: SecKeyAlgorithm?
        public let signature: Data
        
        enum CodingKeys: String, CodingKey {
            case version = "version"
            case sid = "sid"
            case issuer = "issuer"
            case serial = "serial"
            case digestAlgorithm = "digestAlgorithm"
            case signatureAlgorithm = "signatureAlgorithm"
            case signature = "signatureValue"
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.version = try container.decode(Int.self, forKey: .version)
            
            let signerIdentifier = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .sid)
            self.issuer = try signerIdentifier.decode(DistinguishedName.self, forKey: .issuer)
            self.serialNumber = try signerIdentifier.decode(BInt.self, forKey: .serial)
            self.digestAlgorithm = try container.decode(AlgorithmIdentifier.self, forKey: .digestAlgorithm)
            
            let algorithmIdentifier = try container.decode(AlgorithmIdentifier.self, forKey: .signatureAlgorithm)
            self.signatureAlgorithm = algorithmIdentifier.signatureAlgorithm(digestAlgorithm: digestAlgorithm)
            
            self.signature = try container.decode(Data.self, forKey: .signature)
        }

        
    }

}

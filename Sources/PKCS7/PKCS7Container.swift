//
//  PKCS7Container.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/3/25.
//
import CryptoKit

@available(macOS 10.15, *)
public struct PKCS7Container: Decodable, DERTagAware {

    public static var tag: DERTagOptions? {
        return .SEQUENCE
    }

    public static var childTagStrategy: DERTagStrategy? {
        return TagStrategy()
    }

    
    public let version: Int
    public let digestAlgorithms: Set<AlgorithmIdentifier>
    
    public let digest: (any HashFunction)?
    
    public let data: Data
    
    public let certificates: Array<Certificate>
    public let signerInfo: Array<SignerInfo>

    enum CodingKeys: String, CodingKey {
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

        digestAlgorithms = try container.decode(Set<AlgorithmIdentifier>.self, forKey: .digestAlgorithms)
        switch digestAlgorithms.first?.identifier {
        case .SHA256:
            self.digest = SHA256()
        default:
            self.digest = nil
        }
        
        
        let encapContentInfo = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .encapContentInfo)
        let eContentType = try encapContentInfo.decode(OID.self, forKey: .eContentType)
        
        guard eContentType == .pkcs7_data else {
            throw DecodingError.dataCorruptedError(forKey: .contentType, in: encapContentInfo, debugDescription: "Unsupported content type \(eContentType)")
        }
        
        let eContent = try encapContentInfo.nestedContainer(keyedBy: CodingKeys.self, forKey: .content)
        data = try eContent.decode(Data.self, forKey: .content)

        
        self.certificates = try signedData.decodeIfPresent(Array<Certificate>.self, forKey: .certificates) ?? []
        self.signerInfo = try signedData.decode(Array<SignerInfo>.self, forKey: .signerInfos)
    }
    
    public func getContent<T>(as contentType: T.Type) throws -> T? where T : Decodable {
        let decoder = DERDecoder()
        return try decoder.decode(contentType, from: self.data)
    }
    
    
    public class TagStrategy : DefaultDERTagStrategy {
        
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

            return super.tag(forType: type, atPath: codingPath)
        }

    }

    public struct SignerInfo: Decodable, Hashable {
        
        public let version: Int
        public let issuer: DistinguishedName
        public let serialNumber: BInt
        public let digestAlgorithm: AlgorithmIdentifier
        public let signatureAlgorithm: AlgorithmIdentifier
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
            self.signatureAlgorithm = try container.decode(AlgorithmIdentifier.self, forKey: .signatureAlgorithm)
            self.signature = try container.decode(Data.self, forKey: .signature)
        }

        
    }

}

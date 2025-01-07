//
//  MASReceipt.swift
//  Mac ASN1Codable
//
//  Created by Weston Bustraan on 1/3/25.
//

import Foundation

public struct AppReceipt: Decodable, DERTagAware {
    
    public static var tag: DERTagOptions? = .SET
    
    public static var childTagStrategy: (any DERTagStrategy)?
    
    var attributes: Dictionary<Int, ReceiptAttribute>

    /** The app’s bundle identifier. */
    public var bundleId: String? {
        attributes[2]?.stringValue
    }
    
    public var bundleIdData: Data? {
        attributes[2]?.data
    }
    
    /** The app’s version number.  */
    public var applicationVersion: String? {
        attributes[3]?.stringValue
    }
    
    /** An opaque value used, with other data, to compute the SHA-1 hash during validation.  */
    public var opaqueValue: Data? {
        attributes[4]?.data
    }
    
    /** A SHA-1 hash, used to validate the receipt.  */
    public var sha1Digest: Data? {
        get {
            attributes[5]?.data
        }
        set {
            if let newData = newValue {
                attributes[5] = ReceiptAttribute(type: 5, data: newData)
            } else {
                attributes.removeValue(forKey: 5)
            }
            
        }
    }

    /** The receipt for an in-app purchase. */
    public var inApp: Data? {
        return nil
    }
    
    /** The version of the app that was originally purchased. */
    public var originalApplicationVersion: String? {
        attributes[19]?.stringValue
    }
    
    /** The date when the app receipt was created. */
    public var receiptCreationDate: Date? {
        if let dateString = attributes[12]?.stringValue {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: dateString)
        }
        return nil
    }
    
    /** The date that the app receipt expires. */
    public var expirationDate: Date? {
        if let dateString = attributes[21]?.stringValue {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: dateString)
        }
        return nil
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let attributeSet = try container.decode(Set<ReceiptAttribute>.self)
        
        attributes = Dictionary(uniqueKeysWithValues: attributeSet.map({ ($0.type, $0) }))
    }
    
    public struct ReceiptAttribute: Decodable, Hashable, Equatable {
        
        public let type: Int
        public let version: Int
        public let data: Data
        
        public var stringValue: String? {
            get {
                let decoder = DERDecoder()
                return try? decoder.decode(String.self, from: self.data)
            }
        }

        public var intValue: Int? {
            get {
                let decoder = DERDecoder()
                return try? decoder.decode(Int.self, from: self.data)
            }
        }

        private enum CodingKeys: CodingKey {
            case type
            case version
            case value
        }
        
        init(type: Int, version: Int = 1, data: Data) {
            self.type = type
            self.version = version
            self.data = data
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(Int.self, forKey: .type)
            self.version = try container.decode(Int.self, forKey: .version)
            self.data = try container.decode(Data.self, forKey: .value)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
        }
        
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.type == rhs.type
        }

    }
    
}

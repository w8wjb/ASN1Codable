//
//  ReceiptAttribute.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/7/25.
//
import Foundation

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

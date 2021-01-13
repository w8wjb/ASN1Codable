//
//  Attribute.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

public struct Attribute<T: Hashable & Codable> : Codable {
    public var type: OID
    public var values: Set<T>
    
    public init(type: OID, value: T) {
        self.type = type
        self.values = Set<T>([value])
    }
    
    public init(type: OID, values: T...) {
        self.type = type
        self.values = Set<T>(values)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.type = try container.decode(OID.self)
        self.values = try container.decode(Set<T>.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type)
        try container.encode(values)
    }
    
}

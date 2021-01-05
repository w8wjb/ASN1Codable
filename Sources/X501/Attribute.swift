//
//  Attribute.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

struct Attribute<T: Hashable & Encodable> : Encodable {
    var type: ObjectIdentifier
    var values: Set<T>
    
    init(type: ObjectIdentifier, value: T) {
        self.type = type
        self.values = Set<T>([value])
    }
    
    init(type: ObjectIdentifier, values: T...) {
        self.type = type
        self.values = Set<T>(values)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ObjectIdentifier.self)
        try container.encode(values, forKey: type)
    }
    
}

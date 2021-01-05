//
//  DistinguishedName.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

struct DistinguishedName : Encodable {

    typealias rdnTuple = (ObjectIdentifier, String)
    
    var names: [RelativeDistinguishedName]

    init(names: [RelativeDistinguishedName]) {
        self.names = names
    }
    
    init(_ tuples: rdnTuple...) {
        self.names = tuples.compactMap { RelativeDistinguishedName(type: $0, value: $1) }
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for name in names {
            try container.encode(name)
        }
    }
    
}

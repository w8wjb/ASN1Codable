//
//  DistinguishedName.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

struct DistinguishedName : Codable {

    typealias rdnTuple = (OID, String)
    
    var names: [RelativeDistinguishedName]

    init(names: [RelativeDistinguishedName]) {
        self.names = names
    }
    
    init(_ tuples: rdnTuple...) {
        self.names = tuples.compactMap { RelativeDistinguishedName(type: $0, value: $1) }
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.names = [RelativeDistinguishedName]()
        while !container.isAtEnd {
            self.names.append(try container.decode(RelativeDistinguishedName.self))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for name in names {
            try container.encode(name)
        }
    }
    
}

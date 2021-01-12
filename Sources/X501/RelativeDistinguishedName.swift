//
//  RelativeDistinguishedName.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

struct RelativeDistinguishedName : Codable, DERTagAware {

    static var childTagStrategy: DERTagStrategy? = nil
    static var tag: DERTagOptions? = .SET

    var type: OID
    var value: String
    
    init(type: OID, value: String) {
        self.type = type
        self.value = value
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let dict = try container.decode([OID:String].self)
        guard let (key, value) = dict.first else {
            throw DecodingError.keyNotFound(OID.self as! CodingKey, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Decoded dictionary has no entries"))
        }
        self.type = key
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode([type:value])
    }
}

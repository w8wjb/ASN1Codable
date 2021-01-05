//
//  RelativeDistinguishedName.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

struct RelativeDistinguishedName : Encodable, DERTagAware {

    static var tag: DERTagOptions = .SET

    var type: ObjectIdentifier
    var value: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ObjectIdentifier.self)
        try container.encode(value, forKey: type)
    }
}

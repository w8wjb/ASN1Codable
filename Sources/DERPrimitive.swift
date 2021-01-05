//
//  DERPrimitive.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

struct DERPrimitive: DERElement {

    var tag: UInt8
    
    var value: Data
    
    var length: Int {
        value.count
    }
    
    init(tag: DERTagOptions, value: Data) {
        self.init(tag: tag.rawValue, value: value)
    }

    init(tag: DERTagOptions, bytes: [UInt8]) {
        self.init(tag: tag.rawValue, value: Data(bytes))
    }

    
    init(tag: UInt8, value: Data) {
        self.tag = tag
        self.value = value
    }

}

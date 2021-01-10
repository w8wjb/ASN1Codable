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


struct RealOptions: OptionSet {
    static let BINARY_ENCODING = RealOptions(rawValue:      0b10000000)
    static let DECIMAL_ENCODING = RealOptions([])
    static let SPECIAL_REAL_VALUE = RealOptions(rawValue:   0b01000000)
    static let BASE_2 = RealOptions([])
    static let BASE_8 = RealOptions(rawValue:               0b00010000)
    static let BASE_16 = RealOptions(rawValue:              0b00100000)
    
    static let IS_NEGATIVE = RealOptions(rawValue:          0b01000000)
    
    static let PLUS_INFINITY = RealOptions([])
    static let MINUS_INFINITY = RealOptions(rawValue:       0b00000001)
    static let NOT_A_NUMBER = RealOptions(rawValue:         0b00000010)
    static let MINUS_ZERO = RealOptions(rawValue:           0b00000011)
    
    static let EXPONENT_1BYTE = RealOptions([])
    static let EXPONENT_2BYTES = RealOptions(rawValue:      0b00000001)
    static let EXPONENT_3BYTES = RealOptions(rawValue:      0b00000010)
    static let EXPONENT_XBYTES = RealOptions(rawValue:      0b00000011)
    
    let rawValue: UInt8
}

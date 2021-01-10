//
//  DERElement.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

protocol DERElement {
    var tag: UInt8 { get }
    var length: Int { get }
    var value: Data { get }
    
    func toData() -> Data
}

extension DERElement {
    
    var isConstructed: Bool {
        return (tag & 0x20) == 0x20
    }
    
    func getLengthBytes() -> [UInt8] {
                        
        var length = self.length
        if length > 127 {

            var encoded = [UInt8]()
            while length > 0 {
                encoded.append(UInt8(length & 0xFF))
                length >>= 8
            }
            encoded.append(0x80 | UInt8(encoded.count))
            return encoded.reversed()
        }
        return [UInt8(length)]
    }
    
    
    func toData() -> Data {
        var data = Data()
        data.append(tag)
        data.append(contentsOf: getLengthBytes())
        data.append(value)
        return data
    }
}

struct DERTagOptions: OptionSet, CustomStringConvertible {
    var rawValue: UInt8
    
    static let Universal = DERTagOptions([])
    static let Application = DERTagOptions(rawValue: 0b01000000)
    static let ContextSpecific = DERTagOptions(rawValue: 0b10000000)
    static let Private = DERTagOptions(rawValue: 0b11000000)
    
    static let primitive = DERTagOptions([])
    static let constructed = DERTagOptions(rawValue: 0b00100000)
    
    static let BOOLEAN = DERTagOptions(rawValue: 1)
    static let INTEGER = DERTagOptions(rawValue: 2)
    static let BIT_STRING = DERTagOptions(rawValue: 3)
    static let OCTET_STRING = DERTagOptions(rawValue: 4)
    static let NULL = DERTagOptions(rawValue: 5)
    static let OBJECT_IDENTIFIER = DERTagOptions(rawValue: 6)
    static let OBJECT_DESCRIPTOR = DERTagOptions(rawValue: 7)
    static let REAL = DERTagOptions(rawValue: 9)
    static let ENUMERATED = DERTagOptions(rawValue: 10)
    static let UTF8String = DERTagOptions(rawValue: 12)
    static let RELATIVE_OID = DERTagOptions(rawValue: 13)
    static let SEQUENCE = DERTagOptions(rawValue: 0x30) // includes constructed bit
    static let SET = DERTagOptions(rawValue: 0x31) // includes constructed bit
    static let PrintableString = DERTagOptions(rawValue: 19)
    static let IA5String = DERTagOptions(rawValue: 22)
    static let UTCTime = DERTagOptions(rawValue: 23)
    static let GeneralizedTime = DERTagOptions(rawValue: 24)
    
    var isConstructed: Bool {
        return self.contains(.constructed)
    }
    
    var description: String {
        switch self {
        case .BOOLEAN:
            return "BOOLEAN"
        case .INTEGER:
            return "INTEGER"
        case .BIT_STRING:
            return "BIT STRING"
        case .OCTET_STRING:
            return "OCTET STRING"
        case .NULL:
            return "NULL"
        case .OBJECT_IDENTIFIER:
            return "OBJECT IDENTIFIER"
        case .OBJECT_DESCRIPTOR:
            return "OBJECT DESCRIPTOR"
        case .REAL:
            return "REAL"
        case .ENUMERATED:
            return "ENUMERATED"
        case .UTF8String:
            return "UTF8String"
        case .RELATIVE_OID:
            return "RELATIVE OID"
        case .SEQUENCE:
            return "SEQUENCE"
        case .SET:
            return "SEQUENCE"
        case .PrintableString:
            return "PrintableString"
        case .IA5String:
            return "IA5String"
        case .UTCTime:
            return "UTCTime"
        case .GeneralizedTime:
            return "GeneralizedTime"
        default:
            var desc = ""
            if self.contains(.Private) {
                desc += "Private "
            } else if self.contains(.Application) {
                desc += "Application "
            } else if self.contains(.ContextSpecific) {
                desc += "Context Specific "
            }
            
            if self.contains(.constructed) {
                desc += "constructed "
            }
            
            desc += "tag \(self.rawValue)"
            return desc
        }
    }
    
    static func contextSpecific(_ rawValue: UInt8, constructed: Bool = true) -> DERTagOptions {
        var tag = DERTagOptions(rawValue: rawValue)
        tag.update(with: .ContextSpecific)
        if constructed {
            tag.update(with: .constructed)
        }
        return tag
    }
    

}

//
//  DERTagStrategy.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation


protocol DERTagStrategy {
    func tag(forPath codingPath: [CodingKey]) -> DERTagOptions
    func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions
}

protocol DERTagAware {
    static var tag: DERTagOptions { get }
}

class DefaultDERTagStrategy: DERTagStrategy {
    
    static let printableStringCharset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWYZabcdefghijklmnopqrstuvwyz0123456789 '()+,-./:=?")
    
    func tag(forPath: [CodingKey]) -> DERTagOptions {
        return .SEQUENCE
    }
    
    func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions {
        // TODO
        
        switch value {
        case is DERTagAware:
            return type(of: value as! DERTagAware).tag            
        case is Bool:
            return .BOOLEAN
        case is Int:
            return .INTEGER
        case is Int8:
            return .INTEGER
        case is Int16:
            return .INTEGER
        case is Int32:
            return .INTEGER
        case is Int64:
            return .INTEGER
        case is UInt:
            return .INTEGER
        case is UInt8:
            return .INTEGER
        case is UInt16:
            return .INTEGER
        case is UInt32:
            return .INTEGER
        case is UInt64:
            return .INTEGER
        case is Float:
            return .REAL
        case is Double:
            return .REAL
        case is Data:
            return .BIT_STRING
        case is ObjectIdentifier:
            return .OBJECT_IDENTIFIER
        case is String:
            let str = value as! String
            if CharacterSet(charactersIn: str).isSubset(of: DefaultDERTagStrategy.printableStringCharset) {
                return .PrintableString
            }
            
            if str.smallestEncoding == .ascii {
                return .IA5String
            }
            return .UTF8String
            
        default:
            
            let mirror = Mirror(reflecting: value)
            
            switch mirror.displayStyle {
            case .none:
                return .NULL
            case .set:
                return .SET
            default:
                return .SEQUENCE
            }
            
        }
        
    }

}

//
//  DERTagStrategy.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation


protocol DERTagStrategy {
    func tag(forPath codingPath: [CodingKey]) -> DERTagOptions
    func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions
    func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions
}

protocol DERTagAware {
    static var tag: DERTagOptions { get }
}

fileprivate protocol _DERSetMarker { }

extension Set : _DERSetMarker where Element: Decodable { }

class DefaultDERTagStrategy: DERTagStrategy {
    
    static let printableStringCharset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWYZabcdefghijklmnopqrstuvwyz0123456789 '()+,-./:=?")
    
    func tag(forPath: [CodingKey]) -> DERTagOptions {
        return .SEQUENCE
    }
    
    func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions {
        
        if let str = value as? String {
            if CharacterSet(charactersIn: str).isSubset(of: DefaultDERTagStrategy.printableStringCharset) {
                return .PrintableString
            }
            
            if str.smallestEncoding == .ascii {
                return .IA5String
            }
            return .UTF8String
        }
        
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
        case is Date:
            return .UTCTime
        case is OID:
            return .OBJECT_IDENTIFIER
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
    
    func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions {

        if let _ = type as? _DERSetMarker.Type {
            return .SET
        }
        
        switch type {
        case is DERTagAware.Type:
            return (type as! DERTagAware.Type).tag
        case is Bool.Type:
            return .BOOLEAN
        case is Int.Type:
            return .INTEGER
        case is Int8.Type:
            return .INTEGER
        case is Int16.Type:
            return .INTEGER
        case is Int32.Type:
            return .INTEGER
        case is Int64.Type:
            return .INTEGER
        case is UInt.Type:
            return .INTEGER
        case is UInt8.Type:
            return .INTEGER
        case is UInt16.Type:
            return .INTEGER
        case is UInt32.Type:
            return .INTEGER
        case is UInt64.Type:
            return .INTEGER
        case is Float.Type:
            return .REAL
        case is Double.Type:
            return .REAL
        case is Data.Type:
            return .BIT_STRING
        case is OID.Type:
            return .OBJECT_IDENTIFIER
        case is String.Type:
            return .UTF8String            
        default:
            return .SEQUENCE
            
        }
        
    }

}

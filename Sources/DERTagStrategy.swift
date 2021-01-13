//
//  DERTagStrategy.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation


public protocol DERTagStrategy {
    func tag(forPath codingPath: [CodingKey]) -> DERTagOptions
    func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions
    func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions
}

public protocol DERTagAware {
    
    /**
        Specify the custom DER tag for encoding and decoding objects of the implementing type
     */
    static var tag: DERTagOptions? { get }
    
    /**
     Specify a strategy to use for child objects of the implementing type
     */
    static var childTagStrategy: DERTagStrategy? { get }
    
}

fileprivate protocol _DERSetMarker { }

extension Set : _DERSetMarker where Element: Decodable { }

open class DefaultDERTagStrategy: DERTagStrategy {
    
    static let printableStringCharset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWYZabcdefghijklmnopqrstuvwyz0123456789 '()+,-./:=?")
    
    open func tag(forPath: [CodingKey]) -> DERTagOptions {
        return .SEQUENCE
    }
    
    open func tag(forValue value: Encodable, atPath codingPath: [CodingKey]) -> DERTagOptions {
        
        if let str = value as? String {
            if CharacterSet(charactersIn: str).isSubset(of: DefaultDERTagStrategy.printableStringCharset) {
                return .PrintableString
            }
            
            if str.smallestEncoding == .ascii {
                return .IA5String
            }
            return .UTF8String
        }
        
        if let tagAwareValue = value as? DERTagAware {
            if let tag = type(of: tagAwareValue).tag {
                return tag
            }
        }
        
        switch value {
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
    
    open func tag(forType type: Decodable.Type, atPath codingPath: [CodingKey]) -> DERTagOptions {

        if let _ = type as? _DERSetMarker.Type {
            return .SET
        }
        
        if let tagAwareType = type as? DERTagAware.Type, let tag = tagAwareType.tag {
            return tag
        }

        switch type {
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

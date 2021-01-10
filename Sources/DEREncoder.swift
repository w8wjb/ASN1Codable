//
//  DEREncoder.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 12/24/20.
//

import Foundation
import Combine

/**
 Top-level DER Encoder
 */
class DEREncoder : TopLevelEncoder {
    typealias Output = Data
    
    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /**
     Specifies the strategy for forming DER tags
     */
    open var tagStrategy : DERTagStrategy = DefaultDERTagStrategy()
    
    func encode<T>(_ value: T) throws -> Data where T : Encodable {
        let encoder = _DEREncoder(userInfo: userInfo, tagStrategy: tagStrategy)

        if value is _DERStringDictionaryEncodableMarker {
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        } else {
            try value.encode(to: encoder)
        }
        
        guard let topLevel = encoder.topLevel else {
            throw EncodingError.invalidValue(value,
                                             EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }
        
        return topLevel.toData()
    }
    
}

fileprivate protocol _DERStringDictionaryEncodableMarker { }

extension Dictionary : _DERStringDictionaryEncodableMarker where Key == String, Value: Encodable { }

/**
 User to represent an index for an unkeyed container in the codingPath
 */
private struct _DERKey : CodingKey, CustomStringConvertible {
    public var stringValue: String
    public var intValue: Int?
    
    var description: String {
        if let intValue = self.intValue {
            return "[\(intValue)]"
        }
        return stringValue
    }
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "[\(index)]"
        self.intValue = index
    }
}

fileprivate class _DEREncoder : Encoder {
    
    var userInfo: [CodingUserInfoKey : Any]
    
    var codingPath: [CodingKey]
    
    var topLevel: DERElement? {
        guard let firstElement = stack.first else {
            return nil
        }
        if let wrapper = firstElement as? SingleValueWrapper {
            return wrapper.elements.first
        }
        return firstElement
    }
    
    var stack: [DERCollection] = []
    
    let tagStrategy : DERTagStrategy

    init(userInfo: [CodingUserInfoKey : Any], codingPath: [CodingKey] = [], tagStrategy: DERTagStrategy) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.tagStrategy = tagStrategy
    }
    
    /**
     Special marker class used as the top-level collection when only a single value is encoded
     */
    fileprivate class SingleValueWrapper : DERCollection { }

    func tailCollection(singleValue: Bool = false) -> DERCollection {
        if let tailCollection = stack.last {
            return tailCollection
        } else {
            let collection: DERCollection
            if singleValue {
                collection = SingleValueWrapper()
            } else {
                collection = DERCollection(tag: tagStrategy.tag(forPath: codingPath))
            }
            pushSequence(collection)
            return collection
        }
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let collection = tailCollection()
        let container = DEREncodingContainer<Key>(referencing: self, codingPath: self.codingPath, parent: collection)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let collection = tailCollection()
        return DEREncodingContainer<_DERKey>(referencing: self, codingPath: self.codingPath, parent: collection)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        let collection = tailCollection(singleValue: true)
        return DEREncodingContainer<_DERKey>(referencing: self, codingPath: self.codingPath, parent: collection)
    }
    
    
    func pushSequence(_ collection: DERCollection) {
        stack.append(collection)
    }
    
    func popStack(depth targetDepth: Int? = nil) {
        let depth = targetDepth ?? stack.count - 1
        if self.stack.count > depth {
            stack.removeLast()
        }
    }
}

fileprivate class DEREncodingContainer<K : CodingKey> : _DERBoxingContainer, KeyedEncodingContainerProtocol {
    typealias Key = K
    
    
    private var parent: DERElement?
    
    init(referencing encoder: _DEREncoder, codingPath: [CodingKey], parent: DERElement?) {
        super.init(referencing: encoder, codingPath: codingPath)
        self.parent = parent
    }
    
    func addChild(element: DERElement?) {
        guard let element = element else {
            return
        }
        
        if let collection = parent as? DERCollection {
            collection.append(element)
        } else {
            parent = element
        }
    }

    // MARK: - KeyedEncodingContainer
    
    public func encodeNil(forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: boxNil(forKey: key))
    }
    
    public func encode(_ value: Bool, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    
    public func encode(_ value: Int, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: Int8, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: Int16, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: Int32, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: Int64, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: UInt, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: UInt8, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: UInt16, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: UInt32, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: UInt64, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    public func encode(_ value: String, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: try box(value, forKey: key))
    }
    
    public func encode(_ value: Float, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    
    public func encode(_ value: Double, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        addChild(element: box(value, forKey: key))
    }
    
    // MARK: Encodable
    public func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        if let collection = parent as? DERCollection, collection.writeKeys {
            addChild(element: try box(key.stringValue))
        }

        addChild(element: try boxEncodable(value, forKey: key))
    }
    
    public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let childCollection = DERCollection(tag: tag())
        addChild(element: childCollection)
        return KeyedEncodingContainer(DEREncodingContainer<NestedKey>(referencing: encoder, codingPath: self.codingPath, parent: childCollection))
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let childCollection = DERCollection(tag: tag())
        addChild(element: childCollection)
        return DEREncodingContainer(referencing: encoder, codingPath: self.codingPath, parent: childCollection)
    }
    
    public func superEncoder() -> Encoder {
        fatalError("Unimplemented")
    }
    
    public func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Unimplemented")
    }
    
}


// MARK: - UnkeyedEncodingContainer
extension DEREncodingContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {
    
    /// The number of elements encoded into the container.
    public var count: Int {
        if let collection = parent as? DERCollection {
            return collection.elements.count
        }
        return 0
    }
    
    private func lastIndexKey() -> CodingKey {
        return _DERKey(index: self.count)
    }
    
    public func encodeNil() throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        addChild(element: boxNil())
    }

    public func encode(_ value: Bool) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        addChild(element: box(value))
    }

    public func encode(_ value: Int) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        addChild(element: box(value))
    }

    public func encode(_ value: Int8) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        addChild(element: box(value))
    }

    public func encode(_ value: Int16) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        addChild(element: box(value))
    }

    public func encode(_ value: Int32) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }

    public func encode(_ value: Int64) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }

    public func encode(_ value: UInt)   throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }
    
    public func encode(_ value: UInt8) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }
    
    public func encode(_ value: UInt16) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }
    
    public func encode(_ value: UInt32) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }
    
    public func encode(_ value: UInt64) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }
    
    public func encode(_ value: String) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: try box(value))
    }
    
    public func encode(_ value: Float) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }
    
    public func encode(_ value: Double) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: box(value))
    }
    
    
    // MARK: Encodable
    public func encode<T : Encodable>(_ value: T) throws {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        addChild(element: try boxEncodable(value))
    }
    
    public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let childCollection = DERCollection(tag: tag())
        addChild(element: childCollection)
        return KeyedEncodingContainer(DEREncodingContainer<NestedKey>(referencing: encoder, codingPath: self.codingPath, parent: childCollection))
    }
    
    public func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let key = lastIndexKey()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let childCollection = DERCollection(tag: tag())
        addChild(element: childCollection)
        return DEREncodingContainer(referencing: encoder, codingPath: self.codingPath, parent: childCollection)
    }
    
}

fileprivate class _DERBoxingContainer {
    
    var codingPath: [CodingKey]
    
    static let printableStringCharset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '()+,-./:=?")

    /// A reference to the encoder we're writing to.
    let encoder: _DEREncoder
    
    init(referencing encoder: _DEREncoder, codingPath: [CodingKey] = []) {
        self.encoder = encoder
        self.codingPath = codingPath
    }

    
    func toSmallestByteArray<T: BinaryInteger>(endian: T, count: Int) -> [UInt8] {
        var _endian = endian
        let bytePtr = withUnsafePointer(to: &_endian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        
        let signed = type(of: endian).isSigned
        var omitLeading = 0
        for byte in bytePtr {
            // Always leave one byte no matter what
            guard bytePtr.count - omitLeading > 1  else {
                break
            }
            
            if byte == 0x00 {
                omitLeading += 1
                continue
            }
            
            // Only omit leading 0xFF bytes for signed numbers
            if signed && byte == 0xFF {
                omitLeading += 1
                continue
            }
            
            break
        }
        
        var bytes = [UInt8](bytePtr[omitLeading...])
        
        if !signed && bytes[0] > 127 {
            // This is to handle a case where there is a UInt that is larger than Int.max.
            bytes.insert(0x00, at: 0)
        }
        
        return bytes
    }
    
    func objectSubIdentifer(_ subidentifier: Int) -> [UInt8] {
        
        var _subidentifier = subidentifier
        var encoded: [UInt8] = [UInt8(_subidentifier & 0x7f)]
        _subidentifier >>= 7
        
        while _subidentifier > 0 {
            encoded.append(0x80 | UInt8(_subidentifier & 0x7f))
            _subidentifier >>= 7
        }
        
        return encoded.reversed()
    }
    
    func tag() -> DERTagOptions {
        return encoder.tagStrategy.tag(forPath: codingPath)
    }
    
    func tag<T : Encodable>(for value: T) -> DERTagOptions {
        return encoder.tagStrategy.tag(forValue: value, atPath: codingPath)
    }

    
    func boxNil(forKey key: CodingKey? = nil) -> DERElement {
        let primitive = DERPrimitive(tag: .NULL, value: Data([]))
        return primitive
    }

    func box(_ value: Bool, forKey key: CodingKey? = nil) -> DERElement {
        let byte: UInt8 = value ? 0xFF : 0x00
        let primitive = DERPrimitive(tag: tag(for: value), value: Data([byte]))
        return primitive
    }
    
    func box(_ value: Int, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<Int>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: Int8, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<Int8>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: Int16, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<Int16>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: Int32, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<Int32>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: Int64, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<Int64>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: UInt, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<UInt>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: UInt8, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<UInt8>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: UInt16, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<UInt16>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: UInt32, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<UInt32>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: UInt64, forKey key: CodingKey? = nil) -> DERElement {
        let bytes = toSmallestByteArray(endian: value.bigEndian, count: MemoryLayout<UInt64>.size)
        let primitive = DERPrimitive(tag: tag(for: value), bytes: bytes)
        return primitive
    }
    
    func box(_ value: String, forKey key: CodingKey? = nil) throws -> DERElement {
        
        let tag = self.tag(for: value)
        
        let primitive: DERPrimitive
        if tag.contains(.PrintableString) {
            primitive = DERPrimitive(tag: tag, value: value.data(using: .ascii)!)
        } else if tag.contains(.IA5String) {
            primitive = DERPrimitive(tag: tag, value: value.data(using: .ascii)!)
        } else if tag.contains(.UTF8String) {
            primitive = DERPrimitive(tag: tag, value: value.data(using: .utf8)!)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath,
                                                                          debugDescription: "Could not encode type \(type(of: value))"))
        }

        return primitive
    }
    
    func box(_ value: Float, forKey key: CodingKey? = nil) -> DERElement {
        return box(Double(value))
    }
    
    func box(_ value: Double, forKey key: CodingKey? = nil) -> DERElement {
        
        // explained in Annex C and Ch. 8.5 of X.690
        
        // using binary encoding, with base 2 and F==0
        // F is only needed when encoding with base 8 or 16
        
        
        var data = Data()
        
        let negative = value.sign == .minus
        
        if value.isNaN {
            // 8.5.9 Value is NOT-A-NUMBER
            let options: RealOptions = [.SPECIAL_REAL_VALUE, .NOT_A_NUMBER]
            data.append(options.rawValue)
            
        } else if value.isInfinite {
            let options: RealOptions
            
            if negative {
                // 8.5.9 Value is MINUS-INFINITY
                options = [.SPECIAL_REAL_VALUE, .MINUS_INFINITY]
            } else {
                // 8.5.9 Value is PLUS-INFINITY
                options = [.SPECIAL_REAL_VALUE, .PLUS_INFINITY]
            }
            data.append(options.rawValue)
            
        } else if value.isZero {
            
            if negative {
                // 8.5.3 If the real value is the value minus zero, then it shall be encoded as specified in 8.5.9
                // 8.5.9 Value is minus zero
                let options: RealOptions = [.SPECIAL_REAL_VALUE, .MINUS_ZERO]
                data.append(options.rawValue)
            } else {
                // 8.5.2 If the real value is the value plus zero, there shall be no contents octets in the encoding.
                
            }
            
        } else {
            
            // 8.5.4 For a non-zero real value, if the base of the abstract value is 10, then the base of the encoded value shall be 10,
            // and if the base of the abstract value is 2 the base of the encoded value shall be 2, 8 or 16 as a sender's option.
            var options: RealOptions = [.BINARY_ENCODING, .BASE_2]
            
            if negative {
                options.update(with: .IS_NEGATIVE)
            }
            
            
            var mantissa = value.significandBitPattern | 0x0010000000000000
            
            // because IEEE double-precision format is (-1)^sign * 1.b51b50..b0 * 2^(e-1023) we need to
            // subtract 1023 and 52 from the exponent to get an exponent corresponding to an integer matissa as need here.
            var exponent = Int(value.exponentBitPattern) - 1075
            
            // trailing zeros of the mantissa should be removed. Therefor find out how much the mantissa can
            // be shifted and the exponent can be increased
            exponent += mantissa.trailingZeroBitCount
            mantissa >>= mantissa.trailingZeroBitCount
            
            // 11.3.1 In encoding the value, the binary scaling factor F shall be zero, and M and E shall each be represented in the fewest octets necessary.
            
            let exponentBytes = toSmallestByteArray(endian: exponent.bigEndian, count: MemoryLayout<Int>.size)
            let mantissaBytes = toSmallestByteArray(endian: mantissa.bigEndian, count: MemoryLayout<Int64>.size)
            
            
            var needsExponentLength = false
            let exponentLength = UInt8(exponentBytes.count)
            
            switch exponentLength {
            case 1:
                options.update(with: .EXPONENT_1BYTE)
            case 2:
                options.update(with: .EXPONENT_2BYTES)
            case 3:
                options.update(with: .EXPONENT_3BYTES)
            default:
                options.update(with: .EXPONENT_XBYTES)
                needsExponentLength = true
            }
            
            data.append(options.rawValue)
            
            if needsExponentLength {
                // 8.5.7.4 d) if bits 2 to 1 are 11, then the second contents octet encodes the number of octets, X say, (as an unsigned binary number)
                // used to encode the value of the exponent, and the third up to the (X plus 3)th (inclusive) contents octets encode the
                // value of the exponent as a two's complement binary number; the value of X shall be at least one; the first nine bits
                // of the transmitted exponent shall not be all zeros or all ones
                
                let exponentLengthBytes = toSmallestByteArray(endian: exponentLength.bigEndian, count: MemoryLayout<UInt8>.size)
                data.append(contentsOf: exponentLengthBytes)
            }
            
            data.append(contentsOf: exponentBytes)
            data.append(contentsOf: mantissaBytes)
            
        }
        
        let primitive = DERPrimitive(tag: tag(for: value), value: data)
        return primitive
    }
    
    func box(_ value: Data, forKey key: CodingKey? = nil) -> DERElement {
        var bitstring = Data([0x00])
        bitstring.append(value)
        let primitive = DERPrimitive(tag: tag(for: value), value: bitstring)
        return primitive
    }
    
    func box(_ value: OID, forKey key: CodingKey? = nil) -> DERElement {

        let identifiers = value.oid.split(separator: ".").compactMap { Int($0) }
        
        let firstSubidentifier = (identifiers[0] * 40) + identifiers[1]
        
        var data = Data()
        data.append(contentsOf: objectSubIdentifer(firstSubidentifier))
        
        for identifier in identifiers[2...] {
            data.append(contentsOf: objectSubIdentifer(identifier))
        }
        
        return DERPrimitive(tag: tag(for: value), value: data)
    }
    
    func box(_ value: Date, forKey key: CodingKey? = nil) -> DERElement {

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyMMddHHmmss'Z'"
        let formatted = dateFormatter.string(from: value)
        let primitive = DERPrimitive(tag: tag(for: value), value: formatted.data(using: .utf8)!)
        return primitive
    }

    func boxEncodable<T : Encodable>(_ value: T, forKey key: CodingKey? = nil) throws -> DERElement? {

        switch value {
        case is Data:
            return box(value as! Data)
        case is OID:
            return box(value as! OID)
        case is Date:
            return box(value as! Date)
        case is Bool:
            return box(value as! Bool)
        case is String:
            return try box(value as! String)
        case is Int:
            return box(value as! Int)
        case is Int8:
            return box(value as! Int8)
        case is Int16:
            return box(value as! Int16)
        case is Int32:
            return box(value as! Int32)
        case is Int64:
            return box(value as! Int64)
        case is UInt:
            return box(value as! UInt)
        case is UInt8:
            return box(value as! UInt8)
        case is UInt16:
            return box(value as! UInt16)
        case is UInt32:
            return box(value as! UInt32)
        case is UInt64:
            return box(value as! UInt64)
        case is Float:
            return box(value as! Float)
        case is Double:
            return box(value as! Double)
        default:
            
            let tag = self.tag(for: value)

            let stackDepth = encoder.stack.count
            var wrapper: DERElement? = nil
            do {
                if tag.contains(.constructed) {
                    let collection = DERCollection(tag: tag)
                    
                    if value is _DERStringDictionaryEncodableMarker {
                        // A Swift Dictionary encodes itself in two ways. If it is of the form [String:Encodable] it will turn the String
                        // into a (internal) _DictionaryCodingKey and call encode(String, forKey: Key)
                        // If it's anything else, it will call encode the key and value pairs sequentially.
                        
                        // There really isn't a key-value structure in DER, so we write it out as a SEQUENCE with the key value pairs sequentially
                        // However, we need some way to communicate to encode(String, forKey: Key) that it needs to write the key out as well
                        
                        collection.writeKeys = true
                    }
                    
                    encoder.pushSequence(collection)
                    wrapper = collection
                }
                
                defer {
                    if value is Set<AnyHashable>, let collection = wrapper as? DERCollection {
                        collection.elements.sort { (lhs: DERElement, rhs: DERElement) -> Bool in
                            return lhs.value.lexicographicallyPrecedes(rhs.value)
                        }
                    }
                    
                    
                    // The value may have requsted several nested containers.
                    // Pop the stack back to the correct depth
                    encoder.popStack(depth: stackDepth)
                }
                encoder.codingPath = self.codingPath
                try value.encode(to: encoder)
            }
            return wrapper


        }
    }
}

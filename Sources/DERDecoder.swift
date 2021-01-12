//
//  DERDecoder.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/5/21.
//

import Foundation
import Combine

//func trace(_ message: Any = "", caller: Any, file: String = #file, _ function: String = #function, line: Int = #line) {
//    print(message, type(of: caller), function, line)
//}

class DERDecoder : TopLevelDecoder {
    
    typealias Input = Data
    
    var tagStrategy: DERTagStrategy = DefaultDERTagStrategy()
    
    open func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
        
        let decoder = _DERDecoder(tagStrategy: tagStrategy, data: data)
        
        let decoded: T
        let container = try decoder.singleValueContainer()
        decoded = try container.decode(type)
        return decoded
    }
    
}

fileprivate protocol _DERStringDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}

extension Dictionary : _DERStringDictionaryDecodableMarker where Key == String, Value: Decodable {
    static var elementType: Decodable.Type { return Value.self }
}

fileprivate enum LengthType {
    case definite
    case indefinite
}

fileprivate class _DERDecoder : Decoder {
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any]
    
    var tagStrategy: DERTagStrategy
    
    private let cursor: BufferCursor
    
    init(userInfo: [CodingUserInfoKey : Any] = [:], codingPath: [CodingKey] = [], tagStrategy: DERTagStrategy, data: Data) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.tagStrategy = tagStrategy
        self.cursor = BufferCursor(data)
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = try DERKeyedDecodingContainer<Key>(referencing: self, cursor: cursor, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let container = try DERUnkeyedDecodingContainer(referencing: self, cursor: cursor, codingPath: codingPath)
        return container
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        let container = try DERSingleValueDecodingContainer(referencing: self, cursor: cursor, codingPath: codingPath)
        return container
    }
    
    
}

struct DERTagKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) { return nil }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "Tag \(intValue)"
    }
    
    init(tag: DERTagOptions) {
        self.intValue = Int(tag.rawValue)
        self.stringValue = tag.description
    }
}

fileprivate class DERKeyedDecodingContainer<K : CodingKey> : _DERUnboxingContainer, KeyedDecodingContainerProtocol {

    typealias Key = K
    
    /// All the keys the `Decoder` has for this container.
    ///
    /// Different keyed containers from the same `Decoder` may return different
    /// keys here; it is possible to encode with multiple key types which are
    /// not convertible to one another. This should report all keys present
    /// which are convertible to the requested type.
    var allKeys: [Key] {
        fatalError("Unimplemented")
    }

    var tag: DERTagOptions
    
    var lengthType: LengthType = .definite
    
    var end: Int
    
    override init(referencing decoder: _DERDecoder, cursor: BufferCursor, codingPath: [CodingKey]) throws {
        self.tag = try cursor.readNextTag()
        
        guard let lengthByte = cursor.peekNext() else {
            throw DecodingError.valueNotFound(UInt8.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read the length byte"))
        }
        
        if lengthByte == 0x80 {
            lengthType = .indefinite
            cursor.next() // Consume the length byte
            end = cursor.buffer.endIndex
            
        } else {
            let length = try cursor.readLength()
            end = cursor.position + length
        }
        try super.init(referencing: decoder, cursor: cursor, codingPath: codingPath)
    }
    
    
    func contains(_ key: Key) -> Bool {
        fatalError("Unimplemented")
    }


    func decodeNil(forKey key: Key) throws -> Bool {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unboxNil(forKey: key)
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unbox(type, forKey: key)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unbox(type, forKey: key)    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unbox(type, forKey: key)    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        let value = try unbox(Double.self, forKey: key)
        let decoded = Float(value)
        return decoded
    }


    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        return try unboxDecodable(type, forKey: key)
    }
    

    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let value = try unbox(Double.self)
            let decoded = Float(value)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }

    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded = try unbox(type)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        do {
            cursor.mark()
            let decoded: T = try unboxDecodable(type, forKey: key)
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }


    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        let container = try DERKeyedDecodingContainer<NestedKey>(referencing: decoder, cursor: cursor, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }


    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        let container = try DERUnkeyedDecodingContainer(referencing: decoder, cursor: cursor, codingPath: codingPath)
        return container
    }


    func superDecoder() throws -> Decoder {
        fatalError("Unimplemented")
    }


    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError("Unimplemented")
    }
    
}


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


// MARK: - UnkeyedEncodingContainer
fileprivate class DERUnkeyedDecodingContainer : _DERUnboxingContainer, UnkeyedDecodingContainer {

    var tag: DERTagOptions
    
    var lengthType: LengthType = .definite
    
    var end: Int
    
    /// The number of elements contained within this container.
    ///
    /// If the number of elements is unknown, the value is `nil`.
    var count: Int? {
        return nil
    }

    private var index = 0
    
    /// The current decoding index of the container (i.e. the index of the next
    /// element to be decoded.) Incremented after every successful decode call.
    private(set) var currentIndex: Int = 0
    
    override init(referencing decoder: _DERDecoder, cursor: BufferCursor, codingPath: [CodingKey] = []) throws {
        self.tag = try cursor.readNextTag()
        
        guard let lengthByte = cursor.peekNext() else {
            throw DecodingError.valueNotFound(UInt8.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read the length byte"))
        }
        
        if lengthByte & 0x80 != 0 {
            lengthType = .indefinite
            cursor.next() // Consume the length byte
            end = cursor.buffer.endIndex
            
        } else {
            let length = try cursor.readLength()
            end = cursor.position + length
        }
        
        try super.init(referencing: decoder, cursor: cursor, codingPath: codingPath)
    }
    
    /// A Boolean value indicating whether there are no more elements left to be
    /// decoded in the container.
    var isAtEnd: Bool {
        guard cursor.hasMoreData() else {
            return true
        }
        
        if lengthType == .indefinite {
            return cursor.current == 0x00 && cursor.peekNext() == 0x00
        }
        
        return cursor.position >= end
    }

    private func indexKey() -> CodingKey {
        return _DERKey(index: self.index)
    }
    
    func pushPath() {
        self.codingPath.append(indexKey())
    }
    
    func popPath(success: Bool = true) {
        self.codingPath.removeLast()
        if success == true {
            index += 1
        }
    }
    
    func decodeNil() throws -> Bool {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try! unboxNil()
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: String.Type) throws -> String {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Double.Type) throws -> Double {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(Double.self)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Float.Type) throws -> Float {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let value = try unbox(Double.self)
        let decoded = Float(value)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int.Type) throws -> Int {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let signed = try unbox(Int.self)
        let decoded = UInt(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let signed = try unbox(Int16.self)
        let decoded = UInt8(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let signed = try unbox(Int32.self)
        let decoded = UInt16(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let signed = try unbox(Int64.self)
        let decoded = UInt32(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        let signed = try unbox(Int64.self)
        let decoded = UInt64(signed)
        currentIndex += 1
        return decoded
    }

    // MARK: Decodable
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
        }
        
        if let oidType = type as? OID.Type {
            return try unbox(oidType) as! T
        } else if type == String.self {
            return try unbox(String.self) as! T
        }
        let decoded: T = try unboxDecodable(type)
        currentIndex += 1
        return decoded
    }
    
    func tryDecode<T : Decodable>(_ wrapped: (() throws -> T)) throws -> T? {
        do {
            pushPath()
            cursor.mark()
        
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container"))
            }
            
            let decoded: T = try wrapped()
            
            cursor.clearMark()
            popPath()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            popPath(success: false)
            return nil
        }
    }

    func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: String.Type) throws -> String? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        return try tryDecode {
            let value = try unbox(Double.self)
            return Float(value)
        }
    }

    func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        return try tryDecode {
            let signed = try unbox(Int.self)
            return UInt(signed)
        }
    }

    func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        return try tryDecode {
            let signed = try unbox(Int16.self)
            return UInt8(signed)
        }
    }

    func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        return try tryDecode {
            let signed = try unbox(Int32.self)
            return UInt16(signed)
        }
    }

    func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        return try tryDecode {
            let signed = try unbox(Int64.self)
            return UInt32(signed)
        }
    }

    func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        return try tryDecode {
            let signed = try unbox(Int64.self)
            return UInt64(signed)
        }
    }

    func decodeIfPresent<T>(_ type: T.Type) throws -> T? where T : Decodable {
        return try tryDecode {
            if let oidType = type as? OID.Type {
                return try unbox(oidType) as! T
            } else if type == String.self {
                return try unbox(String.self) as! T
            }
            return try unboxDecodable(type)
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        
        self.codingPath.append(indexKey())
        defer {
            index += 1
            self.codingPath.removeLast()
        }

        let container = try DERKeyedDecodingContainer<NestedKey>(referencing: decoder, cursor: cursor, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.codingPath.append(indexKey())
        defer {
            index += 1
            self.codingPath.removeLast()
        }

        let container = try DERUnkeyedDecodingContainer(referencing: decoder, cursor: cursor, codingPath: codingPath)
        return container
    }
    
    func superDecoder() throws -> Decoder {
        fatalError("Unimplemented")
    }
    
}


fileprivate class DERSingleValueDecodingContainer: _DERUnboxingContainer, SingleValueDecodingContainer {
    
    func decodeNil() -> Bool {
        return try! unboxNil()
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try unbox(type)
    }

    func decode(_ type: String.Type) throws -> String {
        return try unbox(type)
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try unbox(Double.self)
    }

    func decode(_ type: Float.Type) throws -> Float {
        let value = try unbox(Double.self)
        return Float(value)
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try unbox(type)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try unbox(type)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try unbox(type)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try unbox(type)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try unbox(type)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        let signed = try unbox(Int.self)
        return UInt(signed)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        let signed = try unbox(Int16.self)
        return UInt8(signed)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        let signed = try unbox(Int32.self)
        return UInt16(signed)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        let signed = try unbox(Int64.self)
        return UInt32(signed)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        let signed = try unbox(Int64.self)
        return UInt64(signed)
    }

    // MARK: Decodable
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let oidType = type as? OID.Type {
            return try unbox(oidType) as! T
        } else if type == String.self {
            return try unbox(String.self) as! T
        }
        return try unboxDecodable(type)
    }
    
    func tryDecode<T : Decodable>(_ wrapped: (() throws -> T)) throws -> T? {
        do {
            cursor.mark()
            let decoded: T = try wrapped()
            cursor.clearMark()
            return decoded
        } catch is DecodingError {
            cursor.rewind()
            return nil
        }
    }

    func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: String.Type) throws -> String? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        return try tryDecode {
            let value = try unbox(Double.self)
            return Float(value)
        }
    }

    func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        return try tryDecode {
            return try unbox(type)
        }
    }

    func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        return try tryDecode {
            let signed = try unbox(Int.self)
            return UInt(signed)
        }
    }

    func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        return try tryDecode {
            let signed = try unbox(Int16.self)
            return UInt8(signed)
        }
    }

    func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        return try tryDecode {
            let signed = try unbox(Int32.self)
            return UInt16(signed)
        }
    }

    func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        return try tryDecode {
            let signed = try unbox(Int64.self)
            return UInt32(signed)
        }
    }

    func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        return try tryDecode {
            let signed = try unbox(Int64.self)
            return UInt64(signed)
        }
    }

    func decodeIfPresent<T>(_ type: T.Type) throws -> T? where T : Decodable {
        return try tryDecode {
            if let oidType = type as? OID.Type {
                return try unbox(oidType) as! T
            } else if type == String.self {
                return try unbox(String.self) as! T
            }
            return try unboxDecodable(type)
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = try DERKeyedDecodingContainer<NestedKey>(referencing: decoder, cursor: cursor, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let container = try DERUnkeyedDecodingContainer(referencing: decoder, cursor: cursor, codingPath: codingPath)
        return container
    }


}


fileprivate class _DERUnboxingContainer {
    
    
    let decoder: _DERDecoder
    
    /// The path of coding keys taken to get to this point in decoding.
    internal var codingPath: [CodingKey]

    private var _mark: Int = 0
    let cursor: BufferCursor
    
    init(referencing decoder: _DERDecoder, cursor: BufferCursor, codingPath: [CodingKey] = []) throws {
        self.decoder = decoder
        self.codingPath = codingPath
        self.cursor = cursor
    }
    
    private func getMemorySize<T>(_ type: T.Type) -> Int {
        return MemoryLayout<T>.size
    }

    func peekNextTag() throws -> DERTagOptions {
        guard let tagByte = cursor.peekNext() else {
            throw DecodingError.valueNotFound(DERTagOptions.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read the next tag"))
        }
        return DERTagOptions(rawValue: tagByte)
    }
    
    func checkNextTag(is tag: DERTagOptions) throws -> Bool {
        return try peekNextTag() == tag
    }

    func assertNextTag<T>(is tag: DERTagOptions, expectedType: T.Type) throws {
        let nextTag = try cursor.readNextTag()
        guard nextTag == tag else {
            throw DecodingError.typeMismatch(expectedType, DecodingError.Context(codingPath: codingPath, debugDescription: "Unexpected tag \(nextTag)"))
        }
    }

    func readNextPrimitiveBytes() throws -> [UInt8] {
        let len = try cursor.readLength()
        return cursor.nextBytes(len)
    }
    
    func unbox(_ type: String.Type, forKey key: CodingKey? = nil) throws -> String {
        let tag = try cursor.readNextTag()
        if tag == .PrintableString || tag == .IA5String {
            return String(bytes: try readNextPrimitiveBytes(), encoding: .ascii)!
            
        } else if tag == .UTF8String {
            return String(bytes: try readNextPrimitiveBytes(), encoding: .utf8)!
        }
        
        throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unknown tag \(tag)"))
    }
    
    func unbox(_ type: Bool.Type, forKey key: CodingKey? = nil) throws -> Bool {
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
        try assertNextTag(is: expectedTag, expectedType: type)
        
        let boolBytes = try readNextPrimitiveBytes()
        
        guard let byte = boolBytes.first else {
            return false
        }
        return byte > 0
    }
    
    func unboxNil(forKey key: CodingKey? = nil) throws -> Bool {
        try assertNextTag(is: .NULL, expectedType: Void.self)
        let boolBytes = try readNextPrimitiveBytes()
        return boolBytes.isEmpty
    }
    
    func unbox<T : FixedWidthInteger & Decodable>(_ type: T.Type, forKey key: CodingKey? = nil) throws -> T {
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
        try assertNextTag(is: expectedTag, expectedType: type)
        return try unbox(type, from: try readNextPrimitiveBytes())
    }
    
    func unbox<T : FixedWidthInteger>(_ type: T.Type, from inputBytes: [UInt8]) throws -> T {

        let memSize = getMemorySize(type)
        
        var intBytes = inputBytes
        guard intBytes.count <= memSize else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Length bytes is greater than a \(type)"))
        }
        
        var filler: UInt8 = 0x00
        if type.isSigned, let first = intBytes.first, (first & 0x80) == 0x80 {
            filler = 0xFF
        }
        while intBytes.count < memSize {
            intBytes.insert(filler, at: 0)
        }
        
        let bigEndian = intBytes.withUnsafeBytes { $0.load(as: type) }
        return type.init(bigEndian: bigEndian)
    }
    
    func unbox(_ type: Double.Type, forKey key: CodingKey? = nil) throws -> Double {
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
        try assertNextTag(is: expectedTag, expectedType: type)

        var realBytes = try readNextPrimitiveBytes()
        if realBytes.isEmpty {
            return Double.zero
        }

        let options = RealOptions(rawValue: realBytes.removeFirst())
        
        if options.contains(.BINARY_ENCODING) {
            
            let sign: FloatingPointSign = options.contains(.IS_NEGATIVE) ? .minus : .plus
            
            let exponentLen: Int
            if options.contains(.EXPONENT_XBYTES) {
                exponentLen = Int(realBytes.removeFirst())
            } else if options.contains(.EXPONENT_3BYTES) {
                exponentLen = 3
            } else if options.contains(.EXPONENT_2BYTES) {
                exponentLen = 2
            } else {
                exponentLen = 1
            }
            
            let exponentBytes = Array(realBytes[..<exponentLen])
            let significandBytes = Array(realBytes[exponentLen...])
            let exponent = try unbox(Int.self, from: exponentBytes)
            let significand = try unbox(UInt64.self, from: significandBytes)
            return Double(sign: sign, exponent: exponent, significand: Double(significand))

            
        } else if options.contains(.SPECIAL_REAL_VALUE) {
            
            if options == [.SPECIAL_REAL_VALUE, .PLUS_INFINITY] {
                return Double.infinity
            } else if options == [.SPECIAL_REAL_VALUE, .MINUS_INFINITY] {
                return -Double.infinity
            } else if options == [.SPECIAL_REAL_VALUE, .MINUS_ZERO] {
                return -Double.zero
            } else if options == [.SPECIAL_REAL_VALUE, .NOT_A_NUMBER] {
                return Double.nan
            }
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Unknown SpecialRealValue \(options)"))

            
        } else { // DECIMAL_ENCODING
            
        }
        throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Unknown real value"))

        
    }

    func unbox(_ type: OID.Type, forKey key: CodingKey? = nil) throws -> OID {
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
        try assertNextTag(is: expectedTag, expectedType: type)

        let oidBytes = try readNextPrimitiveBytes()

        var offset = 0
        
        var identifiers = [Int]()
        
        var subidentifier = unboxObjectSubIdentifer(oidBytes, offset: &offset)
        identifiers.append(subidentifier / 40)
        identifiers.append(subidentifier % 40)
        
        while offset < oidBytes.count {
            subidentifier = unboxObjectSubIdentifer(oidBytes, offset: &offset)
            identifiers.append(subidentifier)
        }
        
        
        let identifier = identifiers.compactMap(String.init).joined(separator: ".")
        
        if let oid = OID.knownOIDs[identifier] {
            return oid
        }
        
        return OID(oid: identifier)
    }
    

    private func unboxObjectSubIdentifer(_ data: [UInt8], offset: inout Int) -> Int {
        var decoded = 0
        
        while data[offset] & 0x80 != 0 {
            decoded += Int(data[offset] & 0x7f)
            decoded <<= 7
            offset += 1
        }
        
        decoded += Int(data[offset])
        offset += 1
        
        return decoded
    }
    
    func unbox(_ type: Data.Type, forKey key: CodingKey? = nil) throws -> Data {
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
        try assertNextTag(is: expectedTag, expectedType: type)

        var data = try readNextPrimitiveBytes()
        
        let unusedBytes: UInt8 = data.removeFirst()

        if data.isEmpty {
            return Data()
        }
        
        if unusedBytes > 0 {
            let mask: UInt8 = 0xFF << unusedBytes
            data[data.endIndex-1] &= mask
        }
        
        return Data(data)
    }
    
    func unbox(_ type: Date.Type, forKey key: CodingKey? = nil) throws -> Date {
        let nextTag = try peekNextTag()
        
        let dateFormatter = DateFormatter()
        if nextTag == .UTCTime {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.dateFormat = "yyMMddHHmmss'Z'"

        } else if nextTag == .GeneralizedTime {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.dateFormat = "yyyyMMddHHmmss'Z'"

        } else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Unexpected tag \(nextTag)"))
        }

        try cursor.readNextTag()
        let formatted = String(bytes: try readNextPrimitiveBytes(), encoding: .ascii)!
        guard let date = dateFormatter.date(from: formatted) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read date from: \(formatted)"))
        }
        return date
    }
    
    fileprivate func unbox<T : Decodable>(_ type: _DERStringDictionaryDecodableMarker.Type) throws -> T {
        var dictionary = [String:Decodable]()
        let container = try DERUnkeyedDecodingContainer(referencing: decoder, cursor: cursor, codingPath: codingPath)

        let elementType = type.elementType

        while !container.isAtEnd {
            let key = try container.unbox(String.self)
            dictionary[key] = try elementType.init(from: self.decoder)
        }
        
        return dictionary as! T
    }
    
    func unboxDecodable<T>(_ type: T.Type, forKey key: CodingKey? = nil) throws -> T where T : Decodable {
        if type == Data.self {
            return try unbox(Data.self) as! T
        } else if type == Date.self {
            return try unbox(Date.self) as! T
        } else if let stringKeyedDictType = type as? _DERStringDictionaryDecodableMarker.Type {
            return try unbox(stringKeyedDictType)
        }
        
        let nextTag = try peekNextTag()
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
                        
        guard nextTag == expectedTag else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Next tag [\(nextTag)] is not the expected [\(expectedTag)]"))
        }
        
        // If the type needs its own tag strategy, replace the one in use temporarily
        var prevTagStrategy: DERTagStrategy? = nil
        if let tagAwareType = type as? DERTagAware.Type {
            if let childTagStrategy = tagAwareType.childTagStrategy {
                prevTagStrategy = decoder.tagStrategy
                decoder.tagStrategy = childTagStrategy
            }
        }
        
        defer {
            // If the tag strategy was temporarily replaced, return it to the previous state
            if let prevTagStrategy = prevTagStrategy {
                decoder.tagStrategy = prevTagStrategy
            }
        }
        
        return try type.init(from: decoder)
    }
    
}

//
//  DERDecoder.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/5/21.
//

import Foundation
import Combine
import os

//func trace(_ message: Any = "", caller: Any, file: String = #file, _ function: String = #function, line: Int = #line) {
//    print(message, type(of: caller), function, line)
//}

func format(_ codingPath: [CodingKey]) -> String {
    return codingPath.map(\.stringValue).joined(separator: ", ")
}

public class DERDecoder : TopLevelDecoder {
    public typealias Input = Data
    
    public var tagStrategy: DERTagStrategy
    
    public init(tagStrategy: DERTagStrategy = DefaultDERTagStrategy()) {
        self.tagStrategy = tagStrategy
    }
    
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

fileprivate protocol ClosableDecodingContainer {
    
    func close()
    
}

fileprivate class _DERDecoder : Decoder {
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any]
    
    var tagStrategy: DERTagStrategy
    
    private let cursor: BufferCursor
    
    var nestedContainer: (any ClosableDecodingContainer)?
    
    init(userInfo: [CodingUserInfoKey : Any] = [:], codingPath: [CodingKey] = [], tagStrategy: DERTagStrategy, data: Data) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.tagStrategy = tagStrategy
        self.cursor = BufferCursor(data)
    }
    
    func cleanupNestedContainers() {
        // Close any open containers before reading the next tag
        if let nestedContainer = self.nestedContainer {
            nestedContainer.close()
            self.nestedContainer = nil
        }
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
//        cleanupNestedContainers()
        let container = try DERKeyedDecodingContainer<Key>(referencing: self, cursor: cursor, codingPath: codingPath)
//        nestedContainer = container
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
//        cleanupNestedContainers()
        let container = try DERUnkeyedDecodingContainer(referencing: self, cursor: cursor, codingPath: codingPath)
//        nestedContainer = container
        return container
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
//        cleanupNestedContainers()
        let container = try DERSingleValueDecodingContainer(referencing: self, cursor: cursor, codingPath: codingPath)
//        nestedContainer = container
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

fileprivate class DERKeyedDecodingContainer<K : CodingKey> : _DERUnboxingContainer, KeyedDecodingContainerProtocol, ClosableDecodingContainer {

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
            throw DecodingError.valueNotFound(UInt8.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read the length byte. Offset \(cursor.position)"))
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

    func close() {
        
        if let nestedContainer = nestedContainer {
            nestedContainer.close()
            self.nestedContainer = nil
        }
        
        if lengthType == .indefinite
            && cursor.current == 0x00
            && cursor.peekNext() == 0x00 {
            // If we're at the end of an indefinite length container, consume the two null bytes
            cursor.nextBytes(2)
        }
        
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unboxNil(forKey: key)
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unbox(type, forKey: key)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unbox(type, forKey: key)    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return try unbox(type, forKey: key)    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        let value = try unbox(Double.self, forKey: key)
        let decoded = Float(value)
        return decoded
    }


    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        return try unbox(type, forKey: key)
    }


    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        cleanupNestedContainers()

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        return try unboxDecodable(type, forKey: key)
    }
    

    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()

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
        cleanupNestedContainers()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        let container = try DERKeyedDecodingContainer<NestedKey>(referencing: decoder, cursor: cursor, codingPath: codingPath)
        nestedContainer = container
        return KeyedDecodingContainer(container)
    }


    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        cleanupNestedContainers()
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        let container = try DERUnkeyedDecodingContainer(referencing: decoder, cursor: cursor, codingPath: codingPath)
        nestedContainer = container
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
fileprivate class DERUnkeyedDecodingContainer : _DERUnboxingContainer, UnkeyedDecodingContainer, ClosableDecodingContainer {

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
            throw DecodingError.valueNotFound(UInt8.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read the length byte. Offset \(cursor.position)"))
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
    
    func close() {
        
        if let nestedContainer = nestedContainer {
            nestedContainer.close()
            self.nestedContainer = nil
        }
        
        if lengthType == .indefinite {
            if cursor.current == 0x00 && cursor.peekNext() == 0x00 {
                // If we're at the end of an indefinite length container, consume the two null bytes
                cursor.nextBytes(2)
            }
        }
        
    }
    
    func decodeNil() throws -> Bool {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unboxNil()
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: String.Type) throws -> String {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Double.Type) throws -> Double {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(Double.self)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Float.Type) throws -> Float {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let value = try unbox(Double.self)
        let decoded = Float(value)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int.Type) throws -> Int {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let decoded = try unbox(type)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let signed = try unbox(Int.self)
        let decoded = UInt(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let signed = try unbox(Int16.self)
        let decoded = UInt8(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let signed = try unbox(Int32.self)
        let decoded = UInt16(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let signed = try unbox(Int64.self)
        let decoded = UInt32(signed)
        currentIndex += 1
        return decoded
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
        }
        
        let signed = try unbox(Int64.self)
        let decoded = UInt64(signed)
        currentIndex += 1
        return decoded
    }

    // MARK: Decodable
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        cleanupNestedContainers()

        pushPath()
        defer { popPath() }

        cleanupNestedContainers()
        
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
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
        cleanupNestedContainers()

        do {
            pushPath()
            cursor.mark()
        
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Reached the end of the decoding container. Offset \(cursor.position)"))
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
        cleanupNestedContainers()

        self.codingPath.append(indexKey())
        defer {
            index += 1
            self.codingPath.removeLast()
        }

        let container = try DERKeyedDecodingContainer<NestedKey>(referencing: decoder, cursor: cursor, codingPath: codingPath)
        nestedContainer = container
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        cleanupNestedContainers()
        self.codingPath.append(indexKey())
        defer {
            index += 1
            self.codingPath.removeLast()
        }

        let container = try DERUnkeyedDecodingContainer(referencing: decoder, cursor: cursor, codingPath: codingPath)
        nestedContainer = container
        return container
    }
    
    func superDecoder() throws -> Decoder {
        fatalError("Unimplemented")
    }
    
}


fileprivate class DERSingleValueDecodingContainer: _DERUnboxingContainer, SingleValueDecodingContainer, ClosableDecodingContainer {
    
    func close() {
        // Nothing to do
    }
    
    func decodeNil() -> Bool {
        return (try? unboxNil()) ?? false
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
    
    var nestedContainer: (any ClosableDecodingContainer)?

    
    init(referencing decoder: _DERDecoder, cursor: BufferCursor, codingPath: [CodingKey] = []) throws {
        self.decoder = decoder
        self.codingPath = codingPath
        self.cursor = cursor
    }
    
    private func getMemorySize<T>(_ type: T.Type) -> Int {
        return MemoryLayout<T>.size
    }

    func cleanupNestedContainers() {
        // Close any open containers before reading the next tag
        if let nestedContainer = self.nestedContainer {
            nestedContainer.close()
            self.nestedContainer = nil
        }
    }
    
    func peekNextTag() throws -> DERTagOptions {
        
        guard let tagByte = cursor.peekNext() else {
            throw DecodingError.valueNotFound(DERTagOptions.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read the next tag. Offset \(cursor.position)"))
        }
        return DERTagOptions(rawValue: tagByte)
    }
    
    func checkNextTag(is tag: DERTagOptions) throws -> Bool {
        return try peekNextTag() == tag
    }

    func assertNextTag<T>(is tag: DERTagOptions, expectedType: T.Type) throws {
        let nextTag = try cursor.readNextTag()
        guard nextTag == tag else {
            throw DecodingError.typeMismatch(expectedType, DecodingError.Context(codingPath: codingPath, debugDescription: "Unexpected tag \(nextTag). Offset \(cursor.position)"))
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
            
        } else if tag == .TeletexString {
            // Following OpenSSL's lead on this, even though they admit is broken
            return String(bytes: try readNextPrimitiveBytes(), encoding: .isoLatin1)!
        }
        
        throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unknown tag \(tag). Offset \(cursor.position)"))
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
        let nextTag = try peekNextTag()
        guard nextTag == .NULL else { return false }
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
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Length bytes is greater than a \(type). Offset \(cursor.position)"))
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
    
    func unbox(_ type: BInt.Type, forKey key: CodingKey? = nil) throws -> BInt {
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
        try assertNextTag(is: expectedTag, expectedType: type)

        let bigIntBytes = try readNextPrimitiveBytes()
                
        let strideSize = MemoryLayout<UInt64>.size
        
        let limbs = try stride(from: bigIntBytes.endIndex, to: bigIntBytes.startIndex, by: -strideSize).compactMap { (end: Int) -> Limb? in
            let start = max(end.advanced(by: -strideSize), bigIntBytes.startIndex)
            let limbBytes = [UInt8](bigIntBytes[start..<end])
            let signed = try unbox(Int64.self, from: limbBytes)
            if signed == 0 {
                return nil
            }
            return UInt64(bitPattern: signed)
        }
        
        if limbs.isEmpty {
            return BInt.zero
        }
        
        return BInt(limbs: limbs)
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
        throw DecodingError.valueNotFound(type,
                                          DecodingError.Context(codingPath: codingPath, debugDescription: "Unknown real value. Offset \(cursor.position)"))

        
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
        
        if let knownOID = OID.knownOIDs[identifier] {
            return knownOID
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
        
        let tag = try cursor.readNextTag()
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
        guard tag == expectedTag || tag == .BIT_STRING || tag == .OCTET_STRING else {
            throw DecodingError.typeMismatch(Data.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unexpected tag \(tag). Offset \(cursor.position)"))
        }

        var data = try readNextPrimitiveBytes()
        
        if tag == .BIT_STRING {
            
            let unusedBytes: UInt8 = data.removeFirst()
            
            if data.isEmpty {
                return Data()
            }
            
            if unusedBytes > 0 {
                let mask: UInt8 = 0xFF << unusedBytes
                data[data.endIndex-1] &= mask
            }
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
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Unexpected tag \(nextTag). Offset \(cursor.position)"))
        }

        try cursor.readNextTag()
        let formatted = String(bytes: try readNextPrimitiveBytes(), encoding: .ascii)!
        guard let date = dateFormatter.date(from: formatted) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Could not read date from: \(formatted). Offset \(cursor.position)"))
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
        } else if type == BInt.self {
            return try unbox(BInt.self) as! T
        } else if let stringKeyedDictType = type as? _DERStringDictionaryDecodableMarker.Type {
            return try unbox(stringKeyedDictType)
        }
        
        let nextTag = try peekNextTag()
        let expectedTag = decoder.tagStrategy.tag(forType: type, atPath: codingPath)
                        
        guard nextTag == expectedTag else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Next tag \(nextTag) [\(nextTag.rawValue)] is not the expected \(expectedTag) [\(expectedTag.rawValue)]. Offset: \(cursor.position)"))
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
        
        decoder.codingPath = self.codingPath
        return try type.init(from: decoder)
    }
    
}

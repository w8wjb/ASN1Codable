//
//  BufferCursor.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/8/21.
//

import Foundation

enum BufferCursorError: Error {
    case noMoreBytes
}

class BufferCursor : Sequence, IteratorProtocol {
    
    public typealias Element = UInt8
    
    let buffer: Data
    var byteOrder = CFByteOrder(CFByteOrderBigEndian.rawValue)
    
    var position = 0
    
    var current: UInt8 {
        return buffer[position]
    }
    
    private var marks = [Int]()
    
    init() {
        self.buffer = Data()
    }
    
    init(_ data: Data) {
        self.buffer = data
    }
    
    func hasMoreData() -> Bool {
        return (position+1) < buffer.count
    }
    
    
    @discardableResult
    func nextBytes(_ count: Int) -> [UInt8] {
        let endPosition = Swift.min(position+count, buffer.count)
        let range = position..<endPosition
        let nextBytes = buffer.subdata(in: range)
        seek(endPosition)
        return [UInt8](nextBytes)
    }
        
    @discardableResult
    func readNextTag() throws -> DERTagOptions {
        return DERTagOptions(rawValue: next()!)
    }
    
    func readLength() throws -> Int {
        let lenByte = next()!
        
        // Check for long form
        if (lenByte & 0x80) != 0 {
            
            let lengthLen = Int(lenByte & 0b01111111)
            let intLen = MemoryLayout<Int>.size
            guard lengthLen <= intLen else {
                throw BufferCursorError.noMoreBytes
            }
            
            var lenBytes = nextBytes(lengthLen)
            let padding = [UInt8](repeating: 0, count: intLen - lenBytes.count)
            lenBytes.insert(contentsOf: padding, at: 0)
            let len = Int(lenBytes.withUnsafeBytes({ $0.load(as: UInt.self) }).bigEndian)
            
            return len
        }
        
        return Int(lenByte)
    }
    
    func next<T>(type: T.Type) throws -> T {
        let byteCount = MemoryLayout<T>.size
        var data = nextBytes(byteCount)
        
        if CFByteOrderGetCurrent() != byteOrder {
            data.reverse()
        }
        
        return data.withUnsafeBytes { $0.bindMemory(to: type)[0] }
    }
    
    @discardableResult
    func next() -> UInt8? {
        guard position < buffer.count else {
            return nil
        }
        let byte = buffer[position]
        position += 1
        return byte
    }
    
    func peekNext() -> UInt8? {
        guard position < buffer.count else { return nil }
        return buffer[position]
    }
    
    /**
     Repositions the buffer to a new current position. Corrects out of bounds indexes
     - parameter newPosition: new position index
     */
    func seek(_ newPosition: Int) {
        if newPosition < 0 {
            position = 0
        } else if newPosition >= buffer.count {
            position = buffer.count - 1
        } else {
            self.position = newPosition
        }
    }
    
    /**
     Rewind a distance from the current position
     - parameter distance: Distance to rewind from the current position
     */
    func rewind(_ distance: Int) {
        let newPosition = (self.position - distance)
        seek(newPosition)
    }
    
    /**
     Rewind to previously set mark
     - returns: true if the position changed
     */
    @discardableResult
    func rewind() -> Bool {
        if let mark = marks.popLast() {
            if mark != position {
                seek(mark)
                return true
            }
        }
        return false
    }
    
    /**
     Mark the current position in order to return to it with a subsequent rewind()
     */
    func mark() {
        marks.append(self.position)
    }
    
    func clearMark() {
        let _ = marks.popLast()
    }
    
    /**
     Reset the position back to the beginning of the buffer
     */
    func reset() {
        self.position = 0
    }
    
    
}

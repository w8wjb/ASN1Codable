//
//  Data+Extension.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

extension DataProtocol {
    func hexEncodedString(uppercase: Bool = false, separator: String = "") -> String {
        return self.map {
            if $0 < 16 {
                return "0" + String($0, radix: 16, uppercase: uppercase)
            } else {
                return String($0, radix: 16, uppercase: uppercase)
            }
        }.joined(separator: separator)
    }
}

extension Data {
    
    init(hexEncoded: String) {

        var start = hexEncoded.startIndex
        let bytes: [UInt8] = stride(from: 0, to: hexEncoded.count, by: 2).compactMap { _ in
            let end = hexEncoded.index(after: start)
            defer { start = hexEncoded.index(after: end) }
            return UInt8(hexEncoded[start...end], radix: 16)
        }
        
        self.init(bytes)
    }
    
}

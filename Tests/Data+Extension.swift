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

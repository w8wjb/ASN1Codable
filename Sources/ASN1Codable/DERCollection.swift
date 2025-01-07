//
//  DERCollection.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/4/21.
//

import Foundation

class DERCollection: DERElement {

    let tag: UInt8
    
    var elements: [DERElement]
    
    var writeKeys = false
    
    var length: Int {
        self.elements.reduce(0) {
            // tag + length + content
            $0 + 1 + $1.getLengthBytes().count + $1.length
        }
    }

    var value: Data {
        var data = Data()
        
        for elem in elements {
            data.append(elem.toData())
        }
        return data
    }

    
    convenience init(tag: DERTagOptions = .SEQUENCE, elements: DERElement...) {
        self.init(tag: tag.rawValue, elements: elements)
    }

    convenience init(tag: UInt8, elements: DERElement...) {
        self.init(tag: tag, elements: elements)
    }
    
    init(tag: UInt8, elements: [DERElement]) {
        self.tag = tag
        self.elements = elements
    }
    
    func append(_ element: DERElement) {
        self.elements.append(element)
    }

    
}

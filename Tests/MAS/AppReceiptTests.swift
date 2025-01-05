//
//  AppReceiptTests.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/3/25.
//

import XCTest
@testable import ASN1Codable

final class AppReceiptTests: XCTestCase {



    func testGarageBandReceipt() throws {
        
        let receiptPath = Bundle(for: Self.self).path(forResource: "gb_receipt", ofType: "der")!
        let receiptData = try Data(contentsOf: URL(fileURLWithPath: receiptPath))
        
        let decoder = DERDecoder()
        let pkcs7 = try decoder.decode(PKCS7Container.self, from: receiptData)
        
        
        XCTAssertEqual(pkcs7.data.count, 505)
        
        let receipt = try XCTUnwrap(pkcs7.getContent(as: AppReceipt.self))
        
        for type in receipt.attributes.keys {
            let attr = try XCTUnwrap(receipt.attributes[type])
            
            switch attr.type {
            case 14: XCTAssertEqual(attr.intValue, 1)
            case 25: XCTAssertEqual(attr.intValue, 2)
            case 10: XCTAssertEqual(attr.stringValue, "4+")
            case 11: XCTAssertEqual(attr.intValue, 2003)
            case 13: XCTAssertEqual(attr.intValue, 130000)
            case 1: XCTAssertEqual(attr.intValue, 682658836)
            case 9: XCTAssertEqual(attr.intValue, 1345531954)
            case 16: XCTAssertEqual(attr.intValue, 862757097)
            case 15: XCTAssertEqual(attr.intValue, 78007333978675)
            case 19: XCTAssertEqual(attr.stringValue, "10.0.3")
            case 3: XCTAssertEqual(attr.stringValue, "10.4.11")
            case 0: XCTAssertEqual(attr.stringValue, "Production")
            case 4: XCTAssertEqual(attr.data.hexEncodedString(uppercase: true, separator: " "),
                                   "B3 07 05 98 ED 79 AA E1 E4 A1 94 63 FC BD 04 68")
            case 5: XCTAssertEqual(attr.data.hexEncodedString(uppercase: true, separator: " "),
                                   "0C C1 6E E9 BC 38 1F F4 1C 44 EB 56 B2 80 7A 84 38 2E 50 97")
            case 8: XCTAssertEqual(attr.stringValue, "2024-03-26T00:04:13Z")
            case 12: XCTAssertEqual(attr.stringValue, "2024-03-26T00:04:13Z")
            case 18: XCTAssertEqual(attr.stringValue, "2015-03-10T16:37:56Z")
            case 2: XCTAssertEqual(attr.stringValue, "com.apple.garageband10")
            case 7: XCTAssertEqual(attr.data.hexEncodedString(uppercase: true, separator: " "),
                                   "A5 EA FF 44 6F 55 B7 BF 6C 24 F0 68 64 CA 58 B7 6C FA 42 2F 6A 22 1C 9A DD FB EA 9F DD A4 9C A6 5B 27 4B 4A D2 0C 66 52 B0 43 76 9B E0")
            case 6: XCTAssertEqual(attr.data.hexEncodedString(uppercase: true, separator: " "),
                                   "95 87 7F 7D 40 17 21 0B 04 E4 C0 17 5C 4E 3B 8B FD F5 6B B0 10 93 9D D2 C1 8F 7A 20 0C 14 52 44 E3 95 39 F9 9D AF 3A 59 79 80 20 D3 F5 9E D9 CD 01 A3 4C EC B6 1A 76 A5")

            default:
                XCTFail("Unhandled type \(attr.type)")
            }
            
        }
        
        XCTAssertEqual(receipt.bundleId, "com.apple.garageband10")
        XCTAssertEqual(receipt.applicationVersion, "10.4.11")
        XCTAssertEqual(receipt.originalApplicationVersion, "10.0.3")
        
        let dateComp = DateComponents(calendar: .current,
                                      timeZone: TimeZone(secondsFromGMT: 0),
                                      year: 2024,
                                      month: 3,
                                      day: 26,
                                      minute: 4,
                                      second: 13)

        XCTAssertEqual(receipt.receiptCreationDate, dateComp.date)
        XCTAssertNil(receipt.expirationDate)

        XCTAssertEqual(pkcs7.certificates.count, 3)
        
        XCTAssertEqual(pkcs7.signerInfo.count, 1)
        
        let signerInfo = pkcs7.signerInfo[0]
        
        XCTAssertEqual(signerInfo.issuer.description, "CN=Apple Worldwide Developer Relations Certification Authority, OU=G5, O=Apple Inc., C=US")
        
        
        
    }

}

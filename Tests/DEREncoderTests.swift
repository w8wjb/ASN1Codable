//
//  DEREncoderTests.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/4/21.
//

import XCTest

@testable import ASN1Codable

class DEREncoderTests: XCTestCase {

    let encoder = DEREncoder()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEncodePrintableString() throws {
        let encoded = try encoder.encode("Hello World")
        XCTAssertEqual("130b48656c6c6f20576f726c64", encoded.hexEncodedString())
    }

    func testEncodeIA5String() throws {
        let encoded = try encoder.encode("Hello World!")
        XCTAssertEqual("160c48656c6c6f20576f726c6421", encoded.hexEncodedString())
    }

    func testEncodeUTF8String() throws {
        let encoded = try encoder.encode("😀")
        XCTAssertEqual("0c04f09f9880", encoded.hexEncodedString())
    }
    
    func testEncodeBool() throws {
        var encoded = try encoder.encode(true)
        XCTAssertEqual("0101ff", encoded.hexEncodedString())

        encoded = try encoder.encode(false)
        XCTAssertEqual("010100", encoded.hexEncodedString())

    }
    
    func testEncodeInteger() throws {

        var encoded = try encoder.encode(Int.max)
        XCTAssertEqual("02087fffffffffffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(Int.min)
        XCTAssertEqual("02088000000000000000", encoded.hexEncodedString())

        encoded = try encoder.encode(Int64.max)
        XCTAssertEqual("02087fffffffffffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(Int64.min)
        XCTAssertEqual("02088000000000000000", encoded.hexEncodedString())

        encoded = try encoder.encode(Int32.max)
        XCTAssertEqual("02047fffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(Int32.min)
        XCTAssertEqual("020480000000", encoded.hexEncodedString())

        encoded = try encoder.encode(Int16.max)
        XCTAssertEqual("02027fff", encoded.hexEncodedString())

        encoded = try encoder.encode(Int16.min)
        XCTAssertEqual("02028000", encoded.hexEncodedString())

        encoded = try encoder.encode(Int8.max)
        XCTAssertEqual("02017f", encoded.hexEncodedString())

        encoded = try encoder.encode(Int8.min)
        XCTAssertEqual("020180", encoded.hexEncodedString())
        
        encoded = try encoder.encode(UInt.max)
        XCTAssertEqual("020900ffffffffffffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(UInt64.max)
        XCTAssertEqual("020900ffffffffffffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(UInt32.max)
        XCTAssertEqual("020500ffffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(UInt16.max)
        XCTAssertEqual("020300ffff", encoded.hexEncodedString())

        encoded = try encoder.encode(UInt8.max)
        XCTAssertEqual("020200ff", encoded.hexEncodedString())

        encoded = try encoder.encode(UInt8.min)
        XCTAssertEqual("020100", encoded.hexEncodedString())

    }
    
    func testEncodeReal() throws {
        var encoded = try encoder.encode(Float.greatestFiniteMagnitude)
        XCTAssertEqual("0906806800ffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(Double.greatestFiniteMagnitude)
        XCTAssertEqual("090a8103cb1fffffffffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(Double.infinity)
        XCTAssertEqual("090140", encoded.hexEncodedString())

        encoded = try encoder.encode(-Double.infinity)
        XCTAssertEqual("090141", encoded.hexEncodedString())

        encoded = try encoder.encode(Double.nan)
        XCTAssertEqual("090142", encoded.hexEncodedString())

        encoded = try encoder.encode(Double.zero)
        XCTAssertEqual("0900", encoded.hexEncodedString())


    }

    func testEncodeObjectIdentifier() throws {
        
        // Wrapping in an outside structure, since a top level ObjectIdentifier will encode itself as a String
        struct OIDTest: Encodable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(ObjectIdentifier.CN)
            }
        }
        
        var encoded = try encoder.encode(OIDTest())
        XCTAssertEqual("0603550403", encoded.hexEncodedString())
        
        // A toplevel OID will encode itself as a String
        encoded = try encoder.encode(ObjectIdentifier.ST)
        // PrintableString 2.5.4.8
        XCTAssertEqual("1307322e352e342e38", encoded.hexEncodedString())

    }
    
    func testEncodeDictionary() throws {
        
        let value = ["Foo":"Bar"]

        let encoded = try encoder.encode(value)
        XCTAssertEqual("30801303466f6f13034261720000", encoded.hexEncodedString())

    }
    
    func testEncodeOIDMap() throws {
        
        var encoded = try encoder.encode([ObjectIdentifier.CN : "Bar"])
        XCTAssertEqual("3080060355040313034261720000", encoded.hexEncodedString())

        
        encoded = try encoder.encode([ObjectIdentifier.CN : 42])
        XCTAssertEqual("3080060355040302012a0000", encoded.hexEncodedString())
    }
    
    func testEncodeData() throws {
        
        // Wrapping in an outside structure, since a top level Data will encode itself as an array of bytes
        struct DataTest: Encodable {
            
            let data: Data
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(data)
            }
        }
        
        let deadbeef: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
        let data = Data(deadbeef)
        let wrapper = DataTest(data: data)
        var encoded = try encoder.encode(wrapper)
        XCTAssertEqual("030500deadbeef", encoded.hexEncodedString())

        // Try encoding as an array of bytes
        encoded = try encoder.encode(data)
        XCTAssertEqual("3080020200de020200ad020200be020200ef0000", encoded.hexEncodedString())

        
    }
    

    func testEncodeKeyedContainer() throws {
        
        enum CodingKeys: String, CodingKey {
            case name = "name"
            case ok = "ok"
        }
        
        /**
            From X.690 8.9.3 Example
         */
        struct TestSequence: Encodable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                // Added '@' in order to force IA5String, instead of PrintableString
                try container.encode("Smith", forKey: .name)
                try container.encode(true, forKey: .name)
            }
        }
        
        let encoded = try encoder.encode(TestSequence())
        XCTAssertEqual("30801305536d6974680101ff0000", encoded.hexEncodedString())

        
    }
    
    func testEncodeArray() throws {
        let encoded = try encoder.encode(["Peter", "Paul", "Mary"])
        XCTAssertEqual("30801305506574657213045061756c13044d6172790000", encoded.hexEncodedString())
    }

    func testEncodeSet() throws {
        
        struct TestSet: Encodable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(Set(["Peter", "Paul", "Mary"]))
            }
        }
        
        let encoded = try encoder.encode(TestSet())
        XCTAssertEqual("318013044d61727913045061756c130550657465720000", encoded.hexEncodedString())
    }

    
    func testEncodeNil() throws {
        let value: String? = nil
        let encoded = try encoder.encode(value)
        XCTAssertEqual("0500", encoded.hexEncodedString())
    }

    
    
}

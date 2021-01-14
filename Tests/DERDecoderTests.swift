//
//  DERDecoderTests.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/5/21.
//

import XCTest

@testable import ASN1Codable

class DERDecoderTests: XCTestCase {
    
    let decoder = DERDecoder()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDecodePrintableString() throws {
        
        
        //        let encoder = DEREncoder()
        //        let data = try encoder.encode("Hello World!")
        //        print(data.base64EncodedString())
        
        let encoded = Data(hexEncoded: "130b48656c6c6f20576f726c64")
        let decoded = try decoder.decode(String.self, from: encoded)
        XCTAssertEqual("Hello World", decoded)
        
    }
    
    func testEncodeIA5String() throws {
        let encoded = Data(hexEncoded: "160c48656c6c6f20576f726c6421")
        let decoded = try decoder.decode(String.self, from: encoded)
        XCTAssertEqual("Hello World!", decoded)
    }
    
    func testDecodeUTF8String() throws {
        let encoded = Data(hexEncoded: "0c04f09f9880")
        let decoded = try decoder.decode(String.self, from: encoded)
        XCTAssertEqual("😀", decoded)
    }
    
    func testDecodeLongString() throws {
        
        let b64data = """
        FoIB1EFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWkFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWkFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWkFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWkFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWkFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWg==
        """
        
        let encoded = Data(base64Encoded: b64data)!
        let decoded = try decoder.decode(String.self, from: encoded)
        
        XCTAssertEqual(18, decoded.components(separatedBy: "ABCDEFGHIJKLMNOPQRSTUVWXYZ").count - 1)
        
    }
    
    func testDecodeBool() throws {
        
        var encoded = Data(hexEncoded: "0101ff")
        var decoded = try decoder.decode(Bool.self, from: encoded)
        XCTAssertTrue(decoded)
        
        encoded = Data(hexEncoded: "010100")
        decoded = try decoder.decode(Bool.self, from: encoded)
        XCTAssertFalse(decoded)
    }
    
    func testDecodeInteger() throws {
        
        var encoded = Data(hexEncoded: "02087fffffffffffffff")
        XCTAssertEqual(Int.max, try decoder.decode(Int.self, from: encoded))
        
        encoded = Data(hexEncoded: "02023039")
        XCTAssertEqual(Int(12345), try decoder.decode(Int.self, from: encoded))
        
        encoded = Data(hexEncoded: "02088000000000000000")
        XCTAssertEqual(Int.min, try decoder.decode(Int.self, from: encoded))
        
        encoded = Data(hexEncoded: "02087fffffffffffffff")
        XCTAssertEqual(Int64.max, try decoder.decode(Int64.self, from: encoded))
        
        encoded = Data(hexEncoded: "02088000000000000000")
        XCTAssertEqual(Int64.min, try decoder.decode(Int64.self, from: encoded))
        
        encoded = Data(hexEncoded: "02047fffffff")
        XCTAssertEqual(Int32.max, try decoder.decode(Int32.self, from: encoded))
        
        encoded = Data(hexEncoded: "020480000000")
        XCTAssertEqual(Int32.min, try decoder.decode(Int32.self, from: encoded))
        
        encoded = Data(hexEncoded: "02027fff")
        XCTAssertEqual(Int16.max, try decoder.decode(Int16.self, from: encoded))
        
        encoded = Data(hexEncoded: "02028000")
        XCTAssertEqual(Int16.min, try decoder.decode(Int16.self, from: encoded))
        
        encoded = Data(hexEncoded: "02017f")
        XCTAssertEqual(Int8.max, try decoder.decode(Int8.self, from: encoded))
        
        encoded = Data(hexEncoded: "020180")
        XCTAssertEqual(Int8.min, try decoder.decode(Int8.self, from: encoded))
        
        encoded = Data(hexEncoded: "02087fffffffffffffff")
        XCTAssertEqual(UInt(Int.max), try decoder.decode(UInt.self, from: encoded))
        
        encoded = Data(hexEncoded: "02087fffffffffffffff")
        XCTAssertEqual(UInt64(Int.max), try decoder.decode(UInt64.self, from: encoded))
        
        encoded = Data(hexEncoded: "020500ffffffff")
        XCTAssertEqual(UInt32.max, try decoder.decode(UInt32.self, from: encoded))
        
        encoded = Data(hexEncoded: "020300ffff")
        XCTAssertEqual(UInt16.max, try decoder.decode(UInt16.self, from: encoded))
        
        encoded = Data(hexEncoded: "020200ff")
        XCTAssertEqual(UInt8.max, try decoder.decode(UInt8.self, from: encoded))
        
        encoded = Data(hexEncoded: "020100")
        XCTAssertEqual(UInt8.min, try decoder.decode(UInt8.self, from: encoded))
        
    }
    
    func testDecodeBInt() throws {
        let encoded = Data(hexEncoded: "0211008210cfb0d240e3594463e0bb63828b00")
        let expected = BInt("172886928669790476064670243504169061120")!
        XCTAssertEqual(expected.description, try decoder.decode(BInt.self, from: encoded).description)

    }
    
    func testDecodeReal() throws {
        
        var encoded = Data(hexEncoded: "0906806800ffffff")
        XCTAssertEqual(Float.greatestFiniteMagnitude, try decoder.decode(Float.self, from: encoded))
        
        encoded = Data(hexEncoded: "090980d003243f6a8885a3")
        XCTAssertEqual(Double.pi, try decoder.decode(Double.self, from: encoded))
        
        encoded = Data(hexEncoded: "0909c0ce070902de00d1b7")
        XCTAssertEqual(Double(-1.7588), try decoder.decode(Double.self, from: encoded))
        
        encoded = Data(hexEncoded: "090a8103cb1fffffffffffff")
        XCTAssertEqual(Double.greatestFiniteMagnitude, try decoder.decode(Double.self, from: encoded))
        
        encoded = Data(hexEncoded: "090140")
        XCTAssertEqual(Double.infinity, try decoder.decode(Double.self, from: encoded))
        
        encoded = Data(hexEncoded: "090141")
        XCTAssertEqual(-Double.infinity, try decoder.decode(Double.self, from: encoded))
        
        encoded = Data(hexEncoded: "090142")
        XCTAssertTrue(try decoder.decode(Double.self, from: encoded).isNaN)
        
        encoded = Data(hexEncoded: "0900")
        XCTAssertEqual(Double.zero, try decoder.decode(Double.self, from: encoded))
        
    }
    
    func testDecodeNil() throws {
        
        struct NilTest : Decodable {
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                XCTAssertTrue(try container.decodeNil())
            }
        }
        
        let encoded = Data(hexEncoded: "30020500")
        let decoded = try decoder.decode(NilTest.self, from: encoded)
        XCTAssertNotNil(decoded)
        
        
    }
    
    func testDecodeIfExists() throws {
        
        struct UnkeyedIfExistsTest: Decodable {
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                let bool = try container.decodeIfPresent(Bool.self)
                XCTAssertNil(bool)
                let int8 = try container.decodeIfPresent(Int8.self)
                XCTAssertNil(int8)
                let int16 = try container.decodeIfPresent(Int16.self)
                XCTAssertNil(int16)
                let str = try container.decodeIfPresent(String.self)
                XCTAssertNil(str)
            }
            
        }
        
        
        let encoded = Data(hexEncoded: "30020500")
        let _ = try decoder.decode(UnkeyedIfExistsTest.self, from: encoded)
        
    }
    
    func testDecodeObjectIdentifier() throws {
        let encoded = Data(base64Encoded: "BgkqhkiG9w0BAQE=")!
        XCTAssertEqual(OID.rsaEncryption, try decoder.decode(OID.self, from: encoded))
    }
    
    func testDecodeBitString() throws {
        
        let deadbeef: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
        let expected = Data(deadbeef)
        let encoded = Data(hexEncoded: "030500deadbeef")
        XCTAssertEqual(expected, try decoder.decode(Data.self, from: encoded))
    }
    
    func testDecodeUTCTime() throws {
        
        let timeZone = TimeZone(identifier: "America/Detroit")!
        let components = DateComponents(calendar: .current,
                                        timeZone: timeZone,
                                        year: 2020,
                                        month: 12,
                                        day: 25,
                                        hour: 18,
                                        minute: 30,
                                        second: 20)
        
        let expected = components.date!
        
        let encoded = Data(hexEncoded: "170d3230313232353233333032305a")
        XCTAssertEqual(expected, try decoder.decode(Date.self, from: encoded))
        
    }
    
    
    func testDecodeDictionary() throws {
        var encoded = Data(hexEncoded: "300a1303466f6f1303426172")
        let expected1 = ["Foo":"Bar"]
        XCTAssertEqual(expected1, try decoder.decode([String:String].self, from: encoded))

        encoded = Data(hexEncoded: "30091303466f6f020204d2")
        let expected2 = ["Foo":1234]
        XCTAssertEqual(expected2, try decoder.decode([String:Int].self, from: encoded))

    }
    
    func testDecodeOIDMap() throws {
                
        var encoded = Data(hexEncoded: "3080060355040313034261720000")
        let expected1 = [OID.CN : "Bar"]
        XCTAssertEqual(expected1, try decoder.decode([OID:String].self, from: encoded))
        
        encoded = Data(hexEncoded: "3008060355040302012a")
        let expected2 = [OID.CN : 42]
        XCTAssertEqual(expected2, try decoder.decode([OID:Int].self, from: encoded))
        
    }
    
    func testDecodeNestedStructs() throws {
        let expected = OuterClass(property1: InnerClass(value: 1), property2: InnerClass(value: 2))
        
        let encoded = Data(hexEncoded: "300a30030201013003020102")
        XCTAssertEqual(expected, try decoder.decode(OuterClass.self, from: encoded))
    }
    
    func testDecodeKeyedContainer() throws {

        /**
            From X.690 8.9.3 Example
         */
        struct TestSequence: Decodable, Equatable {
            
            let name: String
            let ok: Bool
            
            enum CodingKeys: String, CodingKey {
                case name = "name"
                case ok = "ok"
            }
            
            init(name: String, ok: Bool) {
                self.name = name
                self.ok = ok
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.ok = try container.decode(Bool.self, forKey: .ok)
            }
        }
        
        let expected = TestSequence(name: "Smith", ok: true)
        
        let encoded = Data(hexEncoded: "300a1305536d6974680101ff")
        XCTAssertEqual(expected, try decoder.decode(TestSequence.self, from: encoded))

        
    }
    
    func testDecodeArray() throws {
        let encoded = Data(hexEncoded: "30131305506574657213045061756c13044d617279")
        let expected = ["Peter", "Paul", "Mary"]
        XCTAssertEqual(expected, try decoder.decode([String].self, from: encoded))
    }
    
    func testDecodeSet() throws {
        let encoded = Data(hexEncoded: "311313044d61727913045061756c13055065746572")
        let expected = Set(["Peter", "Paul", "Mary"])
        XCTAssertEqual(expected, try decoder.decode(Set<String>.self, from: encoded))
    }
    
    
}



fileprivate struct OuterClass: Decodable, Equatable {

    
    static func == (lhs: OuterClass, rhs: OuterClass) -> Bool {
        return lhs.property1.value == rhs.property1.value
            && lhs.property2.value == rhs.property2.value
    }
    
    
    let property1: InnerClass
    let property2: InnerClass
    
    init(property1: InnerClass, property2: InnerClass) {
        self.property1 = property1
        self.property2 = property2
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        property1 = try container.decode(InnerClass.self)
        property2 = try container.decode(InnerClass.self)
    }
}


fileprivate struct InnerClass: Decodable {
    
    let value: Int
    
    init(value: Int) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.value = try container.decode(Int.self)
    }
    
}


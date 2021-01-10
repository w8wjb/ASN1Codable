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
    
    func testEncodeLongString() throws {
        let longString = String(repeating: "ABCDEFGHIJKLMNOPQRSTUVWXYZ", count: 9)
        
        let encoded = try encoder.encode(longString)
        XCTAssertEqual("1681ea4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a", encoded.hexEncodedString())
    }
    
    func testEncodeBool() throws {
        var encoded = try encoder.encode(true)
        XCTAssertEqual("0101ff", encoded.hexEncodedString())

        encoded = try encoder.encode(false)
        XCTAssertEqual("010100", encoded.hexEncodedString())

    }
    
    func testEncodeInteger() throws {

        var encoded = try encoder.encode(12345)
        XCTAssertEqual("02023039", encoded.hexEncodedString())

        encoded = try encoder.encode(Int.max)
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
        
        encoded = try encoder.encode(UInt(Int.max))
        XCTAssertEqual("02087fffffffffffffff", encoded.hexEncodedString())

        encoded = try encoder.encode(UInt64(Int.max))
        XCTAssertEqual("02087fffffffffffffff", encoded.hexEncodedString())

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

        
        encoded = try encoder.encode(Double.pi)
        XCTAssertEqual("090980d003243f6a8885a3", encoded.hexEncodedString())

        encoded = try encoder.encode(Double(-1.7588))
        XCTAssertEqual("0909c0ce070902de00d1b7", encoded.hexEncodedString())
        
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
                try container.encode(OID.CN)
            }
        }
        
        var encoded = try encoder.encode(OIDTest())
        XCTAssertEqual("0603550403", encoded.hexEncodedString())
        
        // A toplevel OID will encode itself as a String
        encoded = try encoder.encode(OID.ST)
        // PrintableString 2.5.4.8
        XCTAssertEqual("1307322e352e342e38", encoded.hexEncodedString())

    }
    
    func testEncodeDictionary() throws {
        
        var encoded = try encoder.encode(["Foo":"Bar"])
        XCTAssertEqual("300a1303466f6f1303426172", encoded.hexEncodedString())

        encoded = try encoder.encode(["Foo" : 1234])
        XCTAssertEqual("30091303466f6f020204d2", encoded.hexEncodedString())

        
    }
    
    func testEncodeOIDMap() throws {
        
        var encoded = try encoder.encode([OID.CN : "Bar"])
        XCTAssertEqual("300a06035504031303426172", encoded.hexEncodedString())

        
        encoded = try encoder.encode([OID.CN : 42])
        XCTAssertEqual("3008060355040302012a", encoded.hexEncodedString())
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
        XCTAssertEqual("3010020200de020200ad020200be020200ef", encoded.hexEncodedString())

        
    }
    
    func testEncodeDate() throws {

        // Wrapping in an outside structure, since a top level Date will encode itself as a Double
        struct DateTest: Encodable {
            
            let date: Date
            
            init() {
                let timeZone = TimeZone(identifier: "America/Detroit")!
                let components = DateComponents(calendar: .current,
                                                timeZone: timeZone,
                                                year: 2020,
                                                month: 12,
                                                day: 25,
                                                hour: 18,
                                                minute: 30,
                                                second: 20)

                self.date = components.date!
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(date)
            }
        }
        
        let obj = DateTest()
        let encoded = try encoder.encode(obj)
        XCTAssertEqual("170d3230313232353233333032305a", encoded.hexEncodedString())
        
    }
    

    func testEncodeKeyedContainer() throws {
                
        /**
            From X.690 8.9.3 Example
         */
        struct TestSequence: Encodable {
            enum CodingKeys: String, CodingKey {
                case name = "name"
                case ok = "ok"
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                // Added '@' in order to force IA5String, instead of PrintableString
                try container.encode("Smith", forKey: .name)
                try container.encode(true, forKey: .name)
            }
        }
        
        let encoded = try encoder.encode(TestSequence())
        XCTAssertEqual("300a1305536d6974680101ff", encoded.hexEncodedString())
        
    }
    
    func testEncodeArray() throws {
        let encoded = try encoder.encode(["Peter", "Paul", "Mary"])
        XCTAssertEqual("30131305506574657213045061756c13044d617279", encoded.hexEncodedString())
    }

    func testEncodeSet() throws {
        
        struct TestSet: Encodable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(Set(["Peter", "Paul", "Mary"]))
            }
        }
        
        let encoded = try encoder.encode(TestSet())
        XCTAssertEqual("311313044d61727913045061756c13055065746572", encoded.hexEncodedString())
    }

    
    func testEncodeNil() throws {
        
        struct NilTest : Encodable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encodeNil()
            }
        }
        
        let encoded = try encoder.encode(NilTest())
        XCTAssertEqual("30020500", encoded.hexEncodedString())
    }

    func testEncodeNestedStructs() throws {
        

        struct InnerClass: Encodable {
            
            let value: Int
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(value)
            }
            
        }
        

        struct OuterClass: Encodable {
            
            let property1: InnerClass
            let property2: InnerClass
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(property1)
                try container.encode(property2)
            }
            
        }
        
        let obj = OuterClass(property1: InnerClass(value: 1), property2: InnerClass(value: 2))
        
        let encoded = try encoder.encode(obj)
        print(encoded.base64EncodedString())
        XCTAssertEqual("300a30030201013003020102", encoded.hexEncodedString())

        
    }
    
}

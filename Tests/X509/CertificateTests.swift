//
//  CertificateTests.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/14/21.
//

import XCTest

@testable import ASN1Codable


class CertificateTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeCertificateExample1() throws {

        let certPath = Bundle(for: CertificationRequestTests.self).path(forResource: "1024b-rsa-example-cert", ofType: "der")!
        let certData = try Data(contentsOf: URL(fileURLWithPath: certPath))
        
        let decoder = DERDecoder()
        let cert = try decoder.decode(Certificate.self, from: certData)
        
        XCTAssertEqual("3579", cert.tbsCertificate.serialNumber.description)
        XCTAssertEqual(SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA1, cert.signatureAlgorithm)
    }
    
    func testDecodeCertificateLetsEncryptRoot() throws {

        let certPath = Bundle(for: CertificationRequestTests.self).path(forResource: "isrgrootx1", ofType: "der")!
        let certData = try Data(contentsOf: URL(fileURLWithPath: certPath))
        
        let decoder = DERDecoder()
        let cert = try decoder.decode(Certificate.self, from: certData)
        
        XCTAssertEqual("172886928669790476064670243504169061120", cert.tbsCertificate.serialNumber.description)
        XCTAssertEqual(3, cert.tbsCertificate.extensions!.count)
        
        for ext in cert.tbsCertificate.extensions! {
            print(ext.id.description)
        }
        
        XCTAssertEqual(SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256, cert.signatureAlgorithm!)
        print(cert)

    }

}

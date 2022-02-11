//
//  CertificateTests.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/14/21.
//

import XCTest

@testable import ASN1Codable


class CertificateTests: XCTestCase {
    
    
    var privateKey: SecKey!
    var publicKey: SecKey!

    override func setUpWithError() throws {
        
        let path = Bundle(for: CertificateTests.self).path(forResource: "test.private", ofType: "key")!
        let keyData = try Data(contentsOf: URL(fileURLWithPath: path))
        
        let attributes: [CFString : Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits: 1024
        ]
        
        
        var error: Unmanaged<CFError>?
        privateKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error)
        if let error = error {
            throw error.takeRetainedValue()
        }
        assert(privateKey != nil)
        
        publicKey = SecKeyCopyPublicKey(privateKey)
        assert(publicKey != nil)

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
            print(ext.value.hexEncodedString())
        }
        
        XCTAssertEqual(SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256, cert.signatureAlgorithm!)
        

    }
    
    func testEncodeCertificateLetsEncryptRoot() throws {
        
        let certPath = Bundle(for: CertificationRequestTests.self).path(forResource: "isrgrootx1", ofType: "der")!
        let certData = try Data(contentsOf: URL(fileURLWithPath: certPath))
        let hexCertData = certData.hexEncodedString()
        
        let decoder = DERDecoder()
        let inputCert = try decoder.decode(Certificate.self, from: certData)

        let encoder = DEREncoder()
        let encoded = try encoder.encode(inputCert)
        let hexEncoded = encoded.hexEncodedString()
        
        XCTAssertEqual(hexCertData, hexEncoded)
        
        XCTAssertTrue(try inputCert.verify())
    }

    
    func testSelfSign() throws {
        
        let dn = DistinguishedName((.C, "US"),
                                   (.L, "Orbit City"),
                                   (.O, "Spacely Sprockets"))
        
        let tbs = TBSCertificate(serialNumber: BInt(1234),
                                 issuer: dn,
                                 notBefore: Date(),
                                 notAfter: Date().addingTimeInterval(126227702), // 4 years from now
                                 subject: dn,
                                 publicKey: publicKey)
        
        var cert = Certificate(tbsCertificate: tbs)

        
        try cert.sign(privateKey: privateKey, algorithm: .rsaSignatureMessagePKCS1v15SHA1)

        XCTAssertNotNil(cert.signatureAlgorithm)
        XCTAssertNotNil(cert.signature)

        XCTAssertTrue(try cert.verify())
        
        let pem = try PEMTools.wrap(cert)

        XCTAssertTrue(pem.contains("-----END CERTIFICATE-----"))
        
        
    }
    
}

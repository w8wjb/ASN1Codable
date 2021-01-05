//
//  CertificationRequestTests.swift
//  ASN1CodableTests
//
//  Created by Weston Bustraan on 1/4/21.
//

import XCTest

@testable import ASN1Codable

class CertificationRequestTests: XCTestCase {

    let encoder = DEREncoder()
    
    var privateKey: SecKey!
    var publicKey: SecKey!
    
    override func setUpWithError() throws {
        
        let path = Bundle(for: CertificationRequestTests.self).path(forResource: "test.private", ofType: "key")!
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

    func testEncodeCertificationRequest() throws {

        let dn = DistinguishedName((.C, "US"),
                                   (.L, "Orbit City"),
                                   (.O, "Spacely Sprockets"))
        
        
        var certInfo = CertificationRequestInfo(subject: dn, publicKey: publicKey)
        
        certInfo.attributes.append(Attribute<String>(type: ObjectIdentifier.challengePassword, values: "asdfasdf"))
        
        var csr = CertificationRequest(info: certInfo)
        try csr.sign(privateKey: privateKey, algorithm: .rsaSignatureMessagePKCS1v15SHA1)
        
        encoder.tagStrategy = CertificationRequest.TagStrategy()
        
        let encoded = try encoder.encode(csr)
        //try encoded.write(to: URL(fileURLWithPath: "/Users/weston/tmp/test.der"))
        
        let expected = """
3080308002010030803180308006035504061302555300000000318030800603550407130a4f7262697420436974790000000031803080060355040a131153706163656c79205370726f636b6574730000000000003080308006092a864886f70d010101050000000382010f003082010a0282010100c717018d511434d3ebba6f348bb94942759ade08bf0097d99f72499cfda08f0c4e84795df6eaa872812007213930e29bb3c547119419d7a29dd86ce4029092aa322cdc96f6bf028de096c8f1d6bc93e2deb9f95f30202c331f3297a041e4b5ecf4cb22d497c7e83f55c01b814700a683c4d733ddd35a4bcca2168a60f75407b2ed5e12c6ad94c7b77d8fe0b918f0f1b1f0631dfe53171a75279387699a96a56cd75c9e70adacf93b2b0fe2bb914178338065a5427241db61d3c3f2193dc33d221c605b0ae6304026f0f53c49933c974b9073a2da87ebbcd55a41dd552cfa8b870ee4938aa936f80fd34c2b18b3760f313dd1171026e04b4bce182fb0fcf74e7b02030100010000a080308006092a864886f70d0109073180130861736466617364660000000000000000308006092a864886f70d010105050000000382010100192f5accaddc88466e96bcc364da354904571a9d973adcb027bbdda92ebbe61dc43b17fc0166020335b7251497c723cd43792be14f0430b34196256cbb6c237c481e9e4f80eb789f895a3a518412e284d82bce3b007780dd7978b10e4b75d826b9b7db270fec6ddf76d0b6ba582ad52edfc433f29a972466a55e3e469f28afa3eb130d23debb9c3a6c6ebb9ec40a414c3a8779b1ecafdaaec5e6d467b9186a084bc56f11620ef1dafba899f7dedbe51c35b71483073f9f6094fa3726dc3d034dc37fd0442d93eddc43c27d258d6a26bd44481caaa22712007e26af4bf0844e8a3c73f6494e289dc4a5168e3a93e8c9a7722f3991db50935735710a0c000dd92d0000
"""
        
        XCTAssertEqual(expected, encoded.hexEncodedString())


    }


}

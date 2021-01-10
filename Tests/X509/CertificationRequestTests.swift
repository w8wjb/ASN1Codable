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
    let decoder = DERDecoder()
    
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
        
        certInfo.attributes.append(Attribute<String>(type: OID.challengePassword, values: "asdfasdf"))
        
        var csr = CertificationRequest(info: certInfo)
        try csr.sign(privateKey: privateKey, algorithm: .rsaSignatureMessagePKCS1v15SHA1)
        
        encoder.tagStrategy = CertificationRequest.TagStrategy()
        
        let encoded = try encoder.encode(csr)
        //try encoded.write(to: URL(fileURLWithPath: "/Users/weston/tmp/test.der"))
        
        let expected = """
3082029c30820184020100303e310b3009060355040613025553311330110603550407130a4f726269742043697479311a3018060355040a131153706163656c79205370726f636b65747330820122300d06092a864886f70d01010105000382010f003082010a0282010100c717018d511434d3ebba6f348bb94942759ade08bf0097d99f72499cfda08f0c4e84795df6eaa872812007213930e29bb3c547119419d7a29dd86ce4029092aa322cdc96f6bf028de096c8f1d6bc93e2deb9f95f30202c331f3297a041e4b5ecf4cb22d497c7e83f55c01b814700a683c4d733ddd35a4bcca2168a60f75407b2ed5e12c6ad94c7b77d8fe0b918f0f1b1f0631dfe53171a75279387699a96a56cd75c9e70adacf93b2b0fe2bb914178338065a5427241db61d3c3f2193dc33d221c605b0ae6304026f0f53c49933c974b9073a2da87ebbcd55a41dd552cfa8b870ee4938aa936f80fd34c2b18b3760f313dd1171026e04b4bce182fb0fcf74e7b0203010001a019301706092a864886f70d010907310a13086173646661736466300d06092a864886f70d0101050500038201010081a029d4af73d6ab05b3d35f1816ac8cb0dabb3b23b2361628c8fa2d686f19b8ac3f1594f8d09cdc38748742eb014d06c93cf6d0566103565cad12e775eb2b3f9bae91787f640c84b9abc6f9bb0251621221c6d806bfd3c016cb732069ba743e213a2bbde6a21667e8201e168a94913af8ca2928ff8eaefdf1bd84ea2402961fa7a8c38a36bf42f48d178a1d364620cba4e5a62d2fac4f404f404914feffa760daa76826e169a1ba50b0d128f8a6a9f2110be6eee9103e3f75dc8546935b89f3673b1150492293d6df67e0e17ebe242e6ad4bca4d48a74769b4a6f6622e5b1cb9f5140601e2b7f97cd4e8d4772fc872e3c8789bb0e1e11a227f3639b4a0bd581
"""
        
        XCTAssertEqual(expected, encoded.hexEncodedString())
        
        
    }
    
    func testPEMWrapper() throws {
        
        let dn = DistinguishedName((.C, "US"),
                                   (.L, "Orbit City"),
                                   (.O, "Spacely Sprockets"))
        
        
        var certInfo = CertificationRequestInfo(subject: dn, publicKey: publicKey)
        
        certInfo.attributes.append(Attribute<String>(type: OID.challengePassword, values: "asdfasdf"))
        
        var csr = CertificationRequest(info: certInfo)
        try csr.sign(privateKey: privateKey, algorithm: .rsaSignatureMessagePKCS1v15SHA1)
        
        let pem = try PEMTools.wrap(csr)
        
        
        let path = Bundle(for: CertificationRequestTests.self).path(forResource: "test.expected", ofType: "csr")!
        
        let expected = try String(contentsOf: URL(fileURLWithPath: path))
        XCTAssertEqual(expected, pem)

    }
    
    func testDecodeCertificationRequestWithAttributes() throws {
        
        let encoded = """
3082029c30820184020100303e310b3009060355040613025553311330110603550407130a4f726269742043697479311a3018060355040a131153706163656c79205370726f636b65747330820122300d06092a864886f70d01010105000382010f003082010a0282010100c717018d511434d3ebba6f348bb94942759ade08bf0097d99f72499cfda08f0c4e84795df6eaa872812007213930e29bb3c547119419d7a29dd86ce4029092aa322cdc96f6bf028de096c8f1d6bc93e2deb9f95f30202c331f3297a041e4b5ecf4cb22d497c7e83f55c01b814700a683c4d733ddd35a4bcca2168a60f75407b2ed5e12c6ad94c7b77d8fe0b918f0f1b1f0631dfe53171a75279387699a96a56cd75c9e70adacf93b2b0fe2bb914178338065a5427241db61d3c3f2193dc33d221c605b0ae6304026f0f53c49933c974b9073a2da87ebbcd55a41dd552cfa8b870ee4938aa936f80fd34c2b18b3760f313dd1171026e04b4bce182fb0fcf74e7b0203010001a019301706092a864886f70d010907310a13086173646661736466300d06092a864886f70d0101050500038201010081a029d4af73d6ab05b3d35f1816ac8cb0dabb3b23b2361628c8fa2d686f19b8ac3f1594f8d09cdc38748742eb014d06c93cf6d0566103565cad12e775eb2b3f9bae91787f640c84b9abc6f9bb0251621221c6d806bfd3c016cb732069ba743e213a2bbde6a21667e8201e168a94913af8ca2928ff8eaefdf1bd84ea2402961fa7a8c38a36bf42f48d178a1d364620cba4e5a62d2fac4f404f404914feffa760daa76826e169a1ba50b0d128f8a6a9f2110be6eee9103e3f75dc8546935b89f3673b1150492293d6df67e0e17ebe242e6ad4bca4d48a74769b4a6f6622e5b1cb9f5140601e2b7f97cd4e8d4772fc872e3c8789bb0e1e11a227f3639b4a0bd581
"""
        
        let data = Data(hexEncoded: encoded)
        
        decoder.tagStrategy = CertificationRequest.TagStrategy()
        
        let csr = try decoder.decode(CertificationRequest.self, from: data)
        
        XCTAssertTrue(try csr.verify())
        
    }
    
    func testDecodeCertificationRequestWithoutAttributes() throws {
        
        let encoded = """
308202833082016b020100303e310b3009060355040613025553311330110603550407130a4f726269742043697479311a3018060355040a131153706163656c79205370726f636b65747330820122300d06092a864886f70d01010105000382010f003082010a0282010100c717018d511434d3ebba6f348bb94942759ade08bf0097d99f72499cfda08f0c4e84795df6eaa872812007213930e29bb3c547119419d7a29dd86ce4029092aa322cdc96f6bf028de096c8f1d6bc93e2deb9f95f30202c331f3297a041e4b5ecf4cb22d497c7e83f55c01b814700a683c4d733ddd35a4bcca2168a60f75407b2ed5e12c6ad94c7b77d8fe0b918f0f1b1f0631dfe53171a75279387699a96a56cd75c9e70adacf93b2b0fe2bb914178338065a5427241db61d3c3f2193dc33d221c605b0ae6304026f0f53c49933c974b9073a2da87ebbcd55a41dd552cfa8b870ee4938aa936f80fd34c2b18b3760f313dd1171026e04b4bce182fb0fcf74e7b0203010001a000300d06092a864886f70d010105050003820101007d996b02ec6955a1a59d6e2386a2d118295b44c8299615f518c6ab03599c9abfeed3b9b5c819ba8cba597319b90fccd6d33123a5fd359573b27636eea431ef680728fad93f3c0725c67fac5493ea98d1bdcdc4dc2e3b042ead94f085e3a9b07ac0a495d61a1820881335ceb35e688065f6db4a5c0461bb8660b02b1b3a5e7ea1fad0d4446727527db386e6904d46d8a91b6f684451b4570a88ed427c5ae6a4eb33ab3fce93bfd3ddb8a9840dd197e44f9e2005ca67f7dffddeb566f93b5e79d5138d69c2d983b7b3adbdc963c546548320dd32952a31f00632f3b05fa8e79e2d0e1c1d207fe73a641b278dde8487a89623ec559eb63ec5c8f22759133e0c5b3f
"""
        
        let data = Data(hexEncoded: encoded)
        
        decoder.tagStrategy = CertificationRequest.TagStrategy()
        
        let csr = try decoder.decode(CertificationRequest.self, from: data)
        
        XCTAssertTrue(try csr.verify())
        
    }
    
}

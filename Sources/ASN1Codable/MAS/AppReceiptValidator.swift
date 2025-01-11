//
//  AppReceiptValidator.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/5/25.
//
import Foundation
import CommonCrypto
#if os(macOS)
import IOKit
#elseif os(iOS)
import UIKit
#endif

public class AppReceiptValidator {
    
    let appleRootCertHash = "2bd06947947609fef46b8d2e40a6f7474d7f085e"
    let appleRootCertFilename = "AppleIncRootCertificate"

    public let container: PKCS7Container
    public var receipt: AppReceipt
    public var bundleIdentifier: String
    public var appVersion: String
    public var appleRootCert: SecCertificate?
    
    
    public convenience init(receiptURL: URL, bundleIdentifier: String? = nil, appVersion: String? = nil) throws {
        try self.init(data: try Data(contentsOf:receiptURL), bundleIdentifier: bundleIdentifier, appVersion: appVersion)
    }
    
    public init(data: Data, bundleIdentifier: String? = nil, appVersion: String? = nil) throws {
        
        let decoder = DERDecoder()
        self.container = try decoder.decode(PKCS7Container.self, from: data)
        
        guard let receipt = try container.getContent(as: AppReceipt.self) else {
            throw ValidationError.missingData(field: "AppReceipt")
        }
        self.receipt = receipt
        
        self.bundleIdentifier = bundleIdentifier ?? Bundle.main.bundleIdentifier ?? ""
        self.appVersion = appVersion ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        
    }
    
    private func locateAppleRootCertificate(certURL: URL? = nil) throws -> SecCertificate {
        
        let certData: Data
        
        if let certURL = certURL {
            certData = try Data(contentsOf: certURL)
            
        } else {
            guard let embeddedCertURL = Bundle.module.url(forResource: appleRootCertFilename, withExtension: "cer") else {
                throw ValidationError.missingRootCertificate
            }
            certData = try Data(contentsOf: embeddedCertURL)
        }
        
        
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            throw ValidationError.missingRootCertificate
        }
        return certificate
    }
    
#if os(macOS)

    // Returns an object with a +1 retain count; the caller needs to release.
    private func io_service(named name: String, wantBuiltIn: Bool) -> io_service_t? {
        let default_port = kIOMasterPortDefault
        var iterator = io_iterator_t()
        defer {
            if iterator != IO_OBJECT_NULL {
                IOObjectRelease(iterator)
            }
        }


        guard let matchingDict = IOBSDNameMatching(default_port, 0, name),
            IOServiceGetMatchingServices(default_port,
                                         matchingDict as CFDictionary,
                                         &iterator) == KERN_SUCCESS,
            iterator != IO_OBJECT_NULL
        else {
            return nil
        }


        var candidate = IOIteratorNext(iterator)
        while candidate != IO_OBJECT_NULL {
            if let cftype = IORegistryEntryCreateCFProperty(candidate,
                                                            "IOBuiltin" as CFString,
                                                            kCFAllocatorDefault,
                                                            0) {
                let isBuiltIn = cftype.takeRetainedValue() as! CFBoolean
                if wantBuiltIn == CFBooleanGetValue(isBuiltIn) {
                    return candidate
                }
            }


            IOObjectRelease(candidate)
            candidate = IOIteratorNext(iterator)
        }


        return nil
    }
#endif
    
    private func getPlatformGUID() throws -> Data? {
#if os(macOS)
        
        // Prefer built-in network interfaces.
        // For example, an external Ethernet adaptor can displace
        // the built-in Wi-Fi as en0.
        guard let service = io_service(named: "en0", wantBuiltIn: true)
                ?? io_service(named: "en1", wantBuiltIn: true)
                ?? io_service(named: "en0", wantBuiltIn: false)
        else { return nil }
        defer { IOObjectRelease(service) }
        
        
        if let cftype = IORegistryEntrySearchCFProperty(
            service,
            kIOServicePlane,
            "IOMACAddress" as CFString,
            kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) {
            return (cftype as? Data)
        }
        

        return nil
#elseif os(watchOS)
        return nil
#else
        
        if let uuid = UIDevice.current.identifierForVendor {
            var uuidBytes = uuid.uuid
            let data = Data(bytes: &uuidBytes, count: MemoryLayout.size(ofValue: uuidBytes))
            return data
            
        } else {
            return nil
        }
#endif
    }
    
    public func validateCertificateTrust(rootCert: SecCertificate) throws {
        guard let receiptCreationDate = receipt.receiptCreationDate else {
            throw ValidationError.missingData(field: "receipt_creation_date")
        }
        
        try container.verify(rootCert: rootCert, verifyDate: receiptCreationDate)
    }
    
    public func computeDeviceHash() throws -> Data {
        
        guard let opaqueValue = receipt.opaqueValue else {
            throw ValidationError.missingData(field: "opaqueValue")
        }
        
        guard let bundleIdentifierData = receipt.bundleIdData else {
            throw ValidationError.missingData(field: "bundleIdentifier")
        }
        
        guard let platformGUID = try getPlatformGUID() else {
            throw ValidationError.platformUUIDUnavailable
        }
        
        var ctx = CC_SHA1_CTX()
        
        guard CC_SHA1_Init(&ctx) == 1 else { throw ValidationError.hashingFailed }
        
        guard platformGUID.withUnsafeBytes({
            CC_SHA1_Update(&ctx, $0.baseAddress, CC_LONG($0.count))
        }) == 1 else { throw ValidationError.hashingFailed }

        guard opaqueValue.withUnsafeBytes({
            CC_SHA1_Update(&ctx, $0.baseAddress, CC_LONG($0.count))
        }) == 1 else { throw ValidationError.hashingFailed }

        guard bundleIdentifierData.withUnsafeBytes({
            CC_SHA1_Update(&ctx, $0.baseAddress, CC_LONG($0.count))
        }) == 1 else { throw ValidationError.hashingFailed }

        var hash = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        
        guard CC_SHA1_Final(&hash, &ctx) == 1 else { throw ValidationError.hashingFailed }
        
        return Data(hash)
    }
    
    
    public func validate() throws {
        
        // Step 1: Locate and load the app receipt from the app’s bundle.
        // The class Bundle provides the location of the receipt with the property appStoreReceiptURL.
        // We're here, so this is already done
        
        // Step 2: Decode the app receipt as a PKCS #7 container and verify that the chain of trust for the container’s signature
        // traces back to the Apple Inc. Root certificate, available from Apple PKI. Use the receipt_creation_date,
        // identified as ASN.1 Field Type 12 when validating the receipt signature.
        let appleRootCert = try self.appleRootCert ?? locateAppleRootCertificate()
        try validateCertificateTrust(rootCert: appleRootCert)
        
        
        // Step 3: Verify that the bundle identifier, identified as ASN.1 Field Type 2, matches your app’s bundle identifier.
        guard self.bundleIdentifier == receipt.bundleId else {
            throw ValidationError.bundleIdentifierMismatch
        }
        
        // Step 4: Verify that the version identifier string, identified as ASN.1 Field Type 3, matches the version string in your app’s bundle.
        guard self.bundleIdentifier == receipt.bundleId else {
            throw ValidationError.bundleIdentifierMismatch
        }
        
        // Step 5: Compute a SHA-1 hash for the device that installs the app and verify that it matches the receipt’s hash, identified as ASN.1 Field Type 5.
        let deviceHash = try computeDeviceHash()
        
        guard deviceHash == receipt.sha1Digest else {
            throw ValidationError.hashInvalid
        }
    }
    
    
}

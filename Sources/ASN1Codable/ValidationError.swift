//
//  ValidationError.swift
//  ASN1Codable
//
//  Created by Weston Bustraan on 1/5/25.
//

public enum ValidationError: Error {
    
    case missingSignatureAlgorithm
    case missingCertificate(serial: BInt?)
    case missingRootCertificate
    case couldNotReadCertificate
    case missingData(field: String)
    case certificateNotTrusted
    case containerNotSigned
    case signatureInvalid
    case bundleIdentifierMismatch
    case platformUUIDUnavailable
    case hashInvalid
    case hashingFailed
}

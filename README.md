# ASN1Codable

**ASN1Codable** is a Swift library for encoding and decoding ASN.1 data, designed to integrate with Swift's `Codable` protocol.

## What is ASN.1 and DER Encoding?

ASN.1 (Abstract Syntax Notation One) is a standard interface description language used to define data structures for representing, encoding, transmitting, and decoding data. It’s widely used in telecommunications, cryptography, and various file formats.

**DER (Distinguished Encoding Rules)** is a subset of ASN.1 encoding rules designed to produce unambiguous binary representations of data structures, ensuring compatibility across systems.

### Common Uses of ASN.1 and DER Encoding
- **Public Key Infrastructure (PKI):** Encoding certificates (e.g., X.509), certificate signing requests (CSRs), and other cryptographic data.
- **Cryptographic Protocols:** Encoding keys and digital signatures.
- **Mac App Store Receipts:** Representing purchase and subscription information for app validation.
- **Telecommunications Protocols:** Encoding signaling messages in mobile networks.

## Features

- Simplified parsing and encoding of ASN.1 DER and BER data.
- Support for common ASN.1 types, including integers, strings, and sequences.
- Easy integration with Swift's `Codable` for type-safe data manipulation.
- Initial support for PKI certificates and certificate signing requests.
- **New Feature:** Decoding of Mac App Store receipts.
- Fully open source and available under the MIT license.

## Installation

You can add **ASN1Codable** to your project using the Swift Package Manager (SPM).

1. In Xcode, go to **File > Add Packages...**.
2. Enter the repository URL:
   ```
   https://github.com/w8wjb/ASN1Codable
   ```
3. Choose a version or branch and add the package to your project.

Alternatively, update your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/w8wjb/ASN1Codable", from: "1.0.0")
]
```

# Getting Started

## Basic Usage

### Decoding an SSL Certificate

```swift
let certPath = "path/to/der/certificate"
let certData = try Data(contentsOf: URL(fileURLWithPath: certPath))

let decoder = DERDecoder()
let cert = try decoder.decode(Certificate.self, from: certData)
```

### Generating a self-signed certificate

```swift

let privateKeyPath = "path/to/private.key"
let keyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))

let attributes: [CFString : Any] = [
    kSecAttrKeyType: kSecAttrKeyTypeRSA,
    kSecAttrKeyClass: kSecAttrKeyClassPrivate,
    kSecAttrKeySizeInBits: 1024
]


var error: Unmanaged<CFError>?
let privateKey: SecKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error)
if let error = error {
    throw error.takeRetainedValue()
}

let publicKey: SecKey = SecKeyCopyPublicKey(privateKey)


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

```


### Decoding custom ASN.1 Data

Here’s an example of decoding an ASN.1-encoded sequence:

```swift
import ASN1Codable

struct Certificate: Codable {
    let version: Int
    let serialNumber: String
    let issuer: String
    let subject: String
}

let derData: Data = ... // ASN.1 DER-encoded data
do {
    let decoder = ASN1Decoder()
    let certificate = try decoder.decode(Certificate.self, from: derData)
    print("Issuer: \(certificate.issuer)")
} catch {
    print("Failed to decode: \(error)")
}
```

### Encoding custom ASN.1 Data

```swift
import ASN1Codable

let certificate = Certificate(version: 2, serialNumber: "12345", issuer: "CA Inc.", subject: "John Doe")
do {
    let encoder = ASN1Encoder()
    let derData = try encoder.encode(certificate)
    print("Encoded DER data: \(derData)")
} catch {
    print("Failed to encode: \(error)")
}
```

## Documentation

For a detailed guide on supported ASN.1 types and custom configuration options, visit the [Wiki](https://github.com/w8wjb/ASN1Codable/wiki).

## Contributing

We welcome contributions from the community! To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request.


## License

**ASN1Codable** is distributed under the MIT license. See [LICENSE](https://github.com/w8wjb/ASN1Codable/blob/main/LICENSE) for more information.


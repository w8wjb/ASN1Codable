// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ASN1Codable",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ASN1Codable",
            targets: ["ASN1Codable"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ASN1Codable",
            dependencies: [],
            path: "Sources",
            resources: [
                .copy("Resources/AppleIncRootCertificate.cer")
            ]
        ),
        .testTarget(
            name: "ASN1CodableTests",
            dependencies: ["ASN1Codable"],
            path: "Tests",
                resources: [
                    .copy("./X509/1024b-rsa-example-cert.der"),
                    .copy("./X509/1024b-rsa-example-cert.pem"),
                    .copy("./X509/isrgrootx1.der"),
                    .copy("./X509/isrgrootx1.pem"),
                    .copy("./X509/test.expected.csr"),
                    .copy("./X509/test.private.key"),
                    .copy("./MAS/gb_receipt.der"),
                    .copy("./MAS/qth_sandbox_receipt.der")
            ]
        ),
    ]
)

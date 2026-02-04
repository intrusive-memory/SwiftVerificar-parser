// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftVerificarParser",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftVerificarParser",
            targets: ["SwiftVerificarParser"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftVerificarParser"
        ),
        .testTarget(
            name: "SwiftVerificarParserTests",
            dependencies: ["SwiftVerificarParser"]
        ),
    ]
)

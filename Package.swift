// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-foundation-extensions",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FoundationExtensions", targets: ["FoundationExtensions"]),
    ],
    targets: [
        .target(name: "FoundationExtensions", resources: [.process("Localizable.xcstrings")],
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "FoundationExtensionsTests", dependencies: ["FoundationExtensions"],
                    swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)

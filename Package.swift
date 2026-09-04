// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Subprocess",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Subprocess", targets: ["Subprocess"]),
    ],
    targets: [
        .target(name: "Subprocess", path: "Sources",
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "SubprocessTests", dependencies: ["Subprocess"], path: "Tests"),
    ]
)

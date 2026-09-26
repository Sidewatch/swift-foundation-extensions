// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ProcessRunner",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProcessRunner", targets: ["ProcessRunner"]),
    ],
    dependencies: [
        .package(path: "../swift-foundation-extensions"),
    ],
    targets: [
        .target(name: "ProcessRunner", dependencies: [.product(name: "FoundationExtensions", package: "swift-foundation-extensions")], path: "Sources",
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "ProcessRunnerTests", dependencies: ["ProcessRunner"], path: "Tests"),
    ]
)

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ProcessRunner",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProcessRunner", targets: ["ProcessRunner"]),
    ],
    targets: [
        .target(name: "ProcessRunner", path: "Sources",
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "SubprocessTests", dependencies: ["ProcessRunner"], path: "Tests"),
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Subprocess",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "Subprocess", targets: ["Subprocess"]),
    ],
    targets: [
        .target(name: "Subprocess", path: "Sources",
                swiftSettings: [.unsafeFlags(["-strict-concurrency=complete"])]),
        .testTarget(name: "SubprocessTests", dependencies: ["Subprocess"], path: "Tests"),
    ]
)

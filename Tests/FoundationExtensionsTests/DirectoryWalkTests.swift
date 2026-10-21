//
//  DirectoryWalkTests.swift
//  FoundationExtensionsTests
//
//  `FileManager.walk`: a linked root is walked, under its own spelling.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

/// `FileManager.walk(_:includingPropertiesForKeys:options:visit:)`.
final class DirectoryWalkTests: XCTestCase {
    private var base: URL!

    override func setUpWithError() throws {
        base = FileManager.default.temporaryDirectory.appendingPathComponent("walk-\(UUID().uuidString)")
        let real = base.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: real.appendingPathComponent("sub/deep"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: real.appendingPathComponent("skipme"), withIntermediateDirectories: true)
        for path in ["a.txt", "sub/b.txt", "sub/deep/c.txt", "skipme/d.txt"] {
            try Data("x".utf8).write(to: real.appendingPathComponent(path))
        }
        try FileManager.default.createSymbolicLink(at: base.appendingPathComponent("link"), withDestinationURL: real)
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: base) }

    private func walked(_ root: URL, skipping: String? = nil) -> [String] {
        var out: [String] = []
        FileManager.default.walk(root) { url in
            out.append(url.path)
            return url.lastPathComponent == skipping ? .skipDescendants : .next
        }
        return out.sorted()
    }

    func testALinkedRootIsWalkedUnderTheLinksOwnSpelling() {
        let link = base.appendingPathComponent("link")
        let paths = walked(link)
        XCTAssertEqual(paths.count, 7, "every file and folder under the link: \(paths)")
        XCTAssertTrue(paths.allSatisfy { $0.hasPrefix(link.path + "/") }, "spelled under the link: \(paths)")
        XCTAssertTrue(paths.contains(link.path + "/sub/deep/c.txt"))
    }

    func testAPlainRootWalksAsBeforeAndTheStepsAreHonoured() {
        let real = base.appendingPathComponent("real")
        XCTAssertEqual(walked(real).count, 7)
        XCTAssertFalse(walked(real, skipping: "skipme").contains { $0.hasSuffix("d.txt") }, "skipped folder")
        XCTAssertEqual(walked(base.appendingPathComponent("link"), skipping: "skipme").count, 6, "skipping under a link too")
        var visits = 0
        FileManager.default.walk(real) { _ in
            visits += 1
            return .stop
        }
        XCTAssertEqual(visits, 1, "stop ends the walk")
        XCTAssertTrue(walked(base.appendingPathComponent("missing")).isEmpty)
    }
}

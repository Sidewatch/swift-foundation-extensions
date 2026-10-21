//
//  SameFileTests.swift
//  FoundationExtensionsTests
//
//  `URL.isSameFile(as:)`: one file under two spellings.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

/// `URL.isSameFile(as:)`.
final class SameFileTests: XCTestCase {
    func testOneFileThroughALinkIsTheSameFile() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("same-\(UUID().uuidString)")
        let real = dir.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = real.appendingPathComponent("a.swift")
        try Data("x".utf8).write(to: file)
        let link = dir.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        XCTAssertTrue(link.appendingPathComponent("a.swift").isSameFile(as: file), "through the link")
        XCTAssertTrue(file.isSameFile(as: URL(fileURLWithPath: real.path + "/./a.swift")), "the same spelling, standardized")
        XCTAssertFalse(file.isSameFile(as: real.appendingPathComponent("b.swift")))
        XCTAssertFalse(URL(fileURLWithPath: "/nowhere/a").isSameFile(as: URL(fileURLWithPath: "/nowhere/b")))
    }
}

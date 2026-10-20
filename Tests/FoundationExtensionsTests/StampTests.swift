//
//  StampTests.swift
//  FoundationExtensionsTests
//
//  `URL.contentStamp` (through links, sub-second) and `StampedCache` (hit, stamp change, bound).
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

/// `URL.contentStamp` and `StampedCache`.
final class StampTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("stamp-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: dir) }

    func testTheStampChangesWithTheContentAndIsNilForAMissingFile() throws {
        let file = dir.appendingPathComponent("a.txt")
        try "one".write(to: file, atomically: false, encoding: .utf8)
        let first = try XCTUnwrap(file.contentStamp)
        try "two!".write(to: file, atomically: false, encoding: .utf8)
        XCTAssertNotEqual(file.contentStamp, first)
        XCTAssertNil(dir.appendingPathComponent("missing").contentStamp)
    }

    func testTheStampFollowsALinkToItsTarget() throws {
        let target = dir.appendingPathComponent("target.txt")
        let link = dir.appendingPathComponent("link.txt")
        try "short".write(to: target, atomically: false, encoding: .utf8)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        XCTAssertEqual(link.contentStamp, target.contentStamp, "the link's stamp is its target's")
        let before = link.contentStamp
        try "a much longer body".write(to: target, atomically: false, encoding: .utf8)
        XCTAssertNotEqual(link.contentStamp, before, "a write to the target moves the link's stamp")
    }

    func testTheCacheHitsUntilTheStampChanges() {
        let cache = StampedCache<Int>()
        var made = 0
        XCTAssertEqual(
            cache.value(for: "k", stamp: "1") {
                made += 1; return 10
            }, 10)
        XCTAssertEqual(
            cache.value(for: "k", stamp: "1") {
                made += 1; return 99
            }, 10, "same stamp: the stored value")
        XCTAssertEqual(
            cache.value(for: "k", stamp: "2") {
                made += 1; return 20
            }, 20, "a new stamp re-derives")
        XCTAssertEqual(made, 2)
    }

    func testTheCacheStartsOverPastItsLimit() {
        let cache = StampedCache<Int>(limit: 3)
        for i in 0..<3 { _ = cache.value(for: "k\(i)", stamp: "s") { i } }
        XCTAssertEqual(cache.count, 3)
        _ = cache.value(for: "k3", stamp: "s") { 3 }
        XCTAssertEqual(cache.count, 1, "emptied, then the new entry")
    }
}

//
//  PathContainmentTests.swift
//  FoundationExtensionsTests
//
//  `isInside`, `relativePath(under:)` and friends: whole components, the folder itself, trailing
//  slashes, the root, standardization.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

/// `isInside`, `relativePath(under:)`, `URL.path(relativeTo:)` and `firstContaining`.
final class PathContainmentTests: XCTestCase {
    func testASiblingThatSharesAPrefixIsNotInside() {
        XCTAssertFalse("/a/bc".isInside("/a/b"))
        XCTAssertFalse("/a/b-docs/x".isInside("/a/b"))
        XCTAssertNil("/a/bc/x".relativePath(under: "/a/b"))
    }

    func testInsideAndRelative() {
        XCTAssertTrue("/a/b/c.swift".isInside("/a/b"))
        XCTAssertEqual("/a/b/src/c.swift".relativePath(under: "/a/b"), "src/c.swift")
    }

    func testTheFolderItselfCountsOnlyWhenAskedAndIsTheEmptyPath() {
        XCTAssertTrue("/a/b".isInside("/a/b"))
        XCTAssertFalse("/a/b".isInside("/a/b", includingSelf: false))
        XCTAssertEqual("/a/b".relativePath(under: "/a/b"), "")
    }

    func testTrailingSlashesNeverDecide() {
        XCTAssertTrue("/a/b/c".isInside("/a/b/"))
        XCTAssertTrue("/a/b/".isInside("/a/b"))
        XCTAssertEqual("/a/b/c".relativePath(under: "/a/b//"), "c")
        XCTAssertEqual("/a/b".directoryPrefix, "/a/b/")
        XCTAssertEqual("/a/b/".directoryPrefix, "/a/b/")
    }

    func testEverythingIsInsideTheRoot() {
        XCTAssertTrue("/etc/hosts".isInside("/"))
        XCTAssertEqual("/etc/hosts".relativePath(under: "/"), "etc/hosts")
        XCTAssertEqual("/".directoryPrefix, "/")
    }

    func testURLsAreStandardizedFirst() {
        let root = URL(fileURLWithPath: "/a/b")
        XCTAssertTrue(URL(fileURLWithPath: "/a/b/x/../c.swift").isInside(root))
        XCTAssertFalse(URL(fileURLWithPath: "/a/b/../bc/c.swift").isInside(root))
        XCTAssertEqual(URL(fileURLWithPath: "/a/b/./src/c.swift").path(relativeTo: root), "src/c.swift")
    }

    func testFirstContainingPicksTheFirstFolderThatHoldsIt() {
        let roots = [URL(fileURLWithPath: "/w/inner/deep"), URL(fileURLWithPath: "/w/inner"), URL(fileURLWithPath: "/w")]
        XCTAssertEqual(roots.firstContaining(URL(fileURLWithPath: "/w/inner/x"))?.path, "/w/inner")
        XCTAssertNil(roots.firstContaining(URL(fileURLWithPath: "/elsewhere/x")))
    }

    func testRelativePathOfUsesTheFirstFolderThatStrictlyHoldsIt() {
        let roots = [URL(fileURLWithPath: "/w/app"), URL(fileURLWithPath: "/w/lib")]
        XCTAssertEqual(roots.relativePath(of: URL(fileURLWithPath: "/w/lib/src/a.swift")), "src/a.swift")
        XCTAssertNil(roots.relativePath(of: URL(fileURLWithPath: "/w/app")), "the folder itself has no relative path")
        XCTAssertNil(roots.relativePath(of: URL(fileURLWithPath: "/w/apple/x")), "a prefix sibling is outside")
    }
}

//
//  StringClippingTests.swift
//  FoundationExtensionsTests
//
//  `firstLine` over every break kind, and `clipped(to:)`'s length rule.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

/// `String.firstLine` and `String.clipped(to:)`.
final class StringClippingTests: XCTestCase {
    func testTheFirstLineThatHoldsAnythingTrimmed() {
        XCTAssertEqual("  fix the build  \nand more".firstLine, "fix the build")
        XCTAssertEqual("fix it\r\nplease".firstLine, "fix it", "a CRLF break ends the line")
        XCTAssertEqual("\n   \n\tsecond\n".firstLine, "second", "blank lines are skipped")
        XCTAssertEqual("a\u{2028}b".firstLine, "a")
        XCTAssertEqual("   ".firstLine, "")
    }

    func testClippingKeepsTheLimitEllipsisIncluded() {
        XCTAssertEqual("abcdef".clipped(to: 6), "abcdef", "fits")
        XCTAssertEqual("abcdef".clipped(to: 4), "abc…")
        XCTAssertEqual("abcdef".clipped(to: 4).count, 4)
        XCTAssertEqual("a😀cdef".clipped(to: 3), "a😀…", "by characters, never splitting one")
        XCTAssertEqual("abc".clipped(to: 0), "")
    }
}

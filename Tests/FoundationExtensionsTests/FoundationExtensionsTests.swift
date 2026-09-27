//
//  FoundationExtensionsTests.swift
//  FoundationExtensionsTests
//
//  Each helper against the cases its callers depend on, including the edges that trap or
//  mislead when the idiom is spelled out by hand.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

final class FoundationExtensionsTests: XCTestCase {
    func testSafeSubscriptAnswersNilOutsideTheBounds() {
        let a = [10, 20, 30]
        XCTAssertEqual(a[safe: 0], 10)
        XCTAssertEqual(a[safe: 2], 30)
        XCTAssertNil(a[safe: 3])
        XCTAssertNil(a[safe: -1])
        XCTAssertNil([Int]()[safe: 0])
    }

    func testClampedHoldsBothBoundsAndToleratesInvertedOnes() {
        XCTAssertEqual(5.clamped(to: 0...3), 3)
        XCTAssertEqual((-2).clamped(to: 0...3), 0)
        XCTAssertEqual(2.clamped(to: 0...3), 2)
        XCTAssertEqual(5.clamped(low: 0, high: -1), -1, "inverted bounds answer high, never trap")
    }

    func testLinesSplitsCRLFTextThatCharacterSplittingCannot() {
        let crlf = "a\r\nb\r\nc"
        XCTAssertEqual(crlf.lines.count, 3)
        XCTAssertEqual(crlf.split(separator: "\n").count, 1, "the trap this helper exists to avoid")
        XCTAssertEqual("a\n".lines, ["a", ""], "a trailing newline yields a final empty line")
        XCTAssertEqual(("x\ny" as NSString).lines, ["x", "y"])
    }

    func testShellQuotedKeepsOneArgumentThroughSpacesAndQuotes() {
        XCTAssertEqual("plain".shellQuoted, "'plain'")
        XCTAssertEqual("it's here".shellQuoted, "'it'\\''s here'")
    }

    func testShellQuotedSurvivesARealShell() throws {
        let odd = "a b 'c' $HOME \"d\""
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", "printf %s " + odd.shellQuoted]
        let out = Pipe(); p.standardOutput = out
        try p.run(); p.waitUntilExit()
        XCTAssertEqual(String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8), odd)
    }

    func testTrimmedAndTrimmedSpacesDifferOnNewlines() {
        XCTAssertEqual("  a \n".trimmed, "a")
        XCTAssertEqual("  a \n".trimmedSpaces, "a \n")
        XCTAssertEqual("\t b\t"[...].trimmed, "b", "works on a Substring too")
    }

    func testCompactDurationUsesTheFewestUnits() {
        XCTAssertEqual(TimeInterval(30).compactDuration, "<1m")
        XCTAssertEqual(TimeInterval(12 * 60).compactDuration, "12m")
        XCTAssertEqual(TimeInterval(90 * 60).compactDuration, "1h 30m")
        XCTAssertEqual(TimeInterval(5 * 86_400 + 13 * 60).compactDuration, "5d 0h 13m",
                       "a day keeps its hour column even at zero")
        XCTAssertEqual(TimeInterval(5 * 86_400 + 8 * 3_600 + 13 * 60).compactDuration, "5d 8h 13m")
    }

    func testExistsAndLowercasedExtension() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fx-\(UUID()).TXT")
        XCTAssertFalse(url.exists)
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertTrue(url.exists)
        XCTAssertEqual(url.lowercasedExtension, "txt")
        XCTAssertEqual(("a/b.MD" as NSString).lowercasedExtension, "md")
    }

    func testFullRangeCountsUTF16Units() {
        XCTAssertEqual(("é🙂" as NSString).fullRange, NSRange(location: 0, length: 3))
        XCTAssertEqual(NSAttributedString(string: "abc").fullRange, NSRange(location: 0, length: 3))
    }

    func testDefaultReadsAnswerTheDefaultOnlyForAnUnwrittenKey() throws {
        let suite = "fx-tests-\(UUID())"
        let d = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { d.removePersistentDomain(forName: suite) }
        XCTAssertTrue(d.bool(forKey: "k", default: true), "unwritten reads the default")
        d.set(false, forKey: "k")
        XCTAssertFalse(d.bool(forKey: "k", default: true), "a written false is a decision")
        XCTAssertEqual(d.integer(forKey: "i", default: 7), 7)
        d.set(0, forKey: "i")
        XCTAssertEqual(d.integer(forKey: "i", default: 7), 0)
        XCTAssertEqual(d.double(forKey: "x", default: 1.5), 1.5)
        XCTAssertEqual(d.string(forKey: "s", default: "z"), "z")
    }

    func testUTF8StringDecodesValidBytesOnly() {
        XCTAssertEqual(Data("héllo".utf8).utf8String, "héllo")
        XCTAssertNil(Data([0xFF, 0xFE, 0xFD]).utf8String)
    }

    func testGroupedSeparatesThousandsInTheCurrentLocale() {
        let separator = Locale.current.groupingSeparator ?? ","
        XCTAssertEqual(174_950.grouped, "174\(separator)950")
        XCTAssertEqual(999.grouped, "999")
        XCTAssertEqual((-1_000).grouped, "-1\(separator)000")
    }

    func testByteSizeLabelsUseBinaryUnitsUpToGB() {
        XCTAssertEqual(0.byteSizeLabel, "0 B")
        XCTAssertEqual(1023.byteSizeLabel, "1023 B")
        XCTAssertEqual(2048.byteSizeLabel, "2.0 KB")
        XCTAssertEqual(1_500_000.byteSizeLabel, "1.4 MB")
        XCTAssertEqual((5 * 1024 * 1024 * 1024).byteSizeLabel, "5.0 GB")
        XCTAssertEqual((3000 * 1024 * 1024 * 1024).byteSizeLabel, "3000.0 GB", "GB is the largest unit")
    }

    @MainActor func testDebouncerRunsOnlyTheLastActionOfABurst() {
        let d = Debouncer(delay: 0.05)
        var ran: [Int] = []
        let done = expectation(description: "settled")
        for i in 1...5 { d.schedule { ran.append(i); if i == 5 { done.fulfill() } } }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(ran, [5])
    }

    @MainActor func testDebouncerCancelDropsThePendingAction() {
        let d = Debouncer(delay: 0.05)
        var ran = false
        d.schedule { ran = true }
        d.cancel()
        let settle = expectation(description: "after the delay")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { settle.fulfill() }
        wait(for: [settle], timeout: 2)
        XCTAssertFalse(ran)
    }

    func testAsyncBridgeReturnsTheValueAndNilForAThrow() {
        struct Boom: Error {}
        let answer: Int? = AsyncBridge.wait { try await Task.sleep(nanoseconds: 1_000_000); return 42 }
        XCTAssertEqual(answer, 42)
        let failed: Int? = AsyncBridge.wait { () async throws -> Int in throw Boom() }
        XCTAssertNil(failed)
    }

    func testPathTailKeepsTheLastComponents() {
        XCTAssertEqual("/Users/me/Sources/App.swift".pathTail(), "Sources/App.swift")
        XCTAssertEqual("/Users/me/Sources/App.swift".pathTail(3), "me/Sources/App.swift")
        XCTAssertEqual("/Sources/App.swift".pathTail(), "/Sources/App.swift")   // short enough: unchanged
        XCTAssertEqual("App.swift".pathTail(), "App.swift")
    }

    func testNonEmptyIsNilOnlyForTheEmptyString() {
        XCTAssertNil("".nonEmpty)
        XCTAssertEqual(" ".nonEmpty, " ", "whitespace is not empty; trim first when it should be")
        XCTAssertEqual("a".nonEmpty, "a")
    }
}

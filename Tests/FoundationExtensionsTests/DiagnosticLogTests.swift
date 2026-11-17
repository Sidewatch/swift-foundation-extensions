//
//  DiagnosticLogTests.swift
//  FoundationExtensionsTests
//
//  The diagnostics file: nothing until something fails, repeats counted, size capped.
//
//  Created by David Sherlock on 11/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

final class DiagnosticLogTests: XCTestCase {
    private var url: URL!
    private let clock = Clock()

    /// A clock the test moves.
    private final class Clock: @unchecked Sendable {
        var date = Date(timeIntervalSince1970: 1_800_000_000)
    }

    override func setUp() {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("diag-\(UUID().uuidString)/diagnostics.log")
    }
    override func tearDown() { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

    private func log(maxBytes: Int = 4096) -> DiagnosticLog {
        DiagnosticLog(url: url, maxBytes: maxBytes, repeatInterval: 300, now: { [clock] in clock.date })
    }
    private var lines: [String] {
        ((try? String(contentsOf: url, encoding: .utf8)) ?? "").split(separator: "\n").map(String.init)
    }

    func testNothingIsWrittenUntilSomethingFails() {
        let log = log()
        log.flush()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "no note: no file, not even its folder")
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
    }

    func testANoteIsOneTimestampedLine() {
        let log = log()
        log.note("open failed", "POSIX 24")
        log.flush()
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].hasSuffix("  open failed: POSIX 24"), lines[0])
        XCTAssertNotNil(lines[0].range(of: #"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}  "#, options: .regularExpression))
    }

    func testARepeatedFailureIsWrittenOncePerIntervalAndCounted() {
        let log = log()
        for _ in 0..<500 { log.note("launch failed", "git") }
        log.note("open failed", "POSIX 24")  // another kind is not held back
        log.flush()
        XCTAssertEqual(lines.count, 2, "\(lines)")
        clock.date += 299
        log.note("launch failed", "git")
        log.flush()
        XCTAssertEqual(lines.count, 2, "still inside the interval")
        clock.date += 2
        log.note("launch failed", "git")
        log.flush()
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[2].hasSuffix("launch failed: git  (500 more like the last were not written)"), lines[2])
        clock.date += 301
        log.note("launch failed", "git")
        log.flush()
        XCTAssertTrue(lines[3].hasSuffix("launch failed: git"), "nothing was left out this time: \(lines[3])")
    }

    func testTheFileNeverPassesItsLimitAndKeepsTheNewestWholeLines() {
        let log = log(maxBytes: 2000)
        for i in 0..<200 {
            clock.date += 301
            log.note("kind", "entry number \(i)")
        }
        log.flush()
        let size = (try? Data(contentsOf: url))?.count ?? 0
        XCTAssertLessThanOrEqual(size, 2000)
        XCTAssertTrue(lines.last?.hasSuffix("entry number 199") == true)
        XCTAssertFalse(lines.contains { $0.hasSuffix("entry number 0") }, "the oldest lines are the ones dropped")
        XCTAssertNotNil(
            lines[0].range(of: #"^\d{4}-\d{2}-\d{2} "#, options: .regularExpression), "the kept half starts at a whole line: \(lines[0])")
    }

    func testAMessageIsNotBuiltForANoteThatIsNotWritten() {
        let log = log()
        final class Counter: @unchecked Sendable { var built = 0 }
        let counter = Counter()
        for _ in 0..<50 {
            log.note(
                "kind",
                {
                    counter.built += 1; return "x"
                }())
        }
        log.flush()
        XCTAssertEqual(counter.built, 1)
    }
}

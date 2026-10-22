//
//  ProcessOutputLimitTests.swift
//  ProcessRunnerTests
//
//  Tests for the output limit: a tool printing without end is cut off, not read into memory.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ProcessRunner

/// Tests for the output limit: a tool printing without end is cut off, not read into memory.
final class ProcessOutputLimitTests: XCTestCase {
    /// `yes` prints forever. With a limit the caller gets exactly that many bytes back, quickly,
    /// and the result says it was cut off.
    func testAToolThatNeverStopsPrintingIsCutOffAtTheLimit() {
        let start = Date()
        let r = ProcessRunner.run("/usr/bin/yes", [], outputLimit: 100_000)
        XCTAssertTrue(r.truncated)
        XCTAssertFalse(r.timedOut, "cut off for its output, not its time")
        XCTAssertEqual(r.stdout.count, 100_000)
        XCTAssertTrue(r.outputText.hasPrefix("y\ny\n"))
        XCTAssertFalse(r.succeeded)
        XCTAssertLessThan(Date().timeIntervalSince(start), 3)
    }

    /// Output within the limit is all there and the run is not marked.
    func testOutputWithinTheLimitIsKeptWhole() {
        let r = ProcessRunner.run("/bin/echo", ["hello"], outputLimit: 6)
        XCTAssertFalse(r.truncated)
        XCTAssertEqual(r.outputText, "hello\n")
        XCTAssertTrue(r.succeeded)
    }

    /// One byte over is over.
    func testOneByteOverTheLimitIsCut() {
        let r = ProcessRunner.run("/bin/echo", ["hello"], outputLimit: 5)
        XCTAssertTrue(r.truncated)
        XCTAssertEqual(r.outputText, "hello")
    }

    /// Without a limit everything is read, as before.
    func testNoLimitReadsEverything() {
        let r = ProcessRunner.run("/bin/sh", ["-c", "yes | head -c 300000"])
        XCTAssertFalse(r.truncated)
        XCTAssertEqual(r.stdout.count, 300_000)
    }
}

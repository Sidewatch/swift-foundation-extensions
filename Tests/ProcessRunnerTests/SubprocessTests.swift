//
//  SubprocessTests.swift
//  ProcessRunnerTests
//
//  Tests for `ProcessRunner.run`: captured stdout, stderr and exit status, the trimmed-output
//  convenience, and failure reporting.
//
//  Created by David Sherlock on 8/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ProcessRunner

/// Tests for `ProcessRunner.run`: captured stdout, stderr and exit status, the trimmed-output
/// convenience, and failure reporting.
final class ProcessRunnerTests: XCTestCase {

    func testCapturesStdoutAndStatus() {
        let r = ProcessRunner.run("/bin/echo", ["hello"])
        XCTAssertTrue(r.succeeded)
        XCTAssertEqual(r.trimmedOutput, "hello")
        XCTAssertTrue(r.errorText.isEmpty)
    }

    func testCapturesStderrSeparately() {
        let r = ProcessRunner.run("/bin/sh", ["-c", "echo out; echo err >&2"])
        XCTAssertEqual(r.trimmedOutput, "out")
        XCTAssertTrue(r.errorText.contains("err"))
    }

    func testNonZeroStatusIsReportedNotSwallowed() {
        let r = ProcessRunner.run("/bin/sh", ["-c", "exit 3"])
        XCTAssertEqual(r.status, 3)
        XCTAssertFalse(r.succeeded)
        XCTAssertTrue(r.launched, "a clean non-zero exit is not a launch failure")
    }

    func testMissingToolReportsLaunchFailure() {
        let r = ProcessRunner.run("/nonexistent/tool", [])
        XCTAssertFalse(r.launched)
        XCTAssertEqual(r.status, -1)
    }

    /// The reason this type exists: >64 KB on BOTH streams must not deadlock. A runner that
    /// attaches undrained pipes to both hangs here forever.
    func testLargeOutputOnBothStreamsDoesNotDeadlock() {
        let script = "yes abcdefghij | head -20000; yes klmnopqrst | head -20000 >&2"
        let r = ProcessRunner.run("/bin/sh", ["-c", script])
        XCTAssertTrue(r.succeeded)
        XCTAssertGreaterThan(r.stdout.count, 64 * 1024)
        XCTAssertGreaterThan(r.stderr.count, 64 * 1024)
    }

    func testStdinIsWrittenAndClosed() {
        let r = ProcessRunner.run("/bin/cat", [], input: Data("piped".utf8))
        XCTAssertEqual(r.trimmedOutput, "piped")
    }

    func testWorkingDirectory() {
        let r = ProcessRunner.run("/bin/pwd", [], directory: URL(fileURLWithPath: "/tmp"))
        XCTAssertTrue(r.trimmedOutput.hasSuffix("/tmp"))
    }

    func testEnvironmentOverlayAndPathAugmentation() {
        let r = ProcessRunner.run("/bin/sh", ["-c", "echo $SW_TEST_VAR"], environment: ["SW_TEST_VAR": "set"])
        XCTAssertEqual(r.trimmedOutput, "set")
        let path = ProcessRunner.run("/bin/sh", ["-c", "echo $PATH"])
        XCTAssertTrue(path.trimmedOutput.contains("/opt/homebrew/bin"))
    }

    func testWhichFindsARealToolAndMissesAFakeOne() {
        XCTAssertNotNil(ProcessRunner.which("sh"))
        XCTAssertNil(ProcessRunner.which("definitely-not-a-real-tool-xyz"))
    }

    func testATimeoutTerminatesAWedgedToolAndSaysSo() {
        let start = Date()
        let r = ProcessRunner.run("/bin/sleep", ["5"], timeout: 0.3)
        XCTAssertTrue(r.timedOut)
        XCTAssertFalse(r.succeeded)
        XCTAssertLessThan(Date().timeIntervalSince(start), 2, "the caller was released at the timeout, not after 5 s")
    }

    func testAToolThatFinishesInTimeIsNotMarkedTimedOut() {
        let r = ProcessRunner.run("/bin/echo", ["hi"], timeout: 5)
        XCTAssertFalse(r.timedOut)
        XCTAssertEqual(r.trimmedOutput, "hi")
    }
}

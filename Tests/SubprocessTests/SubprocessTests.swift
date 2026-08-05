//
//  SubprocessTests.swift
//  Tests for Subprocess
//
//  Created by David Sherlock on 8/5/26.
//

import XCTest
@testable import Subprocess

final class SubprocessTests: XCTestCase {

    func testCapturesStdoutAndStatus() {
        let r = Subprocess.run("/bin/echo", ["hello"])
        XCTAssertTrue(r.succeeded)
        XCTAssertEqual(r.trimmedOutput, "hello")
        XCTAssertTrue(r.errorText.isEmpty)
    }

    func testCapturesStderrSeparately() {
        let r = Subprocess.run("/bin/sh", ["-c", "echo out; echo err >&2"])
        XCTAssertEqual(r.trimmedOutput, "out")
        XCTAssertTrue(r.errorText.contains("err"))
    }

    func testNonZeroStatusIsReportedNotSwallowed() {
        let r = Subprocess.run("/bin/sh", ["-c", "exit 3"])
        XCTAssertEqual(r.status, 3)
        XCTAssertFalse(r.succeeded)
        XCTAssertTrue(r.launched, "a clean non-zero exit is not a launch failure")
    }

    func testMissingToolReportsLaunchFailure() {
        let r = Subprocess.run("/nonexistent/tool", [])
        XCTAssertFalse(r.launched)
        XCTAssertEqual(r.status, -1)
    }

    /// The reason this type exists: >64 KB on BOTH streams must not deadlock. The old
    /// hand-rolled version that attached undrained pipes to both hangs here forever.
    func testLargeOutputOnBothStreamsDoesNotDeadlock() {
        let script = "yes abcdefghij | head -20000; yes klmnopqrst | head -20000 >&2"
        let r = Subprocess.run("/bin/sh", ["-c", script])
        XCTAssertTrue(r.succeeded)
        XCTAssertGreaterThan(r.stdout.count, 64 * 1024)
        XCTAssertGreaterThan(r.stderr.count, 64 * 1024)
    }

    func testStdinIsWrittenAndClosed() {
        let r = Subprocess.run("/bin/cat", [], input: Data("piped".utf8))
        XCTAssertEqual(r.trimmedOutput, "piped")
    }

    func testWorkingDirectory() {
        let r = Subprocess.run("/bin/pwd", [], directory: URL(fileURLWithPath: "/tmp"))
        XCTAssertTrue(r.trimmedOutput.hasSuffix("/tmp"))
    }

    func testEnvironmentOverlayAndPathAugmentation() {
        let r = Subprocess.run("/bin/sh", ["-c", "echo $SW_TEST_VAR"], environment: ["SW_TEST_VAR": "set"])
        XCTAssertEqual(r.trimmedOutput, "set")
        let path = Subprocess.run("/bin/sh", ["-c", "echo $PATH"])
        XCTAssertTrue(path.trimmedOutput.contains("/opt/homebrew/bin"))
    }

    func testWhichFindsARealToolAndMissesAFakeOne() {
        XCTAssertNotNil(Subprocess.which("sh"))
        XCTAssertNil(Subprocess.which("definitely-not-a-real-tool-xyz"))
    }
}

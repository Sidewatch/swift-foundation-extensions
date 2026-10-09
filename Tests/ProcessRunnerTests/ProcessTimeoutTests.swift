//
//  ProcessTimeoutTests.swift
//  ProcessRunnerTests
//
//  Tests for the timeout when the timed-out child is not the only holder of its pipes.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ProcessRunner

/// Tests for the timeout when the timed-out child is not the only holder of its pipes.
final class ProcessTimeoutTests: XCTestCase {

    /// A grandchild inherits the child's stdout and stderr, and killing the child does not close
    /// them. `Process` signals the child's whole process group on `terminate()`, so a plain
    /// grandchild dies too; one that ignores `SIGTERM` (the ignore is inherited through `exec`,
    /// as `trap "" TERM` arranges here) keeps the pipes open — here for 10 s, in life a credential
    /// helper or editor git spawned. The caller must be released at the timeout plus the kill
    /// grace, not when the grandchild finally exits.
    func testATimeoutReturnsEvenWhenAGrandchildKeepsThePipesOpen() {
        let start = Date()
        let r = ProcessRunner.run("/bin/sh", ["-c", "trap '' TERM; sleep 10 & sleep 10"], timeout: 1)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertTrue(r.timedOut)
        XCTAssertFalse(r.succeeded)
        XCTAssertLessThan(elapsed, 3, "released at timeout + grace, not when the grandchild exited")
    }

    /// Output written before the deadline is kept when the child is cut off.
    func testOutputBeforeTheTimeoutIsKept() {
        let r = ProcessRunner.run("/bin/sh", ["-c", "echo early; sleep 10"], timeout: 0.5)
        XCTAssertTrue(r.timedOut)
        XCTAssertEqual(r.trimmedOutput, "early")
    }
}

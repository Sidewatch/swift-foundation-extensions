//
//  ProcessFailureReportTests.swift
//  ProcessRunnerTests
//
//  A host hears of a run that could not launch or timed out, by the tool's name alone.
//
//  Created by David Sherlock on 11/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ProcessRunner

final class ProcessFailureReportTests: XCTestCase {
    private final class Heard: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [String] = []
        func add(_ line: String) { lock.lock(); stored.append(line); lock.unlock() }
        var lines: [String] { lock.lock(); defer { lock.unlock() }; return stored }
    }

    override func tearDown() { ProcessRunner.observeFailures(nil) }

    func testAFailedLaunchAndATimeoutAreReportedByToolNameAndASuccessIsNot() {
        let heard = Heard()
        ProcessRunner.observeFailures { tool, reason in heard.add("\(tool): \(reason)") }
        _ = ProcessRunner.run("/bin/echo", ["/secret/project/path"])
        XCTAssertEqual(heard.lines, [], "a run that worked is not a failure")
        _ = ProcessRunner.run("/nonexistent/folder/sometool", ["/secret/project/path"])
        _ = ProcessRunner.run("/bin/sleep", ["30"], timeout: 0.2)
        XCTAssertEqual(heard.lines.count, 2, "\(heard.lines)")
        XCTAssertTrue(heard.lines[0].hasPrefix("sometool: could not launch (NSCocoaErrorDomain "), heard.lines[0])
        XCTAssertEqual(heard.lines[1], "sleep: timed out after 0 s")
        XCTAssertFalse(heard.lines.joined().contains("secret"), "no argument reaches the report")
        XCTAssertFalse(heard.lines.joined().contains("/nonexistent"), "nor the tool's folder")
        ProcessRunner.observeFailures(nil)
        _ = ProcessRunner.run("/nonexistent/folder/sometool", [])
        XCTAssertEqual(heard.lines.count, 2, "nil stops the reports")
    }
}

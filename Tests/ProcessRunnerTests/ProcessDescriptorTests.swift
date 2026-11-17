//
//  ProcessDescriptorTests.swift
//  ProcessRunnerTests
//
//  A finished run gives back every descriptor it opened.
//
//  Created by David Sherlock on 11/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ProcessRunner

final class ProcessDescriptorTests: XCTestCase {

    /// Descriptors open in this process right now.
    private func openDescriptors() -> Int {
        (0..<Int32(4096)).filter { fcntl($0, F_GETFD) != -1 }.count
    }

    /// Runs `body` inside an autorelease pool, so only what a run itself keeps is counted.
    private func descriptorsLeft(after runs: Int, _ body: () -> Void) -> Int {
        let before = openDescriptors()
        for _ in 0..<runs { autoreleasepool { body() } }
        return openDescriptors() - before
    }

    /// A tool that finishes long before its timeout gives its pipes back at once, not at the
    /// deadline: a caller polling a tool with a minute's timeout once ran its app out of descriptors.
    func testAFinishedRunWithATimeoutClosesItsPipesAtOnce() {
        let left = descriptorsLeft(after: 50) {
            XCTAssertTrue(ProcessRunner.run("/bin/echo", ["hi"], timeout: 60).succeeded)
        }
        XCTAssertLessThanOrEqual(left, 2, "a finished run kept \(left) descriptors open")
    }

    /// The same without a pool around the call: the read ends close even while the `Pipe`
    /// objects are still waiting to be released.
    func testAFinishedRunClosesItsPipesEvenBeforeThePipesAreFreed() {
        let before = openDescriptors()
        var results: [ProcessRunner.Result] = []
        for _ in 0..<50 { results.append(ProcessRunner.run("/bin/echo", ["hi"], input: Data("x".utf8))) }
        XCTAssertEqual(results.filter(\.succeeded).count, 50)
        let left = openDescriptors() - before
        XCTAssertLessThanOrEqual(left, 2, "a finished run kept \(left) descriptors open")
    }
}

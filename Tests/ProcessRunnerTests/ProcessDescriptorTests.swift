//
//  ProcessDescriptorTests.swift
//  ProcessRunnerTests
//
//  A finished run gives back every descriptor and every object it made.
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

    /// A launch that fails keeps nothing: Foundation holds the termination handler of a process that
    /// never ran, and the handler once held the run's watchdog (four flags and their locks, about
    /// 600 bytes a call: 200 MB after a day of launches refused at the descriptor limit).
    func testAFailedLaunchLeavesNothingBehind() {
        func bytesInUse() -> Int {
            var stats = malloc_statistics_t()
            malloc_zone_statistics(nil, &stats)
            return stats.size_in_use
        }
        for _ in 0..<100 { autoreleasepool { _ = ProcessRunner.run("/nonexistent/tool", []) } }
        let before = bytesInUse()
        for _ in 0..<2_000 { autoreleasepool { XCTAssertFalse(ProcessRunner.run("/nonexistent/tool", []).launched) } }
        let grown = bytesInUse() - before
        XCTAssertLessThan(grown, 300_000, "2,000 failed launches kept \(grown) bytes")
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

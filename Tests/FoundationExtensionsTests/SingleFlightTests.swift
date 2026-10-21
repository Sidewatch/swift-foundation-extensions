//
//  SingleFlightTests.swift
//  FoundationExtensionsTests
//
//  One run at a time; one rerun, for the latest request.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

/// `SingleFlight`.
final class SingleFlightTests: XCTestCase {
    func testOnlyOneRunAtATimeAndARunWithNoRequestsMeanwhileEndsQuietly() {
        var latch = SingleFlight<Void>()
        XCTAssertTrue(latch.begin())
        XCTAssertTrue(latch.isRunning)
        XCTAssertFalse(latch.endWantsRerun())
        XCTAssertFalse(latch.isRunning)
        XCTAssertTrue(latch.begin(), "idle again")
    }

    func testRequestsDuringARunCostOneRerunForTheLatest() {
        var latch = SingleFlight<Int>()
        XCTAssertTrue(latch.begin(1))
        XCTAssertFalse(latch.begin(2))
        XCTAssertFalse(latch.begin(3))
        XCTAssertEqual(latch.end(), 3, "the latest request, once")
        XCTAssertTrue(latch.begin(3))
        XCTAssertNil(latch.end(), "nothing asked during the rerun")
    }

    func testAVoidLatchSaysARerunWasWanted() {
        var latch = SingleFlight<Void>()
        _ = latch.begin()
        XCTAssertFalse(latch.begin())
        XCTAssertTrue(latch.endWantsRerun())
        _ = latch.begin()
        XCTAssertFalse(latch.endWantsRerun(), "the rerun's own end is quiet")
    }
}

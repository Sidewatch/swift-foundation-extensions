//
//  RecencyFormatterTests.swift
//  FoundationExtensionsTests
//
//  A moment written for a list of recent things, in the locale's own words.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

final class RecencyFormatterTests: XCTestCase {
    /// London's calendar: "now" is Thursday 22 October 2026, 14:37 BST (13:37 UTC).
    private let london: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()
    private let now = ISO8601DateFormatter().date(from: "2026-10-22T13:37:00Z")!

    private func text(_ iso: String, _ locale: String = "en_GB") -> String {
        RecencyFormatter(calendar: london, locale: Locale(identifier: locale)).string(
            for: ISO8601DateFormatter().date(from: iso)!, now: now)
    }

    func testEarlierTodayIsHowLongAgo() {
        XCTAssertEqual(text("2026-10-22T13:36:30Z"), "now", "under a minute")
        XCTAssertEqual(text("2026-10-22T13:25:00Z"), "12 min ago")
        XCTAssertEqual(text("2026-10-22T10:37:00Z"), "3 hr ago")
        XCTAssertEqual(text("2026-10-21T23:30:00Z"), "14 hr ago", "00:30 today in London, though the 21st in UTC")
    }

    func testYesterdayAndThisWeekGiveTheDayAndTime() {
        XCTAssertEqual(text("2026-10-21T13:05:00Z"), "Yesterday at 14:05")
        XCTAssertEqual(text("2026-10-19T08:00:00Z"), "Mon 09:00")
        XCTAssertEqual(text("2026-10-15T23:30:00Z"), "Fri 00:30", "the sixth day back")
    }

    func testOlderGivesTheDateAndAnotherYearItsYear() {
        XCTAssertEqual(text("2026-10-15T22:30:00Z"), "15 Oct", "seven days back: a date")
        XCTAssertEqual(text("2026-05-27T09:00:00Z"), "27 May")
        XCTAssertEqual(text("2025-12-31T23:30:00Z"), "31 Dec 2025")
    }

    func testAMomentAheadOfNowIsNeverInTheFuture() {
        XCTAssertEqual(text("2026-10-22T15:00:00Z"), "16:00", "later today: its time")
        XCTAssertEqual(text("2026-10-30T09:00:00Z"), "30 Oct", "a later day: its date")
    }

    func testTheLocaleChoosesTheWordsAndTheClock() {
        // US English puts a narrow no-break space (U+202F) before AM and PM.
        XCTAssertEqual(text("2026-10-21T13:05:00Z", "en_US"), "Yesterday at 2:05\u{202F}PM")
        XCTAssertEqual(text("2026-10-19T08:00:00Z", "en_US"), "Mon 9:00\u{202F}AM")
        XCTAssertEqual(text("2026-10-22T10:37:00Z", "de_DE"), "vor 3 Std.")
        XCTAssertEqual(text("2026-10-21T13:05:00Z", "de_DE"), "Gestern, 14:05")
    }

    func testFullHasTheSecondsAndTheZone() {
        XCTAssertEqual(
            RecencyFormatter(calendar: london, locale: Locale(identifier: "en_GB")).full(now), "Thursday, 22 October 2026 at 14:37:00 BST")
    }
}

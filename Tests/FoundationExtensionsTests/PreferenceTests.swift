//
//  PreferenceTests.swift
//  FoundationExtensionsTests
//
//  A setting reads its default until written, persists every write, survives a relaunch, and
//  stores an enum by its raw value.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CoreGraphics
@testable import FoundationExtensions

final class PreferenceTests: XCTestCase {
    private enum Mode: Int { case off, some, all }
    private var suite = ""
    private var store: UserDefaults!

    override func setUp() {
        suite = "preference-\(UUID())"
        store = UserDefaults(suiteName: suite)
    }

    override func tearDown() { store.removePersistentDomain(forName: suite) }

    func testAnUnwrittenSettingReadsItsDefaultNotZero() {
        let on = Preference("flag", default: true, store: store)
        XCTAssertTrue(on.wrappedValue)
        XCTAssertNil(store.object(forKey: "flag"), "reading writes nothing")
    }

    func testAWriteIsKeptAndPersisted() {
        var width = Preference("width", default: CGFloat(100), store: store)
        width.wrappedValue = 140
        XCTAssertEqual(width.wrappedValue, 140)
        XCTAssertEqual(Preference("width", default: CGFloat(100), store: store).wrappedValue, 140,
                       "a new declaration — a relaunch — reads what was stored")
    }

    func testAFalseWriteIsADecision() {
        var flag = Preference("flag", default: true, store: store)
        flag.wrappedValue = false
        XCTAssertFalse(Preference("flag", default: true, store: store).wrappedValue)
    }

    func testAnEnumIsStoredByItsRawValue() {
        var mode = Preference("mode", default: Mode.some, store: store)
        mode.wrappedValue = .all
        XCTAssertEqual(store.integer(forKey: "mode"), 2)
        XCTAssertEqual(Preference("mode", default: Mode.some, store: store).wrappedValue, .all)
        store.set(99, forKey: "mode")
        XCTAssertEqual(Preference("mode", default: Mode.some, store: store).wrappedValue, .some,
                       "a raw value that names no case reads as the default")
    }

    func testResetForgetsTheStoredValue() {
        var name = Preference("name", default: "a", store: store)
        name.wrappedValue = "b"
        name.reset()
        XCTAssertEqual(name.wrappedValue, "a")
        XCTAssertNil(store.object(forKey: "name"))
    }

    func testTheProjectionExposesKeyAndDefault() {
        let p = Preference("k", default: 3, store: store)
        XCTAssertEqual(p.projectedValue.key, "k")
        XCTAssertEqual(p.projectedValue.defaultValue, 3)
    }
}

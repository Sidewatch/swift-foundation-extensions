//
//  PreferenceDefaultsTests.swift
//  FoundationExtensionsTests
//
//  `PreferenceDefaults`: a declared key answers whether a stored value is its default — unwritten,
//  written equal, an enum by raw value, an optional nil — and an undeclared key answers nothing.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

final class PreferenceDefaultsTests: XCTestCase {
    private enum Mode: Int { case off, some, all }

    func testADeclaredKeyKnowsItsDefault() {
        let store = UserDefaults(suiteName: "preference-defaults-\(UUID())")!
        _ = Preference("defaults.width", default: 140, store: store)
        _ = Preference("defaults.mode", default: Mode.some, store: store)
        _ = Preference<String?>("defaults.name", default: nil, store: store)
        XCTAssertEqual(PreferenceDefaults.isDefault(nil, forKey: "defaults.width"), true, "unwritten is the default")
        XCTAssertEqual(PreferenceDefaults.isDefault(140, forKey: "defaults.width"), true, "written equal is the default")
        XCTAssertEqual(PreferenceDefaults.isDefault(160, forKey: "defaults.width"), false)
        XCTAssertEqual(PreferenceDefaults.isDefault(Mode.some.rawValue, forKey: "defaults.mode"), true, "an enum by its raw value")
        XCTAssertEqual(PreferenceDefaults.isDefault(Mode.all.rawValue, forKey: "defaults.mode"), false)
        XCTAssertEqual(PreferenceDefaults.isDefault(nil, forKey: "defaults.name"), true)
        XCTAssertEqual(PreferenceDefaults.isDefault("Ada", forKey: "defaults.name"), false, "anything stored is not a nil default")
        XCTAssertTrue(PreferenceDefaults.isDeclared("defaults.name"))
    }

    func testAnUndeclaredKeyAnswersNothing() {
        XCTAssertNil(PreferenceDefaults.isDefault(1, forKey: "defaults.never-declared"))
        XCTAssertFalse(PreferenceDefaults.isDeclared("defaults.never-declared"))
    }
}

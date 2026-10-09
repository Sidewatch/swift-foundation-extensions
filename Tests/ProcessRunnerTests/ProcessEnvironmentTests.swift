//
//  ProcessEnvironmentTests.swift
//  ProcessRunnerTests
//
//  Tests for the child's environment: inherited variables a caller removes, and the layering
//  order between `removing` and `environment`.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ProcessRunner

/// Tests for the child's environment: inherited variables a caller removes, and the layering
/// order between `removing` and `environment`.
final class ProcessEnvironmentTests: XCTestCase {

    private let variable = "SW_PROCESSRUNNER_REMOVED_VAR"

    override func setUp() {
        super.setUp()
        setenv(variable, "inherited", 1)
    }

    override func tearDown() {
        unsetenv(variable)
        super.tearDown()
    }

    private func childSees() -> String {
        ProcessRunner.run("/bin/sh", ["-c", "echo ${\(variable)-unset}"]).trimmedOutput
    }

    /// A variable the launching shell exported (a stray `GIT_DIR`) reaches every child unless the
    /// caller can strip it; `removing` is that strip.
    func testRemovingStripsAnInheritedVariable() {
        XCTAssertEqual(childSees(), "inherited", "the fixture must be inherited to begin with")
        let r = ProcessRunner.run("/bin/sh", ["-c", "echo ${\(variable)-unset}"], removing: [variable])
        XCTAssertEqual(r.trimmedOutput, "unset")
    }

    /// `environment` is layered after `removing`, so naming a variable in both sets it.
    func testEnvironmentWinsOverRemoving() {
        let r = ProcessRunner.run(
            "/bin/sh", ["-c", "echo ${\(variable)-unset}"],
            environment: [variable: "explicit"], removing: [variable])
        XCTAssertEqual(r.trimmedOutput, "explicit")
    }
}

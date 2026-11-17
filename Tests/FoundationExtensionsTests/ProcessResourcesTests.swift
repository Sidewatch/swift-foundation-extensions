//
//  ProcessResourcesTests.swift
//  FoundationExtensionsTests
//
//  The process's own descriptor count and memory.
//
//  Created by David Sherlock on 11/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import FoundationExtensions

final class ProcessResourcesTests: XCTestCase {
    func testAnOpenedFileIsCountedAndAClosedOneIsNot() {
        let before = ProcessResources.current
        let descriptors = (0..<5).map { _ in open("/dev/null", O_RDONLY) }
        XCTAssertEqual(ProcessResources.current.openDescriptors, before.openDescriptors + 5)
        descriptors.forEach { close($0) }
        XCTAssertEqual(ProcessResources.current.openDescriptors, before.openDescriptors)
    }

    func testTheLimitAndTheFootprintAreRead() {
        let now = ProcessResources.current
        var limit = rlimit()
        getrlimit(RLIMIT_NOFILE, &limit)
        XCTAssertEqual(now.descriptorLimit, Int(min(limit.rlim_cur, 65_536)))
        XCTAssertGreaterThan(now.footprintMegabytes, 1)
        XCTAssertLessThan(now.openDescriptors, now.descriptorLimit)
        XCTAssertEqual(
            ProcessResources(openDescriptors: 89, descriptorLimit: 2560, footprintMegabytes: 440).summary, "fds 89/2560, 440 MB")
    }
}

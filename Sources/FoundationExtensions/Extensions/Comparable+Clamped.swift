//
//  Comparable+Clamped.swift
//  FoundationExtensions
//
//  Clamping a value into bounds.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Comparable {
    /// `self` clamped into `range`.
    ///
    /// - Precondition: `range` is not inverted. For bounds that can invert at runtime
    ///   (`0...(count - 1)` when `count == 0`), use ``clamped(low:high:)``.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }

    /// `self` clamped into `[low, high]`, answering `high` when the bounds are inverted —
    /// exactly `min(max(self, low), high)`.
    func clamped(low: Self, high: Self) -> Self {
        min(max(self, low), high)
    }
}

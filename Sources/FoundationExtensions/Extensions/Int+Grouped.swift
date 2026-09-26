//
//  Int+Grouped.swift
//  FoundationExtensions
//
//  A count with locale-aware thousands separators.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Int {
    /// The number with the locale's thousands separators — `174950` → `174,950` in English,
    /// `174.950` in German. Every user-facing count goes through this: above four figures a
    /// bare integer is a smear you have to count digits in.
    var grouped: String {
        Self.groupingFormatter.string(from: NSNumber(value: self)) ?? String(self)
    }

    private static let groupingFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
}

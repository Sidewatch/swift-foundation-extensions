//
//  TimeInterval+Compact.swift
//  FoundationExtensions
//
//  A duration in the fewest words.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension TimeInterval {
    /// A duration in the fewest words that still say how long: `5d 8h 13m`, `1h 30m`, `12m`,
    /// `<1m`.
    var compactDuration: String {
        let total = Int(self.rounded())
        guard total >= 60 else { return "<1m" }
        let days = total / 86_400, hours = total % 86_400 / 3_600, minutes = total % 3_600 / 60
        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if days > 0 || hours > 0 { parts.append("\(hours)h") }
        parts.append("\(minutes)m")
        return parts.joined(separator: " ")
    }
}

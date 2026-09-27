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
        guard total >= 60 else {
            let oneMinute = Duration.seconds(60).formatted(.units(allowed: [.minutes], width: .narrow))
            return String(
                localized: "<\(oneMinute)", bundle: .module,
                comment: "A duration under one minute; the value is one minute in the locale's short form, e.g. 1m")
        }
        let days = total / 86_400, hours = total % 86_400 / 3_600
        // Whole minutes only, so the formatter never rounds seconds up into the next minute.
        let whole = Duration.seconds(total - total % 60)
        // The locale's narrow units ("5d 8h 13m" in English); a day keeps its hour column and
        // an hour its minute column even at zero.
        let allowed: Set<Duration.UnitsFormatStyle.Unit> =
            days > 0 ? [.days, .hours, .minutes] : hours > 0 ? [.hours, .minutes] : [.minutes]
        return whole.formatted(.units(allowed: allowed, width: .narrow, zeroValueUnits: .show(length: 1)))
    }
}

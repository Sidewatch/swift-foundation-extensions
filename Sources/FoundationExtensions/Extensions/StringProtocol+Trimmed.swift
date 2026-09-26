//
//  StringProtocol+Trimmed.swift
//  FoundationExtensions
//
//  Text with its surrounding whitespace removed.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension StringProtocol {
    /// The text without leading or trailing whitespace and newlines.
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The text without leading or trailing spaces and tabs; newlines stay.
    var trimmedSpaces: String { trimmingCharacters(in: .whitespaces) }
}

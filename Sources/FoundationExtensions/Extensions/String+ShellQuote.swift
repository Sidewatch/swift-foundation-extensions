//
//  String+ShellQuote.swift
//  FoundationExtensions
//
//  Quoting text as one POSIX shell argument.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension String {
    /// The text single-quoted for `sh`, with embedded single quotes escaped as `'\''`, so a
    /// path with spaces or apostrophes stays one argument.
    var shellQuoted: String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

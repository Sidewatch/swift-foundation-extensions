//
//  String+Lines.swift
//  FoundationExtensions
//
//  Text split into lines.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension String {
    /// The text split on `\n`; a trailing newline yields a final empty line.
    ///
    /// Splits on UTF-16 units, so a CRLF file divides into lines that keep their `\r` —
    /// unlike `split(separator: "\n")`, where `"\r\n"` is one `Character` and never matches.
    var lines: [String] { components(separatedBy: "\n") }
}

public extension NSString {
    /// The text split on `\n`.
    var lines: [String] { components(separatedBy: "\n") }
}

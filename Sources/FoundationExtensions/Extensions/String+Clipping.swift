//
//  String+Clipping.swift
//  FoundationExtensions
//
//  A text's first line, and a text cut to fit a label with an ellipsis.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension String {
    /// The first line that holds anything, trimmed of surrounding whitespace — every line break kind
    /// ends a line (`"\r\n"` is one `Character`, so a split on `"\n"` alone would keep a CRLF text whole).
    /// Empty when the text is blank.
    var firstLine: String {
        split(whereSeparator: \.isNewline).lazy.map { $0.trimmingCharacters(in: .whitespaces) }.first { !$0.isEmpty } ?? ""
    }

    /// This text cut to at most `limit` characters, the last one an ellipsis when anything was cut —
    /// for a tab title, a menu item, a notification. A `limit` under 1 gives "".
    func clipped(to limit: Int) -> String {
        guard count > limit else { return self }
        guard limit > 0 else { return "" }
        return String(prefix(limit - 1)) + "…"
    }
}

//
//  NSString+BoundedLineRange.swift
//  FoundationExtensions
//
//  The lines around a range, never reaching further than a set distance past it.
//
//  Created by David Sherlock on 10/10/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension NSString {
    /// `lineRange(for:)`, but each end reaches at most `reach` characters past `range`: a line
    /// longer than that (a minified bundle, a source map's one 4 MB line) is cut there instead of
    /// widening a few visible characters into the whole line. Ordinary lines come back whole.
    /// `range` is clamped to the string first.
    func lineRange(for range: NSRange, reach: Int) -> NSRange {
        guard length > 0 else { return NSRange(location: 0, length: 0) }
        let location = min(max(range.location, 0), length)
        let end = min(location + max(range.length, 0), length)
        // Searched within the reach only: asking for the whole line first walks all of it.
        // The LF of a CR LF belongs to the line the CR ends.
        let inPair = location > 0 && location < length && character(at: location) == 0x0A && character(at: location - 1) == 0x0D
        let from = inPair ? location - 1 : location
        let back = max(0, from - reach)
        let before = rangeOfCharacter(from: .newlines, options: .backwards, range: NSRange(location: back, length: from - back))
        let start = before.location == NSNotFound ? back : NSMaxRange(before)
        // The line holding the range's last character (a range ending on a break ends there).
        let last = range.length > 0 ? end - 1 : end
        let limit = min(length, end + reach)
        guard last < limit else { return NSRange(location: start, length: limit - start) }
        let after = rangeOfCharacter(from: .newlines, range: NSRange(location: last, length: limit - last))
        guard after.location != NSNotFound else { return NSRange(location: start, length: limit - start) }
        var stop = NSMaxRange(after)
        // CR LF is one break.
        if character(at: after.location) == 0x0D, stop < length, character(at: stop) == 0x0A { stop += 1 }
        return NSRange(location: start, length: stop - start)
    }
}

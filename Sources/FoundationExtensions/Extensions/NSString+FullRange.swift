//
//  NSString+FullRange.swift
//  FoundationExtensions
//
//  The range covering a whole string.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension NSString {
    /// `NSRange(location: 0, length: length)`.
    var fullRange: NSRange { NSRange(location: 0, length: length) }
}

public extension NSAttributedString {
    /// `NSRange(location: 0, length: length)`.
    var fullRange: NSRange { NSRange(location: 0, length: length) }
}

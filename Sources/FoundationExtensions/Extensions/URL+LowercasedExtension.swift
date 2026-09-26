//
//  URL+LowercasedExtension.swift
//  FoundationExtensions
//
//  A path's extension, lower-cased.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension URL {
    /// `pathExtension.lowercased()`.
    var lowercasedExtension: String { pathExtension.lowercased() }
}

public extension NSString {
    /// `pathExtension.lowercased()`.
    var lowercasedExtension: String { pathExtension.lowercased() }
}

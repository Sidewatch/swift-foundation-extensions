//
//  Data+UTF8.swift
//  FoundationExtensions
//
//  Bytes read as UTF-8 text.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Data {
    /// The bytes as UTF-8 text, or nil when they are not valid UTF-8.
    var utf8String: String? { String(data: self, encoding: .utf8) }
}

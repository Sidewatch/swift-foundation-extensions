//
//  String+NonEmpty.swift
//  FoundationExtensions
//
//  A string, or nil when it is empty.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension String {
    /// This string, or nil when it is empty — for `a.nonEmpty ?? fallback`.
    var nonEmpty: String? { isEmpty ? nil : self }
}

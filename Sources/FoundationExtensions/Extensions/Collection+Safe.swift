//
//  Collection+Safe.swift
//  FoundationExtensions
//
//  A bounds-checked subscript.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Collection {
    /// The element at `index`, or nil when it is out of range, so a stale index from an
    /// asynchronous refresh reads as nothing instead of trapping.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

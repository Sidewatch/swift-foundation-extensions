//
//  Int+ByteSize.swift
//  FoundationExtensions
//
//  A byte count as a short size label.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Int {
    /// The byte count as a size label in binary units (1024) up to GB, one decimal above
    /// bytes: `500` → `500 B`, `2048` → `2.0 KB`.
    var byteSizeLabel: String {
        let units = ["B", "KB", "MB", "GB"]
        var v = Double(self), i = 0
        while v >= 1024, i < units.count - 1 { v /= 1024; i += 1 }
        return i == 0 ? "\(self) B" : String(format: "%.1f %@", v, units[i])
    }
}

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
        var v = Double(self), i = 0
        while v >= 1024, i < 3 { v /= 1024; i += 1 }
        // The number in the locale's digits and decimal mark, ungrouped as before; the unit
        // wording (and its order) is the translation's.
        let n = i == 0 ? self.formatted(.number.grouping(.never))
                       : v.formatted(.number.precision(.fractionLength(1)).grouping(.never))
        switch i {
        case 0:  return String(localized: "\(n) B", bundle: .module, comment: "A size in bytes, e.g. 500 B")
        case 1:  return String(localized: "\(n) KB", bundle: .module, comment: "A size in kilobytes, e.g. 2.0 KB")
        case 2:  return String(localized: "\(n) MB", bundle: .module, comment: "A size in megabytes, e.g. 1.4 MB")
        default: return String(localized: "\(n) GB", bundle: .module, comment: "A size in gigabytes, e.g. 5.0 GB")
        }
    }
}

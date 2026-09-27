//
//  String+PathTail.swift
//  FoundationExtensions
//
//  A path shortened to its last few components.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension String {
    /// The last `count` components of this `/`-separated path (`Sources/App.swift` for
    /// `/Users/me/Sources/App.swift`), or the path itself when it has no more than that.
    func pathTail(_ count: Int = 2) -> String {
        let parts = split(separator: "/")
        return parts.count <= count ? self : parts.suffix(count).joined(separator: "/")
    }
}

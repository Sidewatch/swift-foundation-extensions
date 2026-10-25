//
//  PreferenceDefaults.swift
//  FoundationExtensions
//
//  The default every declared `Preference` reads as, by key, for a check that a key is back at it.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The default each `Preference` declaration reads as, recorded by key as the declaration is
/// created (a static setting is created on its first use). It answers whether a stored value is
/// the default, which is what a "Restore Defaults" check needs without a list of keys of its own.
public enum PreferenceDefaults {
    private static let lock = NSLock()
    /// Each declared key's default, as it would be stored; nil for a default of nil.
    nonisolated(unsafe) private static var defaults: [String: Any?] = [:]

    /// Records `key`'s default, encoded as it is stored. A later declaration of the same key wins.
    static func record(_ key: String, default encoded: Any) {
        // An optional default of nil arrives boxed; it is kept as "no value".
        let value: Any? =
            Mirror(reflecting: encoded).displayStyle == .optional ? Mirror(reflecting: encoded).children.first?.value : encoded
        lock.withLock { defaults[key] = .some(value) }
    }

    /// Whether `key` has been declared as a `Preference` in this run.
    public static func isDeclared(_ key: String) -> Bool { lock.withLock { defaults[key] != nil } }

    /// Whether `stored` (the store's object for `key`, nil when unwritten) reads as the declared
    /// default: unwritten, or equal to it. Nil when `key` was never declared.
    public static func isDefault(_ stored: Any?, forKey key: String) -> Bool? {
        guard let declared = lock.withLock({ defaults[key] }) else { return nil }
        guard let stored else { return true }
        guard let declared else { return false }
        return (stored as AnyObject).isEqual(declared as AnyObject)
    }
}

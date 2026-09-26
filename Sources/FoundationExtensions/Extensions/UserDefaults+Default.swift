//
//  UserDefaults+Default.swift
//  FoundationExtensions
//
//  A preference read with an explicit default.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension UserDefaults {
    /// The stored Bool, or `defaultValue` when the key was never written. `bool(forKey:)`
    /// alone reads an unset key as `false`, which makes every default-on toggle default off.
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        (object(forKey: key) as? Bool) ?? defaultValue
    }

    /// The stored Int, or `defaultValue` when the key was never written.
    func integer(forKey key: String, default defaultValue: Int) -> Int {
        (object(forKey: key) as? Int) ?? defaultValue
    }

    /// The stored Double, or `defaultValue` when the key was never written.
    func double(forKey key: String, default defaultValue: Double) -> Double {
        (object(forKey: key) as? Double) ?? defaultValue
    }

    /// The stored String, or `defaultValue` when the key was never written.
    func string(forKey key: String, default defaultValue: String) -> String {
        (object(forKey: key) as? String) ?? defaultValue
    }
}

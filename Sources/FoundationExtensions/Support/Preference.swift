//
//  Preference.swift
//  FoundationExtensions
//
//  A setting stored in user defaults, declared in one line.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A value persisted in user defaults under `key`, falling back to a default until it is written:
///
///     @Preference("WordWrap", default: false) static var wordWrap: Bool
///
/// The value is read once and kept in memory, so a setting consulted while drawing stays cheap;
/// every assignment writes through. An unwritten key reads as `defaultValue`, never as the
/// type's zero (which is how a default-on toggle turns off).
@propertyWrapper
public struct Preference<Value> {
    /// The user-defaults key.
    public let key: String
    /// What the setting reads as until it is written.
    public let defaultValue: Value
    private let store: UserDefaults
    private let encode: (Value) -> Any
    private var value: Value

    /// The current value; assigning it persists it.
    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            let encoded = encode(newValue)
            // An optional setting assigned nil forgets the key rather than storing a nil box,
            // which user defaults cannot hold.
            if let optional = Mirror(reflecting: encoded).displayStyle, optional == .optional,
               Mirror(reflecting: encoded).children.isEmpty {
                store.removeObject(forKey: key)
            } else {
                store.set(encoded, forKey: key)
            }
        }
    }

    /// The declaration itself, for its key and default — and settable, so `$setting.reset()`
    /// works on a static setting.
    public var projectedValue: Preference<Value> {
        get { self }
        set { self = newValue }
    }

    /// A setting of a property-list type (Bool, Int, Double, CGFloat, String, Data, Date, and
    /// arrays or dictionaries of those), or an optional one, where nil means "not set".
    public init(_ key: String, default defaultValue: Value, store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
        encode = { $0 }
        value = (store.object(forKey: key) as? Value) ?? defaultValue
    }

    /// A setting stored as its raw value, such as an enum of modes. A stored raw value that no
    /// longer names a case reads as the default.
    public init(_ key: String, default defaultValue: Value, store: UserDefaults = .standard)
    where Value: RawRepresentable {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
        encode = { $0.rawValue }
        value = (store.object(forKey: key) as? Value.RawValue).flatMap(Value.init(rawValue:)) ?? defaultValue
    }

    /// Whether the person (or the app) has written this setting, as opposed to reading its default.
    public var isWritten: Bool { store.object(forKey: key) != nil }

    /// Forgets the stored value, so the setting reads as its default again.
    public mutating func reset() {
        value = defaultValue
        store.removeObject(forKey: key)
    }
}

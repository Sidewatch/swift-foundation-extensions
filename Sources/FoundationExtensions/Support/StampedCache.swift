//
//  StampedCache.swift
//  FoundationExtensions
//
//  A bounded, thread-safe memo keyed by an item and the stamp it was computed under.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A bounded, thread-safe memo: a value per key, kept while the key's stamp is unchanged — for
/// "re-derive this file's facts only when the file (or HEAD, or the change kind) moved". The stamp
/// is any string the caller builds (`URL.contentStamp` plus whatever else the value depends on).
///
/// `value(for:stamp:make:)` runs `make` OUTSIDE the lock, so two threads asking for the same new key
/// may both compute it; the last write wins. That is the right trade for slow derivations (a git
/// process each) that are idempotent. When the cache passes `limit` entries it is emptied, which keeps
/// a long session across many branches from growing it without bound.
public final class StampedCache<Value>: @unchecked Sendable {
    private var entries: [String: (stamp: String, value: Value)] = [:]
    private let lock = NSLock()
    /// The entry count past which the cache starts over.
    public let limit: Int

    /// An empty cache that holds up to `limit` entries.
    public init(limit: Int = 2_000) { self.limit = limit }

    /// The value stored for `key` under `stamp`, or — on a miss or a changed stamp — `make()`'s
    /// result, stored for next time.
    public func value(for key: String, stamp: String, make: () -> Value) -> Value {
        lock.lock()
        if let hit = entries[key], hit.stamp == stamp {
            lock.unlock()
            return hit.value
        }
        lock.unlock()
        let value = make()
        lock.lock()
        if entries.count >= limit { entries.removeAll() }
        entries[key] = (stamp, value)
        lock.unlock()
        return value
    }

    /// How many entries are held now.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return entries.count
    }
}

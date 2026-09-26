//
//  Debouncer.swift
//  FoundationExtensions
//
//  Run the last of a burst of actions, once, after a quiet delay.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Runs the last of a burst of actions once the burst has been quiet for a delay — the
/// cancel-then-reschedule idiom every hover, completion and reload path would otherwise spell out.
@MainActor
public final class Debouncer {
    private var pending: DispatchWorkItem?

    /// The delay `schedule(_:)` uses when none is given.
    public let delay: TimeInterval

    /// A debouncer that waits `delay` seconds by default.
    public init(delay: TimeInterval) { self.delay = delay }

    /// Runs `action` on the main queue after the delay, dropping any action still pending.
    public func schedule(after delay: TimeInterval? = nil, _ action: @escaping @MainActor () -> Void) {
        pending?.cancel()
        let item = DispatchWorkItem { MainActor.assumeIsolated { action() } }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + (delay ?? self.delay), execute: item)
    }

    /// Drops the pending action, if any.
    public func cancel() {
        pending?.cancel()
        pending = nil
    }
}

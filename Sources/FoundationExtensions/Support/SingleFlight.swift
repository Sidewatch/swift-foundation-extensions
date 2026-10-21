//
//  SingleFlight.swift
//  FoundationExtensions
//
//  One run at a time, and one more after it when something asked meanwhile.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A single-flight latch with a rerun: one run of a slow refresh at a time, and when refreshes are
/// asked for while it runs, exactly one more afterwards — for the LATEST request, however many came.
/// A storm of file-change events then costs one extra run, never a stack of them.
///
/// ```swift
/// guard latch.begin(roots) else { return }      // busy: `roots` kept for later
/// work { if let next = latch.end() { refresh(next) } }
/// ```
public struct SingleFlight<Request> {
    /// Whether a run is under way (between ``begin(_:)`` returning true and ``end()``).
    public private(set) var isRunning = false
    /// The latest request asked for during the current run.
    private var pending: Request?

    /// An idle latch.
    public init() {}

    /// Starts a run: true when the caller should run now. While one is running, keeps `request` for
    /// afterwards (replacing any kept earlier) and returns false.
    public mutating func begin(_ request: Request) -> Bool {
        guard !isRunning else {
            pending = request
            return false
        }
        isRunning = true
        return true
    }

    /// Ends the run and hands back the request kept during it, if any: the caller runs once more for it.
    public mutating func end() -> Request? {
        isRunning = false
        defer { pending = nil }
        return pending
    }
}

public extension SingleFlight where Request == Void {
    /// Starts a run with nothing to remember: true when the caller should run now.
    mutating func begin() -> Bool { begin(()) }

    /// Ends the run: true when another was asked for during it.
    mutating func endWantsRerun() -> Bool { end() != nil }
}

//
//  AsyncBridge.swift
//  FoundationExtensions
//
//  Waiting on an async operation from synchronous code off the main thread.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Runs an async operation to completion from synchronous code: the operation is detached and
/// the caller waits on a semaphore. For async-only APIs (AVFoundation's loads) called from a
/// worker thread. Never call it on the main thread, and create non-Sendable objects INSIDE the
/// operation — they cannot cross in.
public enum AsyncBridge {
    /// The operation's result, or nil when it threw.
    public static func wait<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) -> T? {
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result: T?
        Task.detached(priority: .userInitiated) {
            result = try? await operation()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
}

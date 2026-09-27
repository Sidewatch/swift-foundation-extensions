//
//  ProcessRunner.swift
//  ProcessRunner
//
//  Run a command-line tool and collect its output, without the deadlock.
//
//  Created by David Sherlock on 8/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import FoundationExtensions

/// Runs external tools and returns what they printed.
///
/// A `Pipe` that is never drained deadlocks once the child writes more than the pipe buffer
/// (~64 KB): the child blocks in `write(2)` while the parent blocks in `waitUntilExit()`.
/// Draining both streams concurrently, always, is the only shape that cannot deadlock, so it is
/// the only shape this type offers.
public enum ProcessRunner {

    /// What a finished process produced.
    public struct Result: Equatable, Sendable {
        /// Exit status, or -1 when the tool could not be launched at all.
        public let status: Int32
        /// Everything the process wrote to standard output.
        public let stdout: Data
        /// Everything the process wrote to standard error.
        public let stderr: Data
        /// True when the process outlived its `timeout` and was terminated.
        public var timedOut = false

        /// `stdout` as UTF-8 with surrounding whitespace trimmed — the common case for
        /// tools whose output is one line (`which`, `git rev-parse`).
        public var trimmedOutput: String {
            stdout.utf8String?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        /// `stdout` as UTF-8, untrimmed; empty when it is not valid UTF-8.
        public var outputText: String { stdout.utf8String ?? "" }
        /// `stderr` as UTF-8, untrimmed; empty when it is not valid UTF-8.
        public var errorText: String { stderr.utf8String ?? "" }
        /// False when the tool could not be started at all (`status == -1`).
        public var launched: Bool { status != -1 }
        /// True when the process exited with status 0.
        public var succeeded: Bool { status == 0 }
    }

    /// Directories appended to `PATH` for GUI-launched apps.
    ///
    /// An app started from Finder inherits a minimal `PATH` that contains neither Homebrew
    /// nor `/usr/local` — so tools the user certainly has installed are simply not found.
    /// Every caller here needs the same augmentation, so it is the default rather than a
    /// thing each one remembers.
    public static let guiPathSupplement = "/opt/homebrew/bin:/usr/local/bin:/usr/bin"

    /// Run `executable` with `args` and collect both streams.
    ///
    /// - Parameters:
    ///   - executable: Absolute path to the tool.
    ///   - args: Arguments, not shell-parsed — no quoting rules, no injection surface.
    ///   - directory: Working directory, or nil to inherit.
    ///   - input: Written to the child's stdin and closed; nil leaves stdin inherited.
    ///   - environment: Extra variables layered over the process environment.
    ///   - augmentPATH: Append ``guiPathSupplement`` to `PATH` (default true).
    ///   - timeout: Seconds after which a still-running process is terminated, so a wedged
    ///     tool cannot hold the caller; nil waits for as long as it takes.
    /// - Returns: The result; `status == -1` when the tool could not be launched, and
    ///   `timedOut` set when it was terminated for running past `timeout`.
    public static func run(
        _ executable: String,
        _ args: [String],
        directory: URL? = nil,
        input: Data? = nil,
        environment: [String: String] = [:],
        augmentPATH: Bool = true,
        timeout: TimeInterval? = nil
    ) -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        if let directory { process.currentDirectoryURL = directory }

        var env = ProcessInfo.processInfo.environment
        if augmentPATH {
            env["PATH"] = env["PATH"].map { "\($0):\(guiPathSupplement)" } ?? guiPathSupplement
        }
        for (k, v) in environment { env[k] = v }
        process.environment = env

        let outPipe = Pipe(), errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        let inPipe: Pipe? = input == nil ? nil : Pipe()
        if let inPipe { process.standardInput = inPipe }

        do { try process.run() } catch { return Result(status: -1, stdout: Data(), stderr: Data()) }

        if let inPipe, let input {
            // Write on a background hop: a child that never reads stdin would otherwise
            // block this thread before draining of its output starts.
            DispatchQueue.global(qos: .utility).async {
                inPipe.fileHandleForWriting.write(input)
                try? inPipe.fileHandleForWriting.close()
            }
        }

        let expiry = TimeoutFlag()
        if let timeout {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { expiry.set(); process.terminate() }
            }
        }

        // Drain BOTH streams concurrently, then wait: this ordering is the whole point of the
        // type. The reads land in a locked box rather than captured `var`s, so strict
        // concurrency can check it.
        let sink = StreamSink()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            sink.setOut(outPipe.fileHandleForReading.readDataToEndOfFile())
            group.leave()
        }
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            sink.setErr(errPipe.fileHandleForReading.readDataToEndOfFile())
            group.leave()
        }
        group.wait()
        process.waitUntilExit()
        return Result(
            status: process.terminationStatus, stdout: sink.out, stderr: sink.err,
            timedOut: expiry.value)
    }

    /// Records, across threads, that the timeout fired.
    private final class TimeoutFlag: @unchecked Sendable {
        private let lock = NSLock()
        private var fired = false
        func set() { lock.lock(); fired = true; lock.unlock() }
        var value: Bool { lock.lock(); defer { lock.unlock() }; return fired }
    }

    /// Collects the two drained streams from the queues that read them.
    ///
    /// Locked even though the `DispatchGroup` join already orders the writes before the read, so
    /// it stays correct if the drain logic is reshaped; the lock is uncontended and costs nothing.
    private final class StreamSink: @unchecked Sendable {
        private let lock = NSLock()
        private var outStorage = Data()
        private var errStorage = Data()

        func setOut(_ d: Data) { lock.lock(); outStorage = d; lock.unlock() }
        func setErr(_ d: Data) { lock.lock(); errStorage = d; lock.unlock() }
        var out: Data { lock.lock(); defer { lock.unlock() }; return outStorage }
        var err: Data { lock.lock(); defer { lock.unlock() }; return errStorage }
    }

    /// Absolute path of `tool` on `PATH`, or nil when it is not installed.
    public static func which(_ tool: String) -> String? {
        let result = run("/usr/bin/which", [tool])
        guard result.succeeded else { return nil }
        let path = result.trimmedOutput
        return path.isEmpty ? nil : path
    }
}

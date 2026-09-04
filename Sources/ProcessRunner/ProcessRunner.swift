//
//  ProcessRunner.swift
//  ProcessRunner
//
//  Run a command-line tool and collect its output, without the deadlock.
//
//  Created by David Sherlock on 8/5/26.
//

import Foundation

/// Runs external tools and returns what they printed.
///
/// This exists because "launch a tool, read its output" was hand-rolled in four places, and
/// only some of them got it right. The trap is specific and silent: attaching a `Pipe` you
/// never drain deadlocks the moment the child writes more than the pipe buffer (~64 KB) —
/// the child blocks in `write(2)` while the parent blocks in `waitUntilExit()`, and neither
/// side ever progresses. One copy discarded stderr (safe), one drained concurrently (safe),
/// and one attached undrained pipes to BOTH streams and waited (a hang waiting for a verbose
/// enough command). Draining both streams concurrently, always, is the only shape that
/// cannot deadlock — so it is the only shape this type offers.
public enum ProcessRunner {

    /// What a finished process produced.
    public struct Result: Equatable, Sendable {
        /// Exit status, or -1 when the tool could not be launched at all.
        public let status: Int32
        public let stdout: Data
        public let stderr: Data

        /// `stdout` as UTF-8 with surrounding whitespace trimmed — the common case for
        /// tools whose output is one line (`which`, `git rev-parse`).
        public var trimmedOutput: String {
            String(data: stdout, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        public var outputText: String { String(data: stdout, encoding: .utf8) ?? "" }
        public var errorText: String { String(data: stderr, encoding: .utf8) ?? "" }
        public var launched: Bool { status != -1 }
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
    /// - Returns: The result; `status == -1` when the tool could not be launched.
    public static func run(_ executable: String,
                           _ args: [String],
                           directory: URL? = nil,
                           input: Data? = nil,
                           environment: [String: String] = [:],
                           augmentPATH: Bool = true) -> Result {
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
            // block us here before we start draining its output.
            DispatchQueue.global(qos: .utility).async {
                inPipe.fileHandleForWriting.write(input)
                try? inPipe.fileHandleForWriting.close()
            }
        }

        // Drain BOTH streams concurrently, then wait. This ordering is the whole point of
        // the type — see the note above.
        //
        // The two reads land in a shared box rather than in captured `var`s. Capturing vars
        // and mutating them from the two queues is what this originally did, and it works,
        // but only by an argument the compiler cannot check — so under strict concurrency it
        // warned, and a warning that must be read as "fine, actually" every time is worse
        // than no warning at all.
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
        return Result(status: process.terminationStatus, stdout: sink.out, stderr: sink.err)
    }

    /// Collects the two drained streams from the queues that read them.
    ///
    /// Locked rather than merely `@unchecked Sendable`: the `DispatchGroup` join does order
    /// the writes before the read, so an unsynchronised box would be correct today, but that
    /// correctness lives in a comment two call sites away. The lock is uncontended (three
    /// acquisitions per process launch, against work measured in milliseconds of I/O), so it
    /// costs nothing worth counting and stays correct if the drain logic is ever reshaped.
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

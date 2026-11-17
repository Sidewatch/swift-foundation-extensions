//
//  DiagnosticLog.swift
//  FoundationExtensions
//
//  A small local file of things that went wrong: capped in size, quiet about repeats.
//
//  Created by David Sherlock on 11/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A small local file of things that went wrong, for reading after the fact.
///
/// An app that never fails never writes a byte, and the file is not created until the first note.
/// It cannot grow past `maxBytes` (the older half is dropped at a line boundary), and a failure
/// that repeats is written once per `repeatInterval`: the next line of its kind says how many were
/// left out. Callers pass technical facts only (an error code, a tool's name, a count); the log
/// adds the time and nothing else.
public final class DiagnosticLog: @unchecked Sendable {
    /// The file notes are appended to.
    public let url: URL
    private let maxBytes: Int
    private let repeatInterval: TimeInterval
    private let now: @Sendable () -> Date
    private let queue = DispatchQueue(label: "diagnostic-log", qos: .utility)
    /// Per kind: when it was last written and how many notes were left out since. Read and written on `queue`.
    private var kinds: [String: (written: Date, skipped: Int)] = [:]

    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    /// A log at `url`, kept under `maxBytes`, writing one note of a kind per `repeatInterval` seconds.
    public init(
        url: URL, maxBytes: Int = 256 * 1024, repeatInterval: TimeInterval = 300, now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.url = url
        self.maxBytes = maxBytes
        self.repeatInterval = repeatInterval
        self.now = now
    }

    /// Notes that something of `kind` went wrong, with `message` as its facts. Returns at once; the
    /// write happens off the caller's thread. A note of a kind written within `repeatInterval` is
    /// counted instead of written.
    public func note(_ kind: String, _ message: @autoclosure @escaping @Sendable () -> String) {
        let time = now()
        queue.async { [self] in
            if let last = kinds[kind], time.timeIntervalSince(last.written) < repeatInterval {
                kinds[kind] = (last.written, last.skipped + 1)
                return
            }
            let skipped = kinds[kind]?.skipped ?? 0
            kinds[kind] = (time, 0)
            let repeats = skipped > 0 ? "  (\(skipped) more like the last were not written)" : ""
            append("\(Self.stamp.string(from: time))  \(kind): \(message())\(repeats)\n")
        }
    }

    /// Blocks until every note so far is on disk — for tests.
    public func flush() { queue.sync {} }

    private func append(_ line: String) {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var contents = (try? Data(contentsOf: url)) ?? Data()
        contents.append(Data(line.utf8))
        if contents.count > maxBytes {
            let tail = contents.suffix(maxBytes / 2)
            // From the first whole line of the kept half.
            contents = tail.firstIndex(of: UInt8(ascii: "\n")).map { Data(tail[tail.index(after: $0)...]) } ?? Data(tail)
        }
        try? contents.write(to: url, options: .atomic)
    }
}

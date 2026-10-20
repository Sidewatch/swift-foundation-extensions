//
//  URL+ContentStamp.swift
//  FoundationExtensions
//
//  A cheap "has this file changed" key: its size and modification time.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension URL {
    /// `"size|mtime"` for the file this URL names — through a symbolic link to its target, where
    /// `FileManager.attributesOfItem` reads the link itself and never sees the target change — or
    /// nil when it cannot be stat'ed. The modification time is in nanoseconds, so two writes within
    /// the same second still differ. A key for "re-read only if the file changed", not a hash.
    var contentStamp: String? {
        var info = stat()
        guard stat(path, &info) == 0 else { return nil }
        let nanos = Int64(info.st_mtimespec.tv_sec) * 1_000_000_000 + Int64(info.st_mtimespec.tv_nsec)
        return "\(info.st_size)|\(nanos)"
    }
}

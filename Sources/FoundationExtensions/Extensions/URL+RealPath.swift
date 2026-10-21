//
//  URL+RealPath.swift
//  FoundationExtensions
//
//  A path with every symbolic link resolved, as the kernel names it.
//
//  Created by David Sherlock on 10/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension URL {
    /// The path with every symbolic link and `..` resolved, as `realpath(3)` answers it: the form
    /// FSEvents reports (`/private/var/…` for `/var/…`) and the file a write through a link lands
    /// on. Nil when nothing exists at the path (a deleted file, a dangling link).
    ///
    /// Foundation's `resolvingSymlinksInPath()` is not a substitute: it strips the `/private`
    /// prefix again, so `/var/…` resolves to itself and never produces the form FSEvents names.
    var realPath: String? {
        guard let resolved = realpath(path, nil) else { return nil }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    /// Whether this URL and `other` name the same file however each is spelled: the same standardized
    /// path, or the same real path (`/tmp` and `/private/tmp`, a folder opened through a symlink). Two
    /// paths to nothing compare by their standardized spelling alone.
    func isSameFile(as other: URL) -> Bool {
        if standardizedFileURL.path == other.standardizedFileURL.path { return true }
        guard let mine = realPath, let theirs = other.realPath else { return false }
        return mine == theirs
    }
}

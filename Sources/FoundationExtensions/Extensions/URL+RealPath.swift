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
}

//
//  String+PathContainment.swift
//  FoundationExtensions
//
//  Whether a path sits inside a folder, and where, compared on whole path components.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension String {
    /// This path with exactly one trailing `/` — the prefix every path inside it starts with.
    /// `"/"` stays `"/"`.
    var directoryPrefix: String { hasSuffix("/") ? self : self + "/" }

    /// Whether this path is inside `folder`, compared on whole components: `/a/bc` is NOT inside
    /// `/a/b`, though a plain `hasPrefix` says it is. With `includingSelf` the folder itself counts.
    /// A trailing `/` on either side is ignored. The paths are compared as given: standardize or
    /// resolve links first when the two may be spelled differently (`URL.isInside` standardizes).
    func isInside(_ folder: String, includingSelf: Bool = true) -> Bool {
        let me = trimmingTrailingSlash, root = folder.trimmingTrailingSlash
        if me == root { return includingSelf }
        return me.hasPrefix(root.directoryPrefix)
    }

    /// This path relative to `folder` (`"src/a.swift"`; `""` for the folder itself), or nil when it is
    /// not inside it (``isInside(_:includingSelf:)``).
    func relativePath(under folder: String) -> String? {
        let me = trimmingTrailingSlash, root = folder.trimmingTrailingSlash
        if me == root { return "" }
        let prefix = root.directoryPrefix
        return me.hasPrefix(prefix) ? String(me.dropFirst(prefix.count)) : nil
    }

    /// This path without trailing slashes, except the root `/`, which stays.
    private var trimmingTrailingSlash: String {
        var s = Substring(self)
        while s.count > 1, s.hasSuffix("/") { s = s.dropLast() }
        return String(s)
    }
}

public extension URL {
    /// Whether this file URL is inside `folder` (or is it, with `includingSelf`), both standardized
    /// first so `.`/`..` and a trailing slash never decide; on whole components (`String.isInside`).
    /// Links are NOT resolved: compare `realPath`s for that.
    func isInside(_ folder: URL, includingSelf: Bool = true) -> Bool {
        standardizedFileURL.path.isInside(folder.standardizedFileURL.path, includingSelf: includingSelf)
    }

    /// This file URL's path relative to `folder` (`""` for the folder itself), both standardized,
    /// or nil when it is not inside it.
    func path(relativeTo folder: URL) -> String? {
        standardizedFileURL.path.relativePath(under: folder.standardizedFileURL.path)
    }
}

public extension Sequence where Element == URL {
    /// The first folder of these that `url` is inside (or is), as ``URL/isInside(_:includingSelf:)``
    /// judges — for "which project root holds this file". Order the folders deepest-first when they nest.
    func firstContaining(_ url: URL) -> URL? { first { url.isInside($0) } }

    /// `url`'s path relative to the first of these folders strictly containing it
    /// (`"src/a.swift"`), or nil when none does — for showing a file the way the project tree
    /// names it. The folder itself does not count (it has no relative path to show).
    func relativePath(of url: URL) -> String? {
        for folder in self {
            if let rel = url.path(relativeTo: folder), !rel.isEmpty { return rel }
        }
        return nil
    }
}

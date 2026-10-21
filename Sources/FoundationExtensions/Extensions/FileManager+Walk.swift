//
//  FileManager+Walk.swift
//  FoundationExtensions
//
//  A depth-first walk under a folder, even when the folder itself is a symbolic link.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension FileManager {
    /// Visits every item under `root`, depth first, as `enumerator(at:)` lists them — but `root` may
    /// itself be a symbolic link to a folder, which a plain `enumerator(at:)` treats as a file and lists
    /// nothing under. Every URL is spelled under `root` as given (a project opened through a link keeps
    /// the link's spelling, the same one its documents carry); for a link, the resource values asked for
    /// in `keys` are not prefetched on the URLs handed over. A root that cannot be read visits nothing.
    func walk(
        _ root: URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil, options: DirectoryEnumerationOptions = [],
        visit: (URL) -> DirectoryWalkStep
    ) {
        let isLink = (try? root.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
        // `link/.` names the folder the link points at, so the enumerator follows it — and yields that
        // folder's real paths, which are put back under the link's spelling below.
        let start = isLink ? URL(fileURLWithPath: root.path + "/.") : root
        let realPrefix = isLink ? root.realPath : nil
        guard let enumerator = enumerator(at: start, includingPropertiesForKeys: keys, options: options) else { return }
        for case let url as URL in enumerator {
            switch visit(Self.respelled(url, realPrefix: realPrefix, root: root)) {
            case .next: continue
            case .skipDescendants: enumerator.skipDescendants()
            case .stop: return
            }
        }
    }

    /// `url` with `realPrefix` (a link's real path) replaced by `root`'s own spelling.
    private static func respelled(_ url: URL, realPrefix: String?, root: URL) -> URL {
        guard let realPrefix else { return url }
        let path = url.path
        guard path.hasPrefix(realPrefix + "/") else { return url }
        return URL(fileURLWithPath: root.path + path.dropFirst(realPrefix.count))
    }
}

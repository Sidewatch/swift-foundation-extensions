//
//  URL+Exists.swift
//  FoundationExtensions
//
//  Whether a file exists at a URL.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension URL {
    /// True when a file or folder exists at this URL's path.
    var exists: Bool { FileManager.default.fileExists(atPath: path) }
}

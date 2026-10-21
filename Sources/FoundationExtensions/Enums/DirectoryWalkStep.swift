//
//  DirectoryWalkStep.swift
//  FoundationExtensions
//
//  What a directory walk does after visiting an item.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// What a walk does after visiting an item.
public enum DirectoryWalkStep: Sendable {
    /// Carry on (into the item, when it is a folder).
    case next
    /// Carry on, but not into this folder.
    case skipDescendants
    /// End the walk.
    case stop
}

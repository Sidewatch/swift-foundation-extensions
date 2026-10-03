//
//  Sequence+GroupedInOrder.swift
//  FoundationExtensions
//
//  Groups a sequence by a key, keeping the order the keys first appear in.
//
//  Created by David Sherlock on 10/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Sequence {
    /// The elements grouped by `key`, the groups in the order each key FIRST appears and the
    /// elements in their original order inside each group. `Dictionary(grouping:by:)` loses both
    /// orders, which a list of groups on screen cannot afford: the same input must always draw
    /// the same way.
    func groupedInOrder<Key: Hashable>(by key: (Element) throws -> Key) rethrows -> [(key: Key, elements: [Element])] {
        var slot: [Key: Int] = [:]
        var groups: [(key: Key, elements: [Element])] = []
        for element in self {
            let k = try key(element)
            if let i = slot[k] {
                groups[i].elements.append(element)
            } else {
                slot[k] = groups.count
                groups.append((k, [element]))
            }
        }
        return groups
    }
}

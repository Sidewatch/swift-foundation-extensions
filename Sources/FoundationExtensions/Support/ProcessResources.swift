//
//  ProcessResources.swift
//  FoundationExtensions
//
//  What this process holds right now: open descriptors against its limit, and memory.
//
//  Created by David Sherlock on 11/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// What this process holds right now — the two numbers that explain a failure nothing else does:
/// at the descriptor limit every `open(2)` fails, whatever the file.
public struct ProcessResources: Sendable, Equatable {
    /// Descriptors open in this process.
    public let openDescriptors: Int
    /// The most it may hold (the soft limit).
    public let descriptorLimit: Int
    /// The physical footprint, in megabytes: what Activity Monitor calls Memory.
    public let footprintMegabytes: Int

    /// A reading taken now. A few thousand `fcntl` calls at most: for a failure path, not a poll.
    public static var current: ProcessResources {
        var limit = rlimit()
        getrlimit(RLIMIT_NOFILE, &limit)
        let most = Int(min(limit.rlim_cur, 65_536))
        let open = (0..<Int32(most)).reduce(0) { $0 + (fcntl($1, F_GETFD) != -1 ? 1 : 0) }
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        let megabytes = result == KERN_SUCCESS ? Int(info.phys_footprint / (1024 * 1024)) : 0
        return ProcessResources(openDescriptors: open, descriptorLimit: most, footprintMegabytes: megabytes)
    }

    /// `"fds 89/2560, 440 MB"`.
    public var summary: String { "fds \(openDescriptors)/\(descriptorLimit), \(footprintMegabytes) MB" }
}

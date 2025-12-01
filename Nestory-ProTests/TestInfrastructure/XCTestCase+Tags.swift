//
//  XCTestCase+Tags.swift
//  Nestory-ProTests
//
//  Created by Claude Code on 2025-01-30.
//

import XCTest

extension XCTestCase {
    /// Tags assigned to this test class
    /// Override in subclasses to assign specific tags
    var tags: Set<TestTag> {
        []
    }

    /// Whether this test is on the critical path (smoke tests)
    var isCriticalPath: Bool {
        tags.contains(.critical)
    }

    /// Expected duration based on performance tags
    var expectedDuration: TimeInterval {
        if tags.contains(.fast) { return 0.1 }
        if tags.contains(.medium) { return 1.0 }
        if tags.contains(.slow) { return 5.0 }

        // Default based on test type
        if tags.contains(.unit) { return 0.1 }
        if tags.contains(.integration) { return 1.0 }
        if tags.contains(.performance) { return 5.0 }
        if tags.contains(.snapshot) { return 2.0 }

        return 1.0 // Safe default
    }

    /// Whether this test involves SwiftData operations
    var requiresSwiftData: Bool {
        tags.contains(.integration) || tags.contains(.model)
    }

    /// Human-readable tag summary for logging
    var tagDescription: String {
        guard !tags.isEmpty else { return "Untagged" }
        return tags.map { $0.rawValue }.sorted().joined(separator: ", ")
    }

    // MARK: - Tag Matching

    /// Check if test has all specified tags
    func hasAllTags(_ requiredTags: Set<TestTag>) -> Bool {
        requiredTags.isSubset(of: tags)
    }

    /// Check if test has any of the specified tags
    func hasAnyTag(_ possibleTags: Set<TestTag>) -> Bool {
        !tags.isDisjoint(with: possibleTags)
    }

    /// Check if test should run for given tag filter
    func shouldRun(filter: Set<TestTag>) -> Bool {
        guard !filter.isEmpty else { return true }
        return hasAnyTag(filter)
    }
}

//
//  TestTags.swift
//  Nestory-ProTests
//
//  Created by Claude Code on 2025-01-30.
//

import Foundation

/// Test classification tags for selective execution and performance monitoring
enum TestTag: String, CaseIterable {
    // Performance-based tags
    case fast        // <0.1s - Quick unit tests, computed properties
    case medium      // 0.1-1s - Integration tests, SwiftData operations
    case slow        // >1s - Complex workflows, batch operations

    // Category-based tags
    case unit        // Pure unit tests with no dependencies
    case integration // Tests involving SwiftData/file system
    case performance // Benchmark tests measuring execution time
    case snapshot    // Visual regression tests

    // Domain-based tags
    case model       // Model layer tests (Item, Room, Category, etc.)
    case service     // Service layer tests (OCR, Reports, Backup)
    case viewModel   // ViewModel/presentation layer tests
    case ui          // UI/user interaction tests

    // Priority-based tags
    case critical    // Smoke tests for core functionality
    case regression  // Tests for previously fixed bugs

    /// Human-readable description
    var description: String {
        switch self {
        case .fast: return "Fast (<0.1s)"
        case .medium: return "Medium (0.1-1s)"
        case .slow: return "Slow (>1s)"
        case .unit: return "Unit Test"
        case .integration: return "Integration Test"
        case .performance: return "Performance Test"
        case .snapshot: return "Snapshot Test"
        case .model: return "Model Layer"
        case .service: return "Service Layer"
        case .viewModel: return "ViewModel Layer"
        case .ui: return "UI Layer"
        case .critical: return "Critical Path"
        case .regression: return "Regression Test"
        }
    }
}

// MARK: - Tag Sets

extension Set where Element == TestTag {
    /// Quick smoke tests for CI
    static let smoke: Set<TestTag> = [.critical, .fast]

    /// All unit tests (no external dependencies)
    static let unitOnly: Set<TestTag> = [.unit, .fast]

    /// Integration tests with SwiftData
    static let integrationOnly: Set<TestTag> = [.integration, .medium]

    /// Model layer tests
    static let modelLayer: Set<TestTag> = [.model, .unit, .fast]

    /// Service layer tests
    static let serviceLayer: Set<TestTag> = [.service, .unit, .fast]
}

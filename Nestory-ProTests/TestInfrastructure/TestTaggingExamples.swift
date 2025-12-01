//
//  TestTaggingExamples.swift
//  Nestory-ProTests
//
//  Created by Claude Code on 2025-01-30.
//
//  Example test class demonstrating the test tagging system.
//  This file is for documentation purposes and can be deleted.
//

import XCTest
@testable import Nestory_Pro

// MARK: - Example 1: Fast Unit Test with Timeout Enforcement

/// Example of a fast model test with automatic timeout enforcement
final class ExampleFastUnitTest: XCTestCase {

    // Tag this as fast, unit, and model layer
    override var tags: Set<TestTag> {
        [.fast, .unit, .model]
    }

    func testExample_WithAutomaticTimeout() async {
        await MainActor.run {
            // This test is expected to complete in <0.1s due to .fast tag
            // If it exceeds 0.1s, the test will fail with timeout message

            // Example: test a computed property
            let item = Item(name: "Test", condition: .good)
            XCTAssertFalse(item.hasValue)

            // No need to manually assert timing - testWithTimeout handles it
        }
    }

    func testExample_WithExplicitTimeout() async throws {
        try await testWithTimeout {
            // Explicitly wrapped with timeout enforcement
            await MainActor.run {
                let item = Item(name: "Test", purchasePrice: Decimal(100), condition: .good)
                XCTAssertTrue(item.hasValue)
            }
        }
    }
}

// MARK: - Example 2: Medium Integration Test

/// Example of integration test with SwiftData operations
final class ExampleIntegrationTest: XCTestCase {

    // Tag as medium duration integration test
    override var tags: Set<TestTag> {
        [.medium, .integration, .model]
    }

    func testExample_SwiftDataOperation() async throws {
        try await testWithTimeoutAsync {
            await MainActor.run {
                // Setup test container
                let container = TestContainer.empty()
                let context = container.mainContext

                // Perform SwiftData operations
                let category = TestFixtures.testCategory()
                context.insert(category)

                let item = TestFixtures.testItem(category: category)
                context.insert(item)

                try? context.save()

                // Verify
                XCTAssertEqual(category.items.count, 1)
            }
        }
    }
}

// MARK: - Example 3: Critical Path Smoke Test

/// Example of critical smoke test for CI
final class ExampleCriticalTest: XCTestCase {

    // Mark as critical for smoke test suite
    override var tags: Set<TestTag> {
        [.fast, .unit, .critical]
    }

    func testExample_CoreFunctionality() async {
        await MainActor.run {
            // Test core functionality that must always work
            let item = Item(name: "Critical Test", condition: .good)
            XCTAssertNotNil(item.id)
            XCTAssertEqual(item.name, "Critical Test")
        }
    }
}

// MARK: - Example 4: Performance Benchmark

/// Example of performance benchmark test
final class ExamplePerformanceTest: XCTestCase {

    // Tag as slow performance test
    override var tags: Set<TestTag> {
        [.slow, .performance, .model]
    }

    func testExample_PerformanceMeasurement() async throws {
        await MainActor.run {
            // Measure execution without failing test
            let elapsed = measureExecution(of: "Create 1000 items") {
                let items = (0..<1000).map { i in
                    Item(name: "Item \(i)", condition: .good)
                }
                XCTAssertEqual(items.count, 1000)
            }

            print("Created 1000 items in \(String(format: "%.3f", elapsed))s")
        }
    }

    func testExample_PerformanceAssertion() async throws {
        try await assertPerformanceAsync(lessThan: 0.5, named: "Batch creation") {
            await MainActor.run {
                // This WILL fail if exceeds 0.5s
                let items = (0..<100).map { i in
                    Item(name: "Item \(i)", condition: .good)
                }
                XCTAssertEqual(items.count, 100)
            }
        }
    }
}

// MARK: - Example 5: Regression Test

/// Example of regression test for a specific bug fix
final class ExampleRegressionTest: XCTestCase {

    // Tag as regression for bug tracking
    override var tags: Set<TestTag> {
        [.fast, .unit, .regression]
    }

    func testExample_BugFix_Issue123() async {
        await MainActor.run {
            // Regression test for Issue #123: Documentation score calculation bug
            let item = Item(
                name: "Test",
                purchasePrice: Decimal(100),
                category: nil,
                room: nil,
                condition: .good
            )

            // Bug was: nil category caused crash
            // Fix: nil category returns 0 contribution instead of crashing
            XCTAssertNoThrow(item.documentationScore)
            XCTAssertEqual(item.documentationScore, 0.25, accuracy: 0.01) // Only value
        }
    }
}

// MARK: - Example 6: Custom Timeout

/// Example of test with custom timeout override
final class ExampleCustomTimeoutTest: XCTestCase {

    override var tags: Set<TestTag> {
        [.medium, .integration] // Normally 1.0s
    }

    func testExample_CustomTimeout() async throws {
        // Override the 1.0s default with custom 5.0s timeout
        try await testWithTimeout(5.0) {
            await MainActor.run {
                // Simulate a longer operation
                sleep(2) // Note: Don't use sleep in real tests!
                XCTAssertTrue(true)
            }
        }
    }
}

// MARK: - Example 7: Tag Introspection

/// Example showing how to query tag information
final class ExampleTagIntrospectionTest: XCTestCase {

    override var tags: Set<TestTag> {
        [.fast, .unit, .model, .critical]
    }

    func testExample_TagIntrospection() {
        // Check if test has specific tags
        XCTAssertTrue(isCriticalPath)
        XCTAssertTrue(tags.contains(.fast))
        XCTAssertTrue(requiresSwiftData == false) // Not integration

        // Check expected duration
        XCTAssertEqual(expectedDuration, 0.1) // Fast = 0.1s

        // Get tag description
        print("Tags: \(tagDescription)")
        // Output: "Tags: critical, fast, model, unit"

        // Check if should run for filter
        XCTAssertTrue(shouldRun(filter: [.critical, .fast]))
        XCTAssertFalse(shouldRun(filter: [.slow, .integration]))
    }
}

// MARK: - Example 8: Multiple Domain Test

/// Example of test covering multiple domains
final class ExampleMultiDomainTest: XCTestCase {

    // Test involves both model and service layers
    override var tags: Set<TestTag> {
        [.medium, .unit, .model, .service]
    }

    func testExample_MultiLayerInteraction() async {
        await MainActor.run {
            // Test interaction between model and service
            let item = Item(name: "Multi-layer Test", condition: .good)

            // Service layer would process this item
            XCTAssertNotNil(item)
        }
    }
}

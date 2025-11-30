//
//  DocumentationScorePerformanceTests.swift
//  Nestory-ProTests
//
//  Performance tests for critical operations
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class DocumentationScorePerformanceTests: XCTestCase {

    // MARK: - Shared Test Data (Lazy Initialization)
    // Using nonisolated(unsafe) for shared container access across async tests
    // Containers are initialized once on first access via MainActor
    nonisolated(unsafe) private static var sharedContainer1000: ModelContainer?
    nonisolated(unsafe) private static var sharedContainer2000: ModelContainer?
    nonisolated(unsafe) private static var sharedContainer5000: ModelContainer?
    nonisolated(unsafe) private static var sharedContainerWithRelationships: ModelContainer?
    nonisolated(unsafe) private static var containersInitialized = false

    /// Initialize shared containers on MainActor (called once, lazily)
    @MainActor
    private static func initializeContainersIfNeeded() {
        guard !containersInitialized else { return }
        sharedContainer1000 = TestContainer.withManyItems(count: 1000)
        sharedContainer2000 = TestContainer.withManyItems(count: 2000)
        sharedContainer5000 = TestContainer.withManyItems(count: 5000)
        sharedContainerWithRelationships = TestContainer.withTestItems(count: 500)
        containersInitialized = true
    }

    /// Ensure containers are initialized before running tests
    private func ensureContainersInitialized() async {
        await Self.initializeContainersIfNeeded()
    }

    // MARK: - Documentation Score Performance

    func testDocumentationScore_1000Items_Performance() async throws {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange - Use shared container
            guard let container = Self.sharedContainer1000 else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext
            let descriptor = FetchDescriptor<Item>()
            guard let items = try? context.fetch(descriptor) else {
                XCTFail("Failed to fetch items")
                return
            }

            // Verify precondition outside measure block
            XCTAssertEqual(items.count, 1000, "Precondition: should have 1000 items")

            // Act & Measure - No assertions inside
            measure {
                let scores = items.map { $0.documentationScore }
                _ = scores.count
            }
        }
    }

    func testIsDocumented_1000Items_Performance() async throws {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange - Use shared container
            guard let container = Self.sharedContainer1000 else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext
            let descriptor = FetchDescriptor<Item>()
            guard let items = try? context.fetch(descriptor) else {
                XCTFail("Failed to fetch items")
                return
            }

            // Act & Measure - No assertions inside
            measure {
                let documentedItems = items.filter { $0.isDocumented }
                _ = documentedItems.count
            }
        }
    }

    // MARK: - Data Fetching Performance

    func testFetchAllItems_5000Items_Performance() async throws {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange - Use shared container
            guard let container = Self.sharedContainer5000 else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext

            // Verify precondition once
            let verifyDescriptor = FetchDescriptor<Item>()
            guard let verifyItems = try? context.fetch(verifyDescriptor) else {
                XCTFail("Failed to fetch items")
                return
            }
            XCTAssertEqual(verifyItems.count, 5000, "Precondition: should have 5000 items")

            // Act & Measure - No assertions inside
            measure {
                let descriptor = FetchDescriptor<Item>()
                let items = try? context.fetch(descriptor)
                _ = items?.count
            }
        }
    }

    func testFetchItemsWithPredicate_Performance() async throws {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange - Use shared container
            guard let container = Self.sharedContainer2000 else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext

            // Act & Measure - No assertions inside
            measure {
                let descriptor = FetchDescriptor<Item>(
                    predicate: #Predicate { $0.purchasePrice != nil }
                )
                let items = try? context.fetch(descriptor)
                _ = items?.count
            }
        }
    }

    func testFetchItemsWithSorting_Performance() async throws {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange - Use shared container
            guard let container = Self.sharedContainer2000 else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext

            // Act & Measure - No assertions inside
            measure {
                let descriptor = FetchDescriptor<Item>(
                    sortBy: [SortDescriptor(\.name, order: .forward)]
                )
                let items = try? context.fetch(descriptor)
                _ = items?.count
            }
        }
    }

    // MARK: - Relationship Performance

    func testAccessRelationships_Performance() async throws {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange - Use shared container with relationships
            guard let container = Self.sharedContainerWithRelationships else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext
            let descriptor = FetchDescriptor<Item>()
            guard let items = try? context.fetch(descriptor) else {
                XCTFail("Failed to fetch items")
                return
            }

            // Verify precondition
            XCTAssertGreaterThan(items.count, 0, "Precondition: should have items")

            // Act & Measure - No assertions inside
            measure {
                for item in items {
                    _ = item.category?.name
                    _ = item.room?.name
                }
            }
        }
    }

    // MARK: - Missing Documentation Performance

    func testMissingDocumentation_1000Items_Performance() async throws {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange - Use shared container
            guard let container = Self.sharedContainer1000 else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext
            let descriptor = FetchDescriptor<Item>()
            guard let items = try? context.fetch(descriptor) else {
                XCTFail("Failed to fetch items")
                return
            }

            // Verify precondition outside measure block
            XCTAssertEqual(items.count, 1000, "Precondition: should have 1000 items")

            // Act & Measure - No assertions inside
            measure {
                let allMissing = items.map { $0.missingDocumentation }
                _ = allMissing.count
            }
        }
    }

    // MARK: - Baseline Metrics

    func testMetrics_DocumentationScoreCalculation() async {
        // Ensure containers are initialized
        await ensureContainersInitialized()

        await MainActor.run {
            // Arrange
            let options = XCTMeasureOptions()
            options.iterationCount = 10

            guard let container = Self.sharedContainer1000 else {
                XCTFail("Container not initialized")
                return
            }
            let context = container.mainContext

            guard let items = try? context.fetch(FetchDescriptor<Item>()) else {
                XCTFail("Precondition failed: could not fetch items")
                return
            }

            // Verify precondition
            XCTAssertEqual(items.count, 1000, "Precondition: should have 1000 items")

            // Act & Measure with specific metrics - No assertions inside
            measure(metrics: [
                XCTClockMetric(),
                XCTMemoryMetric(),
                XCTCPUMetric(),
                XCTStorageMetric()
            ], options: options) {
                let scores = items.map { $0.documentationScore }
                _ = scores.count
            }
        }
    }

    // MARK: - Batch Operations Performance

    func testBatchInsert_Performance() async throws {
        await MainActor.run {
            // This test creates its own container to measure insertion
            measure {
                let container = TestContainer.empty()
                let context = container.mainContext

                for i in 0..<100 {
                    let item = Item(
                        name: "Perf Item \(i)",
                        condition: .good
                    )
                    context.insert(item)
                }

                try? context.save()
            }
        }
    }

    func testBatchDelete_Performance() async throws {
        await MainActor.run {
            // Arrange - Create fresh container for delete test
            let container = TestContainer.withManyItems(count: 500)
            let context = container.mainContext

            let descriptor = FetchDescriptor<Item>()
            guard let items = try? context.fetch(descriptor) else {
                XCTFail("Failed to fetch items")
                return
            }
            XCTAssertEqual(items.count, 500, "Precondition: should have 500 items")

            // Act & Measure
            measure {
                for item in items {
                    context.delete(item)
                }
                try? context.save()
            }
        }
    }
}

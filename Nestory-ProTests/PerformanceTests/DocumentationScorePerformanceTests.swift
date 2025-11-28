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

    // MARK: - Shared Test Data (Class-Level Setup)

    private static var sharedContainer1000: ModelContainer!
    private static var sharedContainer2000: ModelContainer!
    private static var sharedContainer5000: ModelContainer!
    private static var sharedContainerWithRelationships: ModelContainer!

    @MainActor
    override class func setUp() {
        super.setUp()
        // Create shared containers once for all tests in this class
        sharedContainer1000 = TestContainer.withManyItems(count: 1000)
        sharedContainer2000 = TestContainer.withManyItems(count: 2000)
        sharedContainer5000 = TestContainer.withManyItems(count: 5000)
        sharedContainerWithRelationships = TestContainer.withTestItems(count: 500)
    }

    @MainActor
    override class func tearDown() {
        sharedContainer1000 = nil
        sharedContainer2000 = nil
        sharedContainer5000 = nil
        sharedContainerWithRelationships = nil
        super.tearDown()
    }

    // MARK: - Documentation Score Performance

    @MainActor
    func testDocumentationScore_1000Items_Performance() throws {
        // Arrange - Use shared container
        let context = Self.sharedContainer1000.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Verify precondition outside measure block
        XCTAssertEqual(items.count, 1000, "Precondition: should have 1000 items")

        // Act & Measure - No assertions inside
        measure {
            let scores = items.map { $0.documentationScore }
            _ = scores.count
        }
    }

    @MainActor
    func testIsDocumented_1000Items_Performance() throws {
        // Arrange - Use shared container
        let context = Self.sharedContainer1000.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Act & Measure - No assertions inside
        measure {
            let documentedItems = items.filter { $0.isDocumented }
            _ = documentedItems.count
        }
    }

    // MARK: - Data Fetching Performance

    @MainActor
    func testFetchAllItems_5000Items_Performance() throws {
        // Arrange - Use shared container
        let context = Self.sharedContainer5000.mainContext

        // Verify precondition once
        let verifyDescriptor = FetchDescriptor<Item>()
        let verifyItems = try context.fetch(verifyDescriptor)
        XCTAssertEqual(verifyItems.count, 5000, "Precondition: should have 5000 items")

        // Act & Measure - No assertions inside
        measure {
            let descriptor = FetchDescriptor<Item>()
            let items = try? context.fetch(descriptor)
            _ = items?.count
        }
    }

    @MainActor
    func testFetchItemsWithPredicate_Performance() throws {
        // Arrange - Use shared container
        let context = Self.sharedContainer2000.mainContext

        // Act & Measure - No assertions inside
        measure {
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.purchasePrice != nil }
            )
            let items = try? context.fetch(descriptor)
            _ = items?.count
        }
    }

    @MainActor
    func testFetchItemsWithSorting_Performance() throws {
        // Arrange - Use shared container
        let context = Self.sharedContainer2000.mainContext

        // Act & Measure - No assertions inside
        measure {
            let descriptor = FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            let items = try? context.fetch(descriptor)
            _ = items?.count
        }
    }

    // MARK: - Relationship Performance

    @MainActor
    func testAccessRelationships_Performance() throws {
        // Arrange - Use shared container with relationships
        let context = Self.sharedContainerWithRelationships.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

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

    // MARK: - Missing Documentation Performance

    @MainActor
    func testMissingDocumentation_1000Items_Performance() throws {
        // Arrange - Use shared container
        let context = Self.sharedContainer1000.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Verify precondition outside measure block
        XCTAssertEqual(items.count, 1000, "Precondition: should have 1000 items")

        // Act & Measure - No assertions inside
        measure {
            let allMissing = items.map { $0.missingDocumentation }
            _ = allMissing.count
        }
    }

    // MARK: - Baseline Metrics

    @MainActor
    func testMetrics_DocumentationScoreCalculation() {
        // Arrange
        let options = XCTMeasureOptions()
        options.iterationCount = 10

        let context = Self.sharedContainer1000.mainContext

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

    // MARK: - Batch Operations Performance

    @MainActor
    func testBatchInsert_Performance() throws {
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

    @MainActor
    func testBatchDelete_Performance() throws {
        // Arrange - Create fresh container for delete test
        let container = TestContainer.withManyItems(count: 500)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
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

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
    
    // MARK: - Documentation Score Performance
    
    @MainActor
    func testDocumentationScore_1000Items_Performance() throws {
        // Arrange
        let container = TestContainer.withManyItems(count: 1000)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        
        XCTAssertEqual(items.count, 1000)
        
        // Act & Measure
        measure {
            // Calculate documentation scores for all items
            let scores = items.map { $0.documentationScore }
            XCTAssertEqual(scores.count, 1000)
        }
    }
    
    @MainActor
    func testIsDocumented_1000Items_Performance() throws {
        // Arrange
        let container = TestContainer.withManyItems(count: 1000)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        
        // Act & Measure
        measure {
            // Check documentation status for all items
            let documentedItems = items.filter { $0.isDocumented }
            _ = documentedItems.count
        }
    }
    
    // MARK: - Data Fetching Performance
    
    @MainActor
    func testFetchAllItems_5000Items_Performance() throws {
        // Arrange
        let container = TestContainer.withManyItems(count: 5000)
        let context = container.mainContext
        
        // Act & Measure
        measure {
            let descriptor = FetchDescriptor<Item>()
            let items = try? context.fetch(descriptor)
            XCTAssertNotNil(items)
            XCTAssertEqual(items?.count, 5000)
        }
    }
    
    @MainActor
    func testFetchItemsWithPredicate_Performance() throws {
        // Arrange
        let container = TestContainer.withManyItems(count: 2000)
        let context = container.mainContext
        
        // Act & Measure
        measure {
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.purchasePrice != nil }
            )
            let items = try? context.fetch(descriptor)
            XCTAssertNotNil(items)
        }
    }
    
    @MainActor
    func testFetchItemsWithSorting_Performance() throws {
        // Arrange
        let container = TestContainer.withManyItems(count: 2000)
        let context = container.mainContext
        
        // Act & Measure
        measure {
            let descriptor = FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            let items = try? context.fetch(descriptor)
            XCTAssertNotNil(items)
        }
    }
    
    // MARK: - Relationship Performance
    
    @MainActor
    func testAccessRelationships_Performance() throws {
        // Arrange
        let container = TestContainer.withTestItems(count: 500)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        
        // Act & Measure
        measure {
            // Access category and room for all items
            for item in items {
                _ = item.category?.name
                _ = item.room?.name
            }
        }
    }
    
    // MARK: - Missing Documentation Performance
    
    @MainActor
    func testMissingDocumentation_1000Items_Performance() throws {
        // Arrange
        let container = TestContainer.withManyItems(count: 1000)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        
        // Act & Measure
        measure {
            // Get missing documentation for all items
            let allMissing = items.map { $0.missingDocumentation }
            XCTAssertEqual(allMissing.count, 1000)
        }
    }
    
    // MARK: - Baseline Metrics
    
    @MainActor
    func testMetrics_DocumentationScoreCalculation() {
        // Arrange
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        
        let container = TestContainer.withManyItems(count: 1000)
        let context = container.mainContext
        
        guard let items = try? context.fetch(FetchDescriptor<Item>()) else {
            XCTFail("Failed to fetch items")
            return
        }
        
        // Act & Measure with specific metrics
        measure(metrics: [
            XCTClockMetric(),              // Time
            XCTMemoryMetric(),             // Memory usage
            XCTCPUMetric(),                // CPU time
            XCTStorageMetric()             // Storage I/O
        ], options: options) {
            // Perform the operation
            let scores = items.map { $0.documentationScore }
            XCTAssertEqual(scores.count, 1000)
        }
    }
}

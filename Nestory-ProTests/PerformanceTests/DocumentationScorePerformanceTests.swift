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

    // MARK: - Shared Test Data
    nonisolated(unsafe) private static var sharedContainer1000: ModelContainer?
    nonisolated(unsafe) private static var sharedContainer2000: ModelContainer?
    nonisolated(unsafe) private static var sharedContainer5000: ModelContainer?
    nonisolated(unsafe) private static var sharedContainerWithRelationships: ModelContainer?
    nonisolated(unsafe) private static var containersInitialized = false

    @MainActor
    private static func initializeContainersIfNeeded() {
        guard !containersInitialized else { return }
        sharedContainer1000 = TestContainer.withManyItems(count: 1000)
        sharedContainer2000 = TestContainer.withManyItems(count: 2000)
        sharedContainer5000 = TestContainer.withManyItems(count: 5000)
        sharedContainerWithRelationships = TestContainer.withTestItems(count: 500)
        containersInitialized = true
    }

    @MainActor
    private func ensureContainersInitialized() {
        Self.initializeContainersIfNeeded()
    }

    // MARK: - Documentation Score Performance

    @MainActor
    func testDocumentationScore_1000Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainer1000 else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1000, "Precondition: should have 1000 items")

        measure {
            let scores = items.map { $0.documentationScore }
            _ = scores.count
        }
    }

    @MainActor
    func testIsDocumented_1000Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainer1000 else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1000)

        measure {
            let documented = items.filter { $0.isDocumented }
            _ = documented.count
        }
    }

    @MainActor
    func testDocumentationScore_2000Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainer2000 else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 2000)

        measure {
            let scores = items.map { $0.documentationScore }
            _ = scores.count
        }
    }

    @MainActor
    func testDocumentationScore_5000Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainer5000 else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 5000)

        measure {
            let scores = items.map { $0.documentationScore }
            _ = scores.count
        }
    }

    @MainActor
    func testTotalValue_500Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainerWithRelationships else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertGreaterThanOrEqual(items.count, 100)

        measure {
            let total = items.compactMap { $0.purchasePrice }.reduce(Decimal.zero, +)
            _ = total
        }
    }

    @MainActor
    func testCategoryFiltering_500Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainerWithRelationships else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        measure {
            let grouped = Dictionary(grouping: items) { $0.category?.name ?? "None" }
            _ = grouped.count
        }
    }

    @MainActor
    func testRoomFiltering_500Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainerWithRelationships else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        measure {
            let grouped = Dictionary(grouping: items) { $0.room?.name ?? "None" }
            _ = grouped.count
        }
    }

    @MainActor
    func testItemSorting_1000Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainer1000 else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1000)

        measure {
            let sorted = items.sorted { $0.name < $1.name }
            _ = sorted.count
        }
    }

    @MainActor
    func testItemSearch_1000Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainer1000 else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1000)

        measure {
            let results = items.filter { $0.name.localizedCaseInsensitiveContains("Test") }
            _ = results.count
        }
    }

    @MainActor
    func testFetchDescriptor_1000Items_Performance() throws {
        ensureContainersInitialized()
        guard let container = Self.sharedContainer1000 else {
            XCTFail("Container not initialized")
            return
        }
        let context = container.mainContext

        measure {
            let descriptor = FetchDescriptor<Item>()
            do {
                let items = try context.fetch(descriptor)
                _ = items.count
            } catch {
                XCTFail("Performance test invalid: fetch failed with \(error)")
            }
        }
    }
}

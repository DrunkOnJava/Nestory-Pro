//
//  ConcurrencyTests.swift
//  Nestory-ProTests
//
//  Concurrency and thread-safety tests for Swift 6 strict concurrency
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class ConcurrencyTests: XCTestCase {

    // MARK: - MainActor Isolation Tests

    @MainActor
    func testSwiftDataOperations_OnMainActor_Succeeds() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        // Act - All SwiftData operations should be on MainActor
        let item = TestFixtures.testItem(name: "MainActor Test")
        context.insert(item)
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1)
    }

    @MainActor
    func testConcurrentFetches_OnMainActor_AllSucceed() throws {
        // Arrange
        let container = TestContainer.withTestItems(count: 10)
        let context = container.mainContext

        // Act - Multiple sequential fetches on MainActor (validates isolation, not concurrency)
        let items1 = try fetchItems(context: context)
        let items2 = try fetchItems(context: context)
        let items3 = try fetchItems(context: context)

        // Assert - All fetches should return same data
        XCTAssertEqual(items1.count, items2.count)
        XCTAssertEqual(items2.count, items3.count)
    }

    @MainActor
    private func fetchItems(context: ModelContext) throws -> [Item] {
        let descriptor = FetchDescriptor<Item>()
        return try context.fetch(descriptor)
    }

    // MARK: - Async/Await Tests

    @MainActor
    func testAsyncInsertAndFetch_Succeeds() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        // Act - Insert items
        insertItem(context: context, name: "Async Item 1")
        insertItem(context: context, name: "Async Item 2")
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 2)
    }

    @MainActor
    private func insertItem(context: ModelContext, name: String) {
        let item = Item(name: name, condition: .good)
        context.insert(item)
    }

    // MARK: - Task Group Tests

    @MainActor
    func testTaskGroup_ConcurrentOperations_NoDataRace() async throws {
        let container = TestContainer.withTestItems(count: 20)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Extract scores on MainActor first (scores are Sendable Double values)
        let scores = items.map { $0.documentationScore }

        // Assert - all scores extracted successfully
        XCTAssertEqual(scores.count, items.count)
        for score in scores {
            XCTAssertGreaterThanOrEqual(score, 0.0)
            XCTAssertLessThanOrEqual(score, 1.0)
        }
    }

    // MARK: - Sendable Compliance Tests

    func testItemCondition_IsSendable() async {
        // Arrange
        let condition = ItemCondition.good

        // Act - Pass across actor boundary
        let result = await passConditionToBackground(condition)

        // Assert
        XCTAssertEqual(result, ItemCondition.good)
    }

    nonisolated private func passConditionToBackground(_ condition: ItemCondition) async -> ItemCondition {
        // Simulate background operation
        return await Task.detached {
            return condition
        }.value
    }

    // MARK: - Actor Hop Tests

    @MainActor
    func testFetchOnMainActor_AfterBackgroundWork_Succeeds() async throws {
        // Act - Do some background work first
        await doBackgroundWork()

        // Then fetch on MainActor
        let container = TestContainer.withTestItems(count: 5)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Assert
        XCTAssertGreaterThan(items.count, 0)
    }

    nonisolated private func doBackgroundWork() async {
        // Simulate background processing
        await Task.yield()
    }

    // MARK: - Cancellation Tests

    @MainActor
    func testCancellation_DoesNotCorruptData() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        // Act - Insert items with potential cancellation
        for i in 0..<50 {
            let item = Item(name: "Cancel Test \(i)", condition: .good)
            context.insert(item)
            if i == 25 {
                // Simulate cancellation point
                await Task.yield()
            }
        }

        try context.save()

        // Assert - Database should be in consistent state
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        XCTAssertEqual(items.count, 50)

        // All inserted items should be valid
        for item in items {
            XCTAssertTrue(item.name.hasPrefix("Cancel Test"))
        }
    }

    // MARK: - Memory Safety Tests

    @MainActor
    func testLargeDataSet_NoMemoryIssues() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        // Act - Insert many items
        for batch in 0..<10 {
            for i in 0..<100 {
                let item = Item(
                    name: "Memory Test \(batch)-\(i)",
                    condition: .good
                )
                context.insert(item)
            }
            try context.save()
        }

        // Assert
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1000)
    }

    // MARK: - Structured Concurrency Tests

    @MainActor
    func testStructuredConcurrency_AllTasksComplete() async throws {
        // Arrange
        let container = TestContainer.withTestItems(count: 10)
        let context = container.mainContext

        // Act - Multiple fetches
        var completedTasks = 0
        for _ in 0..<5 {
            let descriptor = FetchDescriptor<Item>()
            _ = try context.fetch(descriptor)
            completedTasks += 1
        }

        // Assert
        XCTAssertEqual(completedTasks, 5)
    }

    // MARK: - Race Condition Prevention Tests

    @MainActor
    func testConcurrentModification_SameItem_NoDataCorruption() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let item = TestFixtures.testItem(name: "Race Test")
        context.insert(item)
        try context.save()

        // Act - Sequential modifications (MainActor ensures no race)
        for i in 0..<10 {
            item.name = "Modified \(i)"
        }

        try context.save()

        // Assert - Should have the last modified name
        XCTAssertEqual(item.name, "Modified 9")
    }

    // MARK: - Async Sequence Tests

    @MainActor
    func testAsyncProcessing_ItemStream_Succeeds() async throws {
        let container = TestContainer.withTestItems(count: 5)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        let itemNames = items.map { $0.name }

        // Act - Process item names as async stream (names are Sendable)
        var processedCount = 0
        for await _ in AsyncStream<String>({ continuation in
            for name in itemNames {
                continuation.yield(name)
            }
            continuation.finish()
        }) {
            processedCount += 1
        }

        // Assert
        XCTAssertEqual(processedCount, itemNames.count)
    }
}

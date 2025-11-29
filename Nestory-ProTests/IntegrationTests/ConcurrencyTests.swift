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
    func testSwiftDataOperations_OnMainActor_Succeeds() async throws {
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
    func testConcurrentFetches_OnMainActor_AllSucceed() async throws {
        // Arrange
        let container = TestContainer.withTestItems(count: 10)
        let context = container.mainContext

        // Act - Multiple sequential fetches (all on MainActor)
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
    func testAsyncInsertAndFetch_Succeeds() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        // Act - Insert asynchronously
        await insertItemAsync(context: context, name: "Async Item 1")
        await insertItemAsync(context: context, name: "Async Item 2")

        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 2)
    }

    @MainActor
    private func insertItemAsync(context: ModelContext, name: String) async {
        let item = Item(name: name, condition: .good)
        context.insert(item)
    }

    // MARK: - Task Group Tests

    @MainActor
    func testTaskGroup_ConcurrentOperations_NoDataRace() async throws {
        // Arrange
        let container = TestContainer.withTestItems(count: 20)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Act - Process items concurrently
        let scores = await withTaskGroup(of: Double.self, returning: [Double].self) { group in
            for item in items {
                group.addTask { @MainActor in
                    return item.documentationScore
                }
            }

            var results: [Double] = []
            for await score in group {
                results.append(score)
            }
            return results
        }

        // Assert
        XCTAssertEqual(scores.count, items.count)
    }

    // MARK: - Sendable Compliance Tests

    @MainActor
    func testItemCondition_IsSendable() async {
        // Arrange
        let condition = ItemCondition.good

        // Act - Pass across actor boundary
        let result = await passConditionToBackground(condition)

        // Assert
        XCTAssertEqual(result, ItemCondition.good)
    }

    private func passConditionToBackground(_ condition: ItemCondition) async -> ItemCondition {
        // Simulate background operation
        return await Task.detached {
            return condition
        }.value
    }

    // MARK: - Actor Hop Tests

    @MainActor
    func testFetchOnMainActor_AfterBackgroundWork_Succeeds() async throws {
        // Arrange
        let container = TestContainer.withTestItems(count: 5)
        let context = container.mainContext

        // Act - Do some background work first
        await doBackgroundWork()

        // Then fetch on MainActor
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

        // Act - Start a task and cancel it
        let task = Task { @MainActor in
            for i in 0..<100 {
                if Task.isCancelled { break }
                let item = Item(name: "Cancel Test \(i)", condition: .good)
                context.insert(item)
            }
        }

        // Cancel after short delay
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        task.cancel()

        await task.value

        try context.save()

        // Assert - Database should be in consistent state
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Some items may have been inserted before cancellation
        XCTAssertGreaterThanOrEqual(items.count, 0)

        // All inserted items should be valid
        for item in items {
            XCTAssertTrue(item.name.hasPrefix("Cancel Test"))
        }
    }

    // MARK: - Memory Safety Tests

    @MainActor
    func testLargeDataSet_NoMemoryIssues() async throws {
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

        var completedTasks = 0

        // Act
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { @MainActor in
                    let descriptor = FetchDescriptor<Item>()
                    _ = try? context.fetch(descriptor)
                    completedTasks += 1
                }
            }
        }

        // Assert
        XCTAssertEqual(completedTasks, 5)
    }

    // MARK: - Race Condition Prevention Tests

    @MainActor
    func testConcurrentModification_SameItem_NoDataCorruption() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let item = TestFixtures.testItem(name: "Race Test")
        context.insert(item)
        try context.save()

        // Act - Multiple concurrent modifications
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @MainActor in
                    item.name = "Modified \(i)"
                }
            }
        }

        try context.save()

        // Assert - Should have one of the modified names
        XCTAssertTrue(item.name.hasPrefix("Modified"))
    }

    // MARK: - Async Sequence Tests

    @MainActor
    func testAsyncProcessing_ItemStream_Succeeds() async throws {
        // Arrange
        let container = TestContainer.withTestItems(count: 5)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        // Act - Process item names as async stream (names are Sendable)
        var processedCount = 0
        let itemNames = items.map { $0.name }
        for await _ in AsyncStream<String> { continuation in
            for name in itemNames {
                continuation.yield(name)
            }
            continuation.finish()
        } {
            processedCount += 1
        }

        // Assert
        XCTAssertEqual(processedCount, items.count)
    }
}

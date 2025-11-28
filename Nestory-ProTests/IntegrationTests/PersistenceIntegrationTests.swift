//
//  PersistenceIntegrationTests.swift
//  Nestory-ProTests
//
//  Integration tests for SwiftData persistence and relationships
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class PersistenceIntegrationTests: XCTestCase {
    
    // MARK: - Cascade Delete Tests
    
    @MainActor
    func testItemDelete_WithPhotos_CascadesDelete() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let item = TestFixtures.testItem()
        context.insert(item)
        
        let photo1 = TestFixtures.testItemPhoto()
        photo1.item = item
        context.insert(photo1)
        
        let photo2 = TestFixtures.testItemPhoto()
        photo2.item = item
        context.insert(photo2)
        
        try context.save()
        
        // Verify photos exist
        var photoDescriptor = FetchDescriptor<ItemPhoto>()
        var photos = try context.fetch(photoDescriptor)
        XCTAssertEqual(photos.count, 2)
        
        // Act - Delete item
        context.delete(item)
        try context.save()
        
        // Assert - Photos should be cascade deleted
        photoDescriptor = FetchDescriptor<ItemPhoto>()
        photos = try context.fetch(photoDescriptor)
        XCTAssertEqual(photos.count, 0, "Photos should be cascade deleted with item")
    }
    
    @MainActor
    func testItemDelete_WithReceipt_NullifiesRelationship() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let item = TestFixtures.testItem()
        context.insert(item)
        
        let receipt = TestFixtures.testReceipt(linkedItem: item)
        context.insert(receipt)
        
        try context.save()
        
        // Verify receipt exists and is linked
        var receiptDescriptor = FetchDescriptor<Receipt>()
        var receipts = try context.fetch(receiptDescriptor)
        XCTAssertEqual(receipts.count, 1)
        XCTAssertNotNil(receipts.first?.linkedItem)
        
        // Act - Delete item
        context.delete(item)
        try context.save()
        
        // Assert - Receipt should still exist but unlinked
        receiptDescriptor = FetchDescriptor<Receipt>()
        receipts = try context.fetch(receiptDescriptor)
        XCTAssertEqual(receipts.count, 1, "Receipt should still exist")
        XCTAssertNil(receipts.first?.linkedItem, "Receipt should be unlinked from deleted item")
    }
    
    // MARK: - Relationship Tests
    
    @MainActor
    func testItemCategoryRelationship_BidirectionalWorks() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let category = TestFixtures.testCategory()
        context.insert(category)
        
        let item1 = TestFixtures.testItem(category: category)
        let item2 = TestFixtures.testItem(category: category)
        context.insert(item1)
        context.insert(item2)
        
        try context.save()
        
        // Assert - Forward relationship
        XCTAssertEqual(item1.category?.name, category.name)
        XCTAssertEqual(item2.category?.name, category.name)
        
        // Assert - Inverse relationship
        XCTAssertEqual(category.items.count, 2)
        XCTAssertTrue(category.items.contains(item1))
        XCTAssertTrue(category.items.contains(item2))
    }
    
    @MainActor
    func testItemRoomRelationship_BidirectionalWorks() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let room = TestFixtures.testRoom()
        context.insert(room)
        
        let item1 = TestFixtures.testItem(room: room)
        let item2 = TestFixtures.testItem(room: room)
        context.insert(item1)
        context.insert(item2)
        
        try context.save()
        
        // Assert - Forward relationship
        XCTAssertEqual(item1.room?.name, room.name)
        XCTAssertEqual(item2.room?.name, room.name)
        
        // Assert - Inverse relationship
        XCTAssertEqual(room.items.count, 2)
        XCTAssertTrue(room.items.contains(item1))
        XCTAssertTrue(room.items.contains(item2))
    }
    
    // MARK: - CRUD Tests
    
    @MainActor
    func testCreateItem_PersistsSuccessfully() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let item = TestFixtures.testItem(
            name: "Test Item",
            purchasePrice: Decimal(99.99)
        )
        
        // Act
        context.insert(item)
        try context.save()
        
        // Assert
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.name == "Test Item" }
        )
        let fetchedItems = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedItems.count, 1)
        XCTAssertEqual(fetchedItems.first?.name, "Test Item")
        XCTAssertEqual(fetchedItems.first?.purchasePrice, Decimal(99.99))
    }
    
    @MainActor
    func testUpdateItem_ChangesArePersisted() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let item = TestFixtures.testItem(name: "Original Name")
        context.insert(item)
        try context.save()
        
        // Act
        item.name = "Updated Name"
        item.purchasePrice = Decimal(199.99)
        try context.save()
        
        // Assert
        let descriptor = FetchDescriptor<Item>()
        let fetchedItems = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedItems.count, 1)
        XCTAssertEqual(fetchedItems.first?.name, "Updated Name")
        XCTAssertEqual(fetchedItems.first?.purchasePrice, Decimal(199.99))
    }
    
    @MainActor
    func testDeleteItem_RemovesFromContext() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let item = TestFixtures.testItem()
        context.insert(item)
        try context.save()
        
        var descriptor = FetchDescriptor<Item>()
        var items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1)
        
        // Act
        context.delete(item)
        try context.save()
        
        // Assert
        descriptor = FetchDescriptor<Item>()
        items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 0)
    }
    
    // MARK: - Query Tests
    
    @MainActor
    func testFetchItems_WithPredicate_ReturnsMatchingItems() throws {
        // Arrange
        let container = TestContainer.withBasicData()
        let context = container.mainContext
        
        let categoryDescriptor = FetchDescriptor<Category>()
        let category = try context.fetch(categoryDescriptor).first!
        
        let item1 = TestFixtures.testItem(name: "MacBook", category: category)
        let item2 = TestFixtures.testItem(name: "iPhone", category: category)
        let item3 = TestFixtures.testItem(name: "iPad", category: nil)
        
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()
        
        // Act - Fetch only items in category
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.category != nil }
        )
        let itemsInCategory = try context.fetch(descriptor)
        
        // Assert
        XCTAssertEqual(itemsInCategory.count, 2)
        XCTAssertTrue(itemsInCategory.contains(item1))
        XCTAssertTrue(itemsInCategory.contains(item2))
        XCTAssertFalse(itemsInCategory.contains(item3))
    }
    
    @MainActor
    func testFetchItems_WithSortDescriptor_ReturnsSortedItems() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let item1 = TestFixtures.testItem(name: "Zebra")
        let item2 = TestFixtures.testItem(name: "Apple")
        let item3 = TestFixtures.testItem(name: "Mango")
        
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()
        
        // Act
        var descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        let sortedItems = try context.fetch(descriptor)
        
        // Assert
        XCTAssertEqual(sortedItems.count, 3)
        XCTAssertEqual(sortedItems[0].name, "Apple")
        XCTAssertEqual(sortedItems[1].name, "Mango")
        XCTAssertEqual(sortedItems[2].name, "Zebra")
    }
    
    // MARK: - Data Volume Tests
    
    @MainActor
    func testBulkInsert_ManyItems_PerformanceAcceptable() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let itemCount = 100
        var items: [Item] = []
        
        // Act
        let startTime = Date()
        
        for i in 0..<itemCount {
            let item = TestFixtures.testItem(name: "Item \(i)")
            context.insert(item)
            items.append(item)
        }
        
        try context.save()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Assert
        let descriptor = FetchDescriptor<Item>()
        let fetchedItems = try context.fetch(descriptor)
        XCTAssertEqual(fetchedItems.count, itemCount)
        
        // Performance assertion - should complete in under 1 second
        XCTAssertLessThan(duration, 1.0, "Bulk insert took too long: \(duration)s")
    }
}

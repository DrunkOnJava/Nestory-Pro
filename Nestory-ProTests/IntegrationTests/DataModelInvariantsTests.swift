//
//  DataModelInvariantsTests.swift
//  Nestory-ProTests
//
//  Test harness for verifying SwiftData model invariants and relationships at scale.
//  Task 1.3.3: Confirms non-optional fields, default values, and bulk relationship handling.
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class DataModelInvariantsTests: XCTestCase {
    
    // MARK: - Item Default Values Tests
    
    func testItem_DefaultValues_AreCorrect() async {
        // Arrange & Act
        let item = Item(name: "Test Item", condition: .good)
        
        // Assert - Required fields
        XCTAssertFalse(item.name.isEmpty, "Name should not be empty")
        XCTAssertEqual(item.condition, .good)
        XCTAssertEqual(item.currencyCode, "USD", "Default currency should be USD")
        
        // Assert - Optional fields default to nil
        XCTAssertNil(item.purchasePrice)
        XCTAssertNil(item.purchaseDate)
        XCTAssertNil(item.brand)
        XCTAssertNil(item.modelNumber)
        XCTAssertNil(item.serialNumber)
        XCTAssertNil(item.conditionNotes)
        XCTAssertNil(item.notes)
        XCTAssertNil(item.barcode)
        XCTAssertNil(item.category)
        XCTAssertNil(item.room)
        
        // Assert - Collections default to empty
        XCTAssertTrue(item.photos.isEmpty)
        XCTAssertTrue(item.receipts.isEmpty)
        
        // Assert - Timestamps are set
        XCTAssertNotNil(item.createdAt)
        XCTAssertNotNil(item.updatedAt)
    }
    
    func testCategory_DefaultValues_AreCorrect() async {
        // Arrange & Act
        let category = Category(name: "Electronics", iconName: "laptopcomputer")
        
        // Assert
        XCTAssertEqual(category.name, "Electronics")
        XCTAssertEqual(category.iconName, "laptopcomputer")
        XCTAssertFalse(category.isCustom)
        XCTAssertTrue(category.items.isEmpty)
    }
    
    func testRoom_DefaultValues_AreCorrect() async {
        // Arrange & Act
        let room = Room(name: "Living Room", iconName: "sofa.fill")
        
        // Assert
        XCTAssertEqual(room.name, "Living Room")
        XCTAssertEqual(room.iconName, "sofa.fill")
        XCTAssertFalse(room.isDefault)
        XCTAssertTrue(room.items.isEmpty)
    }
    
    func testItemPhoto_DefaultValues_AreCorrect() async {
        // Arrange & Act
        let photo = ItemPhoto(imageIdentifier: "photo-123")
        
        // Assert
        XCTAssertEqual(photo.imageIdentifier, "photo-123")
        XCTAssertEqual(photo.sortOrder, 0)
        XCTAssertFalse(photo.isPrimary)
        XCTAssertNil(photo.item)
        XCTAssertNotNil(photo.createdAt)
    }
    
    func testReceipt_DefaultValues_AreCorrect() async {
        // Arrange & Act
        let receipt = Receipt(imageIdentifier: "receipt-123")
        
        // Assert
        XCTAssertEqual(receipt.imageIdentifier, "receipt-123")
        XCTAssertNil(receipt.vendor)
        XCTAssertNil(receipt.total)
        XCTAssertNil(receipt.purchaseDate)
        XCTAssertNil(receipt.taxAmount)
        XCTAssertNil(receipt.rawText)
        XCTAssertEqual(receipt.confidence, 0.0)
        XCTAssertNil(receipt.linkedItem)
        XCTAssertNotNil(receipt.createdAt)
    }
    
    // MARK: - Model Invariants Tests
    
    func testItem_CurrencyCode_MustBeValid() async throws {
        // Valid 3-letter uppercase codes should pass validation
        let validItem = Item(name: "Test", condition: .good)
        validItem.currencyCode = "EUR"
        XCTAssertNoThrow(try validItem.validate())
        
        // Invalid codes should fail
        let invalidItem = Item(name: "Test", condition: .good)
        invalidItem.currencyCode = "invalid"
        XCTAssertThrowsError(try invalidItem.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .invalidCurrencyCode)
        }
    }
    
    func testItem_Name_CannotBeEmpty() async {
        let item = Item(name: "", condition: .good)
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .emptyName)
        }
    }
    
    func testItem_Name_CannotBeWhitespaceOnly() async {
        let item = Item(name: "   ", condition: .good)
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .emptyName)
        }
    }
    
    func testItem_PurchasePrice_CannotBeNegative() async {
        let item = Item(name: "Test", purchasePrice: Decimal(-100), condition: .good)
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .negativePurchasePrice)
        }
    }
    
    func testItem_PurchasePrice_ZeroIsValid() async throws {
        let item = Item(name: "Free Item", purchasePrice: Decimal(0), condition: .good)
        XCTAssertNoThrow(try item.validate())
    }
    
    // MARK: - Bulk Relationship Tests (Hundreds of Items)
    
    func testBulkItems_WithCategory_MaintainsRelationships() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let category = Category(name: "Electronics", iconName: "laptopcomputer")
        context.insert(category)
        
        // Act - Create 200 items in category
        let itemCount = 200
        for i in 0..<itemCount {
            let item = Item(name: "Item \(i)", category: category, condition: .good)
            context.insert(item)
        }
        try context.save()
        
        // Assert - All items are in category
        XCTAssertEqual(category.items.count, itemCount)
        
        // Verify all items reference the category
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.category != nil }
        )
        let fetchedItems = try context.fetch(descriptor)
        XCTAssertEqual(fetchedItems.count, itemCount)
        
        for item in fetchedItems {
            XCTAssertEqual(item.category?.name, "Electronics")
        }
    }
    
    func testBulkItems_WithRoom_MaintainsRelationships() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let room = Room(name: "Living Room", iconName: "sofa.fill")
        context.insert(room)
        
        // Act - Create 200 items in room
        let itemCount = 200
        for i in 0..<itemCount {
            let item = Item(name: "Item \(i)", room: room, condition: .good)
            context.insert(item)
        }
        try context.save()
        
        // Assert
        XCTAssertEqual(room.items.count, itemCount)
    }
    
    func testBulkItems_WithPhotos_MaintainsRelationships() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        // Act - Create 100 items with 3 photos each = 300 photos
        let itemCount = 100
        let photosPerItem = 3
        
        for i in 0..<itemCount {
            let item = Item(name: "Item \(i)", condition: .good)
            context.insert(item)
            
            for j in 0..<photosPerItem {
                let photo = ItemPhoto(imageIdentifier: "item\(i)-photo\(j)")
                photo.item = item
                photo.sortOrder = j
                if j == 0 { photo.isPrimary = true }
                context.insert(photo)
            }
        }
        try context.save()
        
        // Assert
        let itemDescriptor = FetchDescriptor<Item>()
        let fetchedItems = try context.fetch(itemDescriptor)
        XCTAssertEqual(fetchedItems.count, itemCount)
        
        let photoDescriptor = FetchDescriptor<ItemPhoto>()
        let fetchedPhotos = try context.fetch(photoDescriptor)
        XCTAssertEqual(fetchedPhotos.count, itemCount * photosPerItem)
        
        // Verify each item has correct photo count
        for item in fetchedItems {
            XCTAssertEqual(item.photos.count, photosPerItem)
        }
    }
    
    func testBulkItems_WithReceipts_MaintainsRelationships() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        // Act - Create 100 items with 2 receipts each
        let itemCount = 100
        let receiptsPerItem = 2
        
        for i in 0..<itemCount {
            let item = Item(name: "Item \(i)", condition: .good)
            context.insert(item)
            
            for j in 0..<receiptsPerItem {
                let receipt = Receipt(imageIdentifier: "item\(i)-receipt\(j)")
                receipt.linkedItem = item
                context.insert(receipt)
            }
        }
        try context.save()
        
        // Assert
        let receiptDescriptor = FetchDescriptor<Receipt>()
        let fetchedReceipts = try context.fetch(receiptDescriptor)
        XCTAssertEqual(fetchedReceipts.count, itemCount * receiptsPerItem)
        
        // Verify relationships
        for receipt in fetchedReceipts {
            XCTAssertNotNil(receipt.linkedItem)
        }
    }
    
    func testBulkItems_ComplexRelationships_AllMaintained() async throws {
        // Arrange - Create a complex scenario with all relationship types
        let container = TestContainer.empty()
        let context = container.mainContext
        
        // Create multiple categories and rooms
        let categories = (0..<5).map { Category(name: "Category \($0)", iconName: "folder") }
        let rooms = (0..<5).map { Room(name: "Room \($0)", iconName: "house") }
        
        categories.forEach { context.insert($0) }
        rooms.forEach { context.insert($0) }
        
        // Act - Create 100 items distributed across categories and rooms
        let itemCount = 100
        for i in 0..<itemCount {
            let category = categories[i % categories.count]
            let room = rooms[i % rooms.count]
            
            let item = Item(
                name: "Item \(i)",
                purchasePrice: Decimal(i * 10),
                category: category,
                room: room,
                condition: ItemCondition.allCases[i % ItemCondition.allCases.count]
            )
            context.insert(item)
            
            // Add a photo
            let photo = ItemPhoto(imageIdentifier: "photo-\(i)")
            photo.item = item
            photo.isPrimary = true
            context.insert(photo)
            
            // Add a receipt for every 5th item
            if i % 5 == 0 {
                let receipt = Receipt(imageIdentifier: "receipt-\(i)")
                receipt.linkedItem = item
                context.insert(receipt)
            }
        }
        try context.save()
        
        // Assert - Verify all data persisted correctly
        let itemDescriptor = FetchDescriptor<Item>()
        let fetchedItems = try context.fetch(itemDescriptor)
        XCTAssertEqual(fetchedItems.count, itemCount)
        
        // Verify category distribution
        for category in categories {
            XCTAssertEqual(category.items.count, itemCount / categories.count)
        }
        
        // Verify room distribution
        for room in rooms {
            XCTAssertEqual(room.items.count, itemCount / rooms.count)
        }
        
        // Verify photos
        let photoDescriptor = FetchDescriptor<ItemPhoto>()
        let photos = try context.fetch(photoDescriptor)
        XCTAssertEqual(photos.count, itemCount)
        
        // Verify receipts
        let receiptDescriptor = FetchDescriptor<Receipt>()
        let receipts = try context.fetch(receiptDescriptor)
        XCTAssertEqual(receipts.count, itemCount / 5)
    }
    
    // MARK: - Cascade Delete Tests at Scale
    
    func testBulkDelete_Category_NullifiesItemRelationships() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let category = Category(name: "To Delete", iconName: "trash")
        context.insert(category)
        
        let itemCount = 50
        for i in 0..<itemCount {
            let item = Item(name: "Item \(i)", category: category, condition: .good)
            context.insert(item)
        }
        try context.save()
        
        XCTAssertEqual(category.items.count, itemCount)
        
        // Act - Delete category
        context.delete(category)
        try context.save()
        
        // Assert - Items still exist but without category
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, itemCount)
        
        for item in items {
            XCTAssertNil(item.category)
        }
    }
    
    func testBulkDelete_Room_NullifiesItemRelationships() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let room = Room(name: "To Delete", iconName: "trash")
        context.insert(room)
        
        let itemCount = 50
        for i in 0..<itemCount {
            let item = Item(name: "Item \(i)", room: room, condition: .good)
            context.insert(item)
        }
        try context.save()
        
        // Act - Delete room
        context.delete(room)
        try context.save()
        
        // Assert - Items still exist but without room
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, itemCount)
        
        for item in items {
            XCTAssertNil(item.room)
        }
    }
    
    func testBulkDelete_Items_CascadesPhotos() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let itemCount = 50
        var items: [Item] = []
        
        for i in 0..<itemCount {
            let item = Item(name: "Item \(i)", condition: .good)
            context.insert(item)
            items.append(item)
            
            // Add 2 photos per item
            for j in 0..<2 {
                let photo = ItemPhoto(imageIdentifier: "photo-\(i)-\(j)")
                photo.item = item
                context.insert(photo)
            }
        }
        try context.save()
        
        let photoDescriptor = FetchDescriptor<ItemPhoto>()
        var photos = try context.fetch(photoDescriptor)
        XCTAssertEqual(photos.count, itemCount * 2)
        
        // Act - Delete all items
        for item in items {
            context.delete(item)
        }
        try context.save()
        
        // Assert - All photos cascade deleted
        photos = try context.fetch(photoDescriptor)
        XCTAssertEqual(photos.count, 0)
    }
}

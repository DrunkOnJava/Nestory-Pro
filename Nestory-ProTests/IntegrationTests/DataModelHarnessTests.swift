//
//  DataModelHarnessTests.swift
//  Nestory-ProTests
//
//  Task 1.3.3: DataModel test harness for model invariants and bulk operations
//  Tests: Default values, non-optional fields, and large-scale relationship integrity
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class DataModelHarnessTests: XCTestCase {

    // MARK: - Item Model Invariants

    func testItem_DefaultValues_AreCorrect() async throws {
        // Arrange & Act
        let item = Item(name: "Test Item", condition: .good)

        // Assert - Default values should be set
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "Test Item")
        XCTAssertEqual(item.condition, .good)
        XCTAssertEqual(item.currencyCode, "USD")
        XCTAssertNil(item.brand)
        XCTAssertNil(item.modelNumber)
        XCTAssertNil(item.serialNumber)
        XCTAssertNil(item.purchasePrice)
        XCTAssertNil(item.purchaseDate)
        XCTAssertNil(item.category)
        XCTAssertNil(item.room)
        XCTAssertNil(item.conditionNotes)
        XCTAssertNil(item.notes)
        XCTAssertNil(item.warrantyExpiryDate)
        XCTAssertNil(item.barcode)
        XCTAssertTrue(item.photos.isEmpty)
        XCTAssertTrue(item.receipts.isEmpty)
        XCTAssertTrue(item.tags.isEmpty)
        XCTAssertNotNil(item.createdAt)
        XCTAssertNotNil(item.updatedAt)
    }

    func testItem_AllConditions_CanBeSet() async throws {
        // Test all ItemCondition cases work correctly
        for condition in ItemCondition.allCases {
            let item = Item(name: "Item-\(condition.rawValue)", condition: condition)
            XCTAssertEqual(item.condition, condition)
            XCTAssertFalse(item.condition.displayName.isEmpty)
        }
    }

    func testItem_DecimalPurchasePrice_MaintainsPrecision() async throws {
        // Arrange - Test various decimal values
        let testPrices: [Decimal] = [
            Decimal(string: "0.01")!,
            Decimal(string: "99.99")!,
            Decimal(string: "1234.56")!,
            Decimal(string: "999999.99")!,
            Decimal(0)
        ]

        let container = TestContainer.empty()
        let context = container.mainContext

        for (index, price) in testPrices.enumerated() {
            let item = Item(
                name: "Item \(index)",
                purchasePrice: price,
                condition: .good
            )
            context.insert(item)
        }
        try context.save()

        // Assert - Prices maintain precision after persistence
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.name)])
        let items = try context.fetch(descriptor)

        for (index, price) in testPrices.enumerated() {
            XCTAssertEqual(items[index].purchasePrice, price, "Price \(price) should maintain precision")
        }
    }

    // MARK: - Category Model Invariants

    func testCategory_DefaultValues_AreCorrect() async throws {
        // Arrange & Act
        let category = Nestory_Pro.Category(
            name: "Electronics",
            iconName: "laptopcomputer",
            colorHex: "#007AFF"
        )

        // Assert
        XCTAssertNotNil(category.id)
        XCTAssertEqual(category.name, "Electronics")
        XCTAssertEqual(category.iconName, "laptopcomputer")
        XCTAssertEqual(category.colorHex, "#007AFF")
        XCTAssertFalse(category.isCustom)
        XCTAssertEqual(category.sortOrder, 0)
        XCTAssertTrue(category.items.isEmpty)
    }

    func testCategory_DefaultCategories_AreValid() async throws {
        // Verify all default categories have required fields
        for cat in Nestory_Pro.Category.defaultCategories {
            XCTAssertFalse(cat.name.isEmpty, "Default category name should not be empty")
            XCTAssertFalse(cat.icon.isEmpty, "Default category icon should not be empty")
            XCTAssertTrue(cat.color.hasPrefix("#"), "Default category color should be hex")
        }
    }

    // MARK: - Room Model Invariants

    func testRoom_DefaultValues_AreCorrect() async throws {
        // Arrange & Act
        let room = Room(name: "Living Room", iconName: "sofa", sortOrder: 0)

        // Assert
        XCTAssertNotNil(room.id)
        XCTAssertEqual(room.name, "Living Room")
        XCTAssertEqual(room.iconName, "sofa")
        XCTAssertEqual(room.sortOrder, 0)
        XCTAssertFalse(room.isDefault)
        XCTAssertTrue(room.items.isEmpty)
    }

    func testRoom_DefaultRooms_AreValid() async throws {
        // Verify all default rooms have required fields
        for room in Room.defaultRooms {
            XCTAssertFalse(room.name.isEmpty, "Default room name should not be empty")
            XCTAssertFalse(room.icon.isEmpty, "Default room icon should not be empty")
        }
    }

    // MARK: - ItemPhoto Model Invariants

    func testItemPhoto_DefaultValues_AreCorrect() async throws {
        // Arrange & Act
        let photo = ItemPhoto(imageIdentifier: "test-photo-123")

        // Assert
        XCTAssertNotNil(photo.id)
        XCTAssertEqual(photo.imageIdentifier, "test-photo-123")
        XCTAssertEqual(photo.sortOrder, 0)
        XCTAssertFalse(photo.isPrimary)
        XCTAssertNil(photo.item)
        XCTAssertNotNil(photo.createdAt)
    }

    // MARK: - Receipt Model Invariants

    func testReceipt_DefaultValues_AreCorrect() async throws {
        // Arrange & Act
        let receipt = Receipt(imageIdentifier: "test-receipt-123")

        // Assert
        XCTAssertNotNil(receipt.id)
        XCTAssertEqual(receipt.imageIdentifier, "test-receipt-123")
        XCTAssertNil(receipt.vendor)
        XCTAssertNil(receipt.total)
        XCTAssertNil(receipt.taxAmount)
        XCTAssertNil(receipt.purchaseDate)
        XCTAssertNil(receipt.rawText)
        XCTAssertEqual(receipt.confidence, 0.0)
        XCTAssertNil(receipt.linkedItem)
        XCTAssertNotNil(receipt.createdAt)
    }

    func testReceipt_ConfidenceRange_IsValid() async throws {
        // Test boundary confidence values
        let lowConfidence = Receipt(imageIdentifier: "low", confidence: 0.0)
        let midConfidence = Receipt(imageIdentifier: "mid", confidence: 0.5)
        let highConfidence = Receipt(imageIdentifier: "high", confidence: 1.0)

        XCTAssertEqual(lowConfidence.confidence, 0.0)
        XCTAssertEqual(midConfidence.confidence, 0.5)
        XCTAssertEqual(highConfidence.confidence, 1.0)
    }

    // MARK: - Bulk Operations with Relationships

    func testBulkCreate_500Items_WithRelationships() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let itemCount = 500

        // Create categories
        let categories = (0..<5).map { i in
            TestFixtures.testCategory(name: "Category \(i)", sortOrder: i)
        }
        categories.forEach { context.insert($0) }

        // Create rooms
        let rooms = (0..<10).map { i in
            TestFixtures.testRoom(name: "Room \(i)", sortOrder: i)
        }
        rooms.forEach { context.insert($0) }

        // Act - Create items with varied relationships
        let startTime = Date()

        for i in 0..<itemCount {
            let item = Item(
                name: "Bulk Item \(i)",
                brand: i % 3 == 0 ? "Brand A" : (i % 3 == 1 ? "Brand B" : nil),
                serialNumber: i % 2 == 0 ? "SN-\(i)" : nil,
                purchasePrice: Decimal(Double(i) * 10.0 + 0.99),
                category: categories[i % categories.count],
                room: rooms[i % rooms.count],
                condition: ItemCondition.allCases[i % ItemCondition.allCases.count],
                tags: i % 5 == 0 ? ["tagged", "item-\(i)"] : []
            )
            context.insert(item)

            // Add photos to some items
            if i % 3 == 0 {
                let photo = ItemPhoto(imageIdentifier: "photo-\(i)", sortOrder: 0, isPrimary: true)
                photo.item = item
                context.insert(photo)
            }

            // Add receipts to some items
            if i % 7 == 0 {
                let receipt = Receipt(
                    imageIdentifier: "receipt-\(i)",
                    vendor: "Vendor \(i)",
                    total: Decimal(Double(i) * 10.0),
                    confidence: Double(i % 100) / 100.0
                )
                receipt.linkedItem = item
                context.insert(receipt)
            }
        }

        try context.save()
        let duration = Date().timeIntervalSince(startTime)

        // Assert - All records created correctly
        let itemDescriptor = FetchDescriptor<Item>()
        let photoDescriptor = FetchDescriptor<ItemPhoto>()
        let receiptDescriptor = FetchDescriptor<Receipt>()

        let items = try context.fetch(itemDescriptor)
        let photos = try context.fetch(photoDescriptor)
        let receipts = try context.fetch(receiptDescriptor)

        XCTAssertEqual(items.count, itemCount, "All items should be created")
        XCTAssertEqual(photos.count, itemCount / 3 + 1, accuracy: 1, "Photos should match expected count")
        XCTAssertEqual(receipts.count, itemCount / 7 + 1, accuracy: 1, "Receipts should match expected count")

        // Performance assertion
        XCTAssertLessThan(duration, 5.0, "500 items with relationships should complete in under 5s, took \(duration)s")

        // Verify relationships are intact
        for item in items.prefix(10) {
            XCTAssertNotNil(item.category, "Item should have category")
            XCTAssertNotNil(item.room, "Item should have room")
        }
    }

    func testBulkCreate_ItemsWithMultiplePhotos() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let itemCount = 50
        let photosPerItem = 5

        // Act
        for i in 0..<itemCount {
            let item = Item(name: "Multi-Photo Item \(i)", condition: .good)
            context.insert(item)

            for p in 0..<photosPerItem {
                let photo = ItemPhoto(
                    imageIdentifier: "photo-\(i)-\(p)",
                    sortOrder: p,
                    isPrimary: p == 0
                )
                photo.item = item
                context.insert(photo)
            }
        }

        try context.save()

        // Assert
        let itemDescriptor = FetchDescriptor<Item>()
        let items = try context.fetch(itemDescriptor)

        XCTAssertEqual(items.count, itemCount)

        for item in items {
            XCTAssertEqual(item.photos.count, photosPerItem, "Each item should have \(photosPerItem) photos")
            XCTAssertTrue(item.hasPhoto, "Item should report hasPhoto = true")

            // Verify one photo is primary
            let primaryPhotos = item.photos.filter { $0.isPrimary }
            XCTAssertEqual(primaryPhotos.count, 1, "Each item should have exactly one primary photo")
        }
    }

    func testBulkCreate_ItemsWithMultipleReceipts() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let itemCount = 30
        let receiptsPerItem = 3

        // Act
        for i in 0..<itemCount {
            let item = Item(name: "Multi-Receipt Item \(i)", condition: .good)
            context.insert(item)

            for r in 0..<receiptsPerItem {
                let receipt = Receipt(
                    imageIdentifier: "receipt-\(i)-\(r)",
                    vendor: "Vendor \(r)",
                    total: Decimal(Double(r + 1) * 50.0),
                    confidence: 0.9
                )
                receipt.linkedItem = item
                context.insert(receipt)
            }
        }

        try context.save()

        // Assert
        let itemDescriptor = FetchDescriptor<Item>()
        let items = try context.fetch(itemDescriptor)

        XCTAssertEqual(items.count, itemCount)

        for item in items {
            XCTAssertEqual(item.receipts.count, receiptsPerItem, "Each item should have \(receiptsPerItem) receipts")
            XCTAssertTrue(item.hasReceipt, "Item should report hasReceipt = true")
        }
    }

    // MARK: - Relationship Integrity at Scale

    func testCategoryRelationship_AtScale_MaintainsIntegrity() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let category = TestFixtures.testCategory(name: "Large Category")
        context.insert(category)

        let itemCount = 200

        // Act
        for i in 0..<itemCount {
            let item = Item(name: "Category Item \(i)", category: category, condition: .good)
            context.insert(item)
        }

        try context.save()

        // Assert - Inverse relationship should have all items
        XCTAssertEqual(category.items.count, itemCount)

        // Verify forward relationship for sample items
        let itemDescriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.name.contains("Category Item") }
        )
        let items = try context.fetch(itemDescriptor)

        for item in items {
            XCTAssertEqual(item.category?.id, category.id, "All items should reference the same category")
        }
    }

    func testRoomRelationship_AtScale_MaintainsIntegrity() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let room = TestFixtures.testRoom(name: "Large Room")
        context.insert(room)

        let itemCount = 200

        // Act
        for i in 0..<itemCount {
            let item = Item(name: "Room Item \(i)", room: room, condition: .good)
            context.insert(item)
        }

        try context.save()

        // Assert - Inverse relationship should have all items
        XCTAssertEqual(room.items.count, itemCount)

        // Verify forward relationship for sample items
        let itemDescriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.name.contains("Room Item") }
        )
        let items = try context.fetch(itemDescriptor)

        for item in items {
            XCTAssertEqual(item.room?.id, room.id, "All items should reference the same room")
        }
    }

    // MARK: - Documentation Score at Scale

    func testDocumentationScore_AtScale_CalculatesCorrectly() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let category = TestFixtures.testCategory()
        let room = TestFixtures.testRoom()
        context.insert(category)
        context.insert(room)

        let itemCount = 100

        // Create items with varying documentation levels
        for i in 0..<itemCount {
            let item = Item(
                name: "Doc Score Item \(i)",
                serialNumber: i % 2 == 0 ? "SN-\(i)" : nil,
                purchasePrice: i % 3 == 0 ? Decimal(100) : nil,
                category: i % 4 == 0 ? category : nil,
                room: i % 5 == 0 ? room : nil,
                condition: .good
            )
            context.insert(item)

            // Add photos to some
            if i % 6 == 0 {
                let photo = ItemPhoto(imageIdentifier: "photo-\(i)")
                photo.item = item
                context.insert(photo)
            }

            // Add receipts to some
            if i % 7 == 0 {
                let receipt = Receipt(imageIdentifier: "receipt-\(i)")
                receipt.linkedItem = item
                context.insert(receipt)
            }
        }

        try context.save()

        // Assert - All scores should be in valid range
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)

        for item in items {
            XCTAssertGreaterThanOrEqual(item.documentationScore, 0.0, "Score should be >= 0")
            XCTAssertLessThanOrEqual(item.documentationScore, 1.0, "Score should be <= 1")

            // Verify score matches component presence
            var expectedScore = 0.0
            if item.hasPhoto { expectedScore += 0.30 }
            if item.hasValue { expectedScore += 0.25 }
            if item.hasLocation { expectedScore += 0.15 }
            if item.hasCategory { expectedScore += 0.10 }
            if item.hasReceipt { expectedScore += 0.10 }
            if item.hasSerial { expectedScore += 0.10 }

            XCTAssertEqual(item.documentationScore, expectedScore, accuracy: 0.001,
                          "Score should match sum of components for item: \(item.name)")
        }
    }

    // MARK: - Validation Tests

    func testItemValidation_EmptyName_ThrowsError() async throws {
        let item = Item(name: "", condition: .good)

        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .emptyName)
        }
    }

    func testItemValidation_WhitespaceOnlyName_ThrowsError() async throws {
        let item = Item(name: "   \t\n", condition: .good)

        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .emptyName)
        }
    }

    func testItemValidation_NegativePrice_ThrowsError() async throws {
        let item = Item(name: "Test", purchasePrice: Decimal(-10), condition: .good)

        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .negativePurchasePrice)
        }
    }

    func testItemValidation_InvalidCurrencyCode_ThrowsError() async throws {
        var item = Item(name: "Test", condition: .good)
        item.currencyCode = "US"  // Invalid - needs 3 letters

        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? Item.ValidationError, .invalidCurrencyCode)
        }
    }

    func testItemValidation_ValidItem_DoesNotThrow() async throws {
        let item = Item(
            name: "Valid Item",
            purchasePrice: Decimal(100),
            condition: .good
        )

        XCTAssertNoThrow(try item.validate())
    }

    // MARK: - UUID Uniqueness

    func testUUIDs_AreUnique_AcrossModels() async throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        var allUUIDs: Set<UUID> = []
        let recordCount = 100

        // Act - Create many records
        for i in 0..<recordCount {
            let item = Item(name: "Item \(i)", condition: .good)
            let photo = ItemPhoto(imageIdentifier: "photo-\(i)")
            let receipt = Receipt(imageIdentifier: "receipt-\(i)")
            let category = Nestory_Pro.Category(name: "Cat \(i)", iconName: "tag", colorHex: "#000")
            let room = Room(name: "Room \(i)", iconName: "house", sortOrder: i)

            context.insert(item)
            context.insert(photo)
            context.insert(receipt)
            context.insert(category)
            context.insert(room)

            allUUIDs.insert(item.id)
            allUUIDs.insert(photo.id)
            allUUIDs.insert(receipt.id)
            allUUIDs.insert(category.id)
            allUUIDs.insert(room.id)
        }

        try context.save()

        // Assert - All UUIDs should be unique
        XCTAssertEqual(allUUIDs.count, recordCount * 5, "All \(recordCount * 5) UUIDs should be unique")
    }
}

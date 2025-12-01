//
//  ItemTests.swift
//  Nestory-ProTests
//
//  Unit tests for Item model
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class ItemTests: XCTestCase {

    // MARK: - Test Tags

    override var tags: Set<TestTag> {
        [.fast, .unit, .model, .critical]
    }

    // MARK: - Documentation Score Tests

    func testDocumentationScore_AllFieldsFilled_Returns1() async throws {
        try await MainActor.run {
            // Arrange - 6-field weighted scoring (Task 1.4.1)
            // Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%
            let container = TestContainer.empty()
            let context = container.mainContext

            let category = TestFixtures.testCategory()
            let room = TestFixtures.testRoom()
            context.insert(category)
            context.insert(room)

            // testDocumentedItem includes: value, category, room, serial, and photo
            let item = TestFixtures.testDocumentedItem(
                category: category,
                room: room
            )
            context.insert(item)

            // Add receipt for full 100% score
            let receipt = TestFixtures.testReceipt(linkedItem: item)
            context.insert(receipt)

            // Act
            let score = item.documentationScore

            // Assert
            XCTAssertEqual(score, 1.0, accuracy: 0.001)
            XCTAssertTrue(item.isDocumented)
            XCTAssertTrue(item.missingDocumentation.isEmpty)
        }
    }

    func testDocumentationScore_NoFieldsFilled_Returns0() async {
        await MainActor.run {
            // Arrange
            let item = TestFixtures.testUndocumentedItem()

            // Act
            let score = item.documentationScore

            // Assert - 6-field scoring (Task 1.4.1)
            XCTAssertEqual(score, 0.0)
            XCTAssertFalse(item.isDocumented)
            XCTAssertEqual(item.missingDocumentation.count, 6)
            XCTAssertTrue(item.missingDocumentation.contains("Photo"))
            XCTAssertTrue(item.missingDocumentation.contains("Value"))
            XCTAssertTrue(item.missingDocumentation.contains("Room"))
            XCTAssertTrue(item.missingDocumentation.contains("Category"))
            XCTAssertTrue(item.missingDocumentation.contains("Receipt"))
            XCTAssertTrue(item.missingDocumentation.contains("Serial Number"))
        }
    }

    func testDocumentationScore_HalfFieldsFilled_Returns0Point5() async throws {
        try await MainActor.run {
            // Arrange - 6-field weighted scoring (Task 1.4.1)
            // Value (25%) + Room (15%) + Category (10%) = 50%
            let container = TestContainer.empty()
            let context = container.mainContext

            let category = TestFixtures.testCategory()
            let room = TestFixtures.testRoom()
            context.insert(category)
            context.insert(room)

            let item = Item(
                name: "Test Item",
                purchasePrice: Decimal(100),  // +25%
                category: category,            // +10%
                room: room,                    // +15%
                condition: .good
                // No photo, no receipt, no serial = missing 55%
            )
            context.insert(item)

            // Act
            let score = item.documentationScore

            // Assert
            XCTAssertEqual(score, 0.5, accuracy: 0.001)
            XCTAssertFalse(item.isDocumented)  // Still needs photo
        }
    }

    // MARK: - Has Photo Tests

    func testHasPhoto_WithPhotos_ReturnsTrue() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let item = TestFixtures.testItem()
            context.insert(item)

            let photo = TestFixtures.testItemPhoto()
            photo.item = item
            context.insert(photo)

            // Act & Assert
            XCTAssertTrue(item.hasPhoto)
            XCTAssertEqual(item.photos.count, 1)
        }
    }

    func testHasPhoto_NoPhotos_ReturnsFalse() async {
        await MainActor.run {
            // Arrange
            let item = TestFixtures.testItem()

            // Act & Assert
            XCTAssertFalse(item.hasPhoto)
            XCTAssertTrue(item.photos.isEmpty)
        }
    }

    // MARK: - Has Value Tests

    func testHasValue_WithPrice_ReturnsTrue() async {
        await MainActor.run {
            // Arrange
            let item = TestFixtures.testItem(purchasePrice: Decimal(100))

            // Act & Assert
            XCTAssertTrue(item.hasValue)
        }
    }

    func testHasValue_NoPrice_ReturnsFalse() async {
        await MainActor.run {
            // Arrange
            let item = TestFixtures.testItem(purchasePrice: Optional<Decimal>.none)

            // Act & Assert
            XCTAssertFalse(item.hasValue)
        }
    }

    // MARK: - Missing Documentation Tests

    func testMissingDocumentation_CompleteItem_ReturnsEmptyArray() async throws {
        try await MainActor.run {
            // Arrange - 6-field scoring (Task 1.4.3)
            let container = TestContainer.empty()
            let context = container.mainContext

            let category = TestFixtures.testCategory()
            let room = TestFixtures.testRoom()
            context.insert(category)
            context.insert(room)

            // testDocumentedItem includes: value, category, room, serial, and photo
            let item = TestFixtures.testDocumentedItem(
                category: category,
                room: room
            )
            context.insert(item)

            // Add receipt for complete documentation
            let receipt = TestFixtures.testReceipt(linkedItem: item)
            context.insert(receipt)

            // Act
            let missing = item.missingDocumentation

            // Assert
            XCTAssertTrue(missing.isEmpty)
        }
    }

    func testMissingDocumentation_IncompleteItem_ReturnsCorrectFields() async {
        await MainActor.run {
            // Arrange - 6-field scoring (Task 1.4.3)
            // Item has only value, missing everything else
            let item = Item(
                name: "Test Item",
                purchasePrice: Decimal(100),
                category: nil,
                room: nil,
                condition: .good
            )

            // Act
            let missing = item.missingDocumentation

            // Assert - should be missing 5 fields (has value only)
            XCTAssertEqual(missing.count, 5)
            XCTAssertTrue(missing.contains("Photo"))
            XCTAssertTrue(missing.contains("Room"))
            XCTAssertTrue(missing.contains("Category"))
            XCTAssertTrue(missing.contains("Receipt"))
            XCTAssertTrue(missing.contains("Serial Number"))
            XCTAssertFalse(missing.contains("Value"))  // Value is present
        }
    }

    // MARK: - Initialization Tests

    func testInitialization_DefaultValues_AreSet() async {
        await MainActor.run {
            // Arrange & Act
            let item = Item(
                name: "Test Item",
                condition: .good
            )

            // Assert
            XCTAssertEqual(item.name, "Test Item")
            XCTAssertEqual(item.condition, .good)
            XCTAssertEqual(item.currencyCode, "USD")
            XCTAssertNil(item.brand)
            XCTAssertNil(item.modelNumber)
            XCTAssertNil(item.serialNumber)
            XCTAssertTrue(item.photos.isEmpty)
            XCTAssertTrue(item.receipts.isEmpty)
            XCTAssertTrue(item.tags.isEmpty)
        }
    }

    func testInitialization_AllFields_AreSet() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let category = TestFixtures.testCategory()
            let room = TestFixtures.testRoom()
            context.insert(category)
            context.insert(room)

            let date = Date()
            let warrantyDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

            // Act
            let item = Item(
                name: "MacBook Pro",
                brand: "Apple",
                modelNumber: "M3 Max",
                serialNumber: "ABC123",
                purchasePrice: Decimal(2999),
                purchaseDate: date,
                currencyCode: "USD",
                category: category,
                room: room,
                condition: .likeNew,
                conditionNotes: "Excellent",
                warrantyExpiryDate: warrantyDate,
                tags: ["work", "laptop"]
            )
            context.insert(item)

            // Assert
            XCTAssertEqual(item.name, "MacBook Pro")
            XCTAssertEqual(item.brand, "Apple")
            XCTAssertEqual(item.modelNumber, "M3 Max")
            XCTAssertEqual(item.serialNumber, "ABC123")
            XCTAssertEqual(item.purchasePrice, Decimal(2999))
            XCTAssertEqual(item.purchaseDate, date)
            XCTAssertEqual(item.category?.name, "Test Category")
            XCTAssertEqual(item.room?.name, "Test Room")
            XCTAssertEqual(item.condition, ItemCondition.likeNew)
            XCTAssertEqual(item.tags.count, 2)
        }
    }
}

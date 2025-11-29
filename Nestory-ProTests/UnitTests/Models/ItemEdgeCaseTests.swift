//
//  ItemEdgeCaseTests.swift
//  Nestory-ProTests
//
//  Edge case and boundary tests for Item model
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class ItemEdgeCaseTests: XCTestCase {

    // MARK: - Empty/Nil Edge Cases

    @MainActor
    func testItem_EmptyName_IsAllowed() {
        // Arrange & Act
        let item = Item(name: "", condition: .good)

        // Assert - Empty names are technically allowed (UI should validate)
        XCTAssertEqual(item.name, "")
    }

    @MainActor
    func testItem_WhitespaceName_IsPreserved() {
        // Arrange & Act
        let item = Item(name: "   ", condition: .good)

        // Assert - Whitespace is preserved (UI should trim)
        XCTAssertEqual(item.name, "   ")
    }

    @MainActor
    func testItem_VeryLongName_IsAccepted() {
        // Arrange
        let longName = String(repeating: "A", count: 1000)

        // Act
        let item = Item(name: longName, condition: .good)

        // Assert
        XCTAssertEqual(item.name.count, 1000)
    }

    @MainActor
    func testItem_SpecialCharactersInName_ArePreserved() {
        // Arrange
        let specialName = "MacBook Pro 16\" (M3) – Pro™ $2,999"

        // Act
        let item = Item(name: specialName, condition: .good)

        // Assert
        XCTAssertEqual(item.name, specialName)
    }

    @MainActor
    func testItem_UnicodeEmoji_InName() {
        // Arrange
        let emojiName = "📱 iPhone 15 Pro 🔥"

        // Act
        let item = Item(name: emojiName, condition: .good)

        // Assert
        XCTAssertEqual(item.name, emojiName)
    }

    // MARK: - Decimal Edge Cases

    @MainActor
    func testItem_ZeroPrice_IsValid() {
        // Arrange & Act
        let item = TestFixtures.testItem(purchasePrice: Decimal(0))

        // Assert
        XCTAssertEqual(item.purchasePrice, Decimal(0))
        XCTAssertTrue(item.hasValue) // 0 is still a value
    }

    @MainActor
    func testItem_NegativePrice_IsAllowed() {
        // Arrange & Act (refunds, credits, etc.)
        let item = TestFixtures.testItem(purchasePrice: Decimal(-50.00))

        // Assert
        XCTAssertEqual(item.purchasePrice, Decimal(-50.00))
        XCTAssertTrue(item.hasValue)
    }

    @MainActor
    func testItem_VeryLargePrice_IsAccepted() {
        // Arrange
        let largePrice = Decimal(999_999_999.99)

        // Act
        let item = TestFixtures.testItem(purchasePrice: largePrice)

        // Assert
        XCTAssertEqual(item.purchasePrice, largePrice)
    }

    @MainActor
    func testItem_ManyDecimalPlaces_IsPreserved() {
        // Arrange
        let precisePrice = Decimal(string: "123.456789")!

        // Act
        let item = TestFixtures.testItem(purchasePrice: precisePrice)

        // Assert
        XCTAssertEqual(item.purchasePrice, precisePrice)
    }

    // MARK: - Date Edge Cases

    @MainActor
    func testItem_FuturePurchaseDate_IsAllowed() {
        // Arrange - Pre-orders, scheduled deliveries
        let futureDate = TestFixtures.testDateInFuture

        // Act
        let item = Item(
            name: "Pre-order Item",
            purchaseDate: futureDate,
            condition: .new
        )

        // Assert
        XCTAssertEqual(item.purchaseDate, futureDate)
    }

    @MainActor
    func testItem_VeryOldPurchaseDate_IsAllowed() {
        // Arrange - Antiques, heirlooms
        var components = DateComponents()
        components.year = 1900
        components.month = 1
        components.day = 1
        let veryOldDate = Calendar.current.date(from: components)!

        // Act
        let item = Item(
            name: "Antique Clock",
            purchaseDate: veryOldDate,
            condition: .fair
        )

        // Assert
        XCTAssertEqual(item.purchaseDate, veryOldDate)
    }

    @MainActor
    func testItem_WarrantyExpired_HasNoSpecialBehavior() {
        // Arrange
        let item = Item(
            name: "Expired Warranty Item",
            condition: .good,
            warrantyExpiryDate: TestFixtures.testWarrantyExpired
        )

        // Assert - Just validates storage, behavior is in views
        XCTAssertNotNil(item.warrantyExpiryDate)
        XCTAssertLessThan(item.warrantyExpiryDate!, TestFixtures.referenceDate)
    }

    // MARK: - Tags Edge Cases

    @MainActor
    func testItem_EmptyTagsArray_IsDefault() {
        // Arrange & Act
        let item = Item(name: "No Tags Item", condition: .good)

        // Assert
        XCTAssertTrue(item.tags.isEmpty)
    }

    @MainActor
    func testItem_DuplicateTags_ArePreserved() {
        // Arrange - Model doesn't enforce uniqueness
        let duplicateTags = ["work", "work", "important", "work"]

        // Act
        let item = Item(
            name: "Duplicate Tags Item",
            condition: .good,
            tags: duplicateTags
        )

        // Assert
        XCTAssertEqual(item.tags.count, 4)
        XCTAssertEqual(item.tags.filter { $0 == "work" }.count, 3)
    }

    @MainActor
    func testItem_EmptyStringTag_IsPreserved() {
        // Arrange
        let tagsWithEmpty = ["valid", "", "also-valid"]

        // Act
        let item = Item(
            name: "Empty Tag Item",
            condition: .good,
            tags: tagsWithEmpty
        )

        // Assert
        XCTAssertEqual(item.tags.count, 3)
        XCTAssertTrue(item.tags.contains(""))
    }

    @MainActor
    func testItem_ManyTags_AreAccepted() {
        // Arrange
        let manyTags = (0..<100).map { "tag-\($0)" }

        // Act
        let item = Item(
            name: "Many Tags Item",
            condition: .good,
            tags: manyTags
        )

        // Assert
        XCTAssertEqual(item.tags.count, 100)
    }

    // MARK: - Condition Edge Cases

    @MainActor
    func testItem_AllConditionValues_AreValid() {
        // Arrange & Act & Assert
        for condition in ItemCondition.allCases {
            let item = Item(name: "Condition \(condition.rawValue)", condition: condition)
            XCTAssertEqual(item.condition, condition)
            XCTAssertFalse(item.condition.displayName.isEmpty)
        }
    }

    // MARK: - Documentation Score Edge Cases

    @MainActor
    func testDocumentationScore_WithOnlyPhoto_Returns0Point30() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let item = Item(name: "Photo Only", condition: .good)
        context.insert(item)

        let photo = TestFixtures.testItemPhoto()
        photo.item = item
        context.insert(photo)

        // Act
        let score = item.documentationScore

        // Assert - 6-field weighted scoring: Photo = 30%
        XCTAssertEqual(score, 0.30, accuracy: 0.001)
    }

    @MainActor
    func testDocumentationScore_WithOnlyValue_Returns0Point25() {
        // Arrange
        let item = Item(
            name: "Value Only",
            purchasePrice: Decimal(100),
            condition: .good
        )

        // Act
        let score = item.documentationScore

        // Assert - 6-field weighted scoring: Value = 25%
        XCTAssertEqual(score, 0.25, accuracy: 0.001)
    }

    @MainActor
    func testDocumentationScore_WithOnlyCategory_Returns0Point10() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let category = TestFixtures.testCategory()
        context.insert(category)

        let item = Item(
            name: "Category Only",
            category: category,
            condition: .good
        )
        context.insert(item)

        // Act
        let score = item.documentationScore

        // Assert - 6-field weighted scoring: Category = 10%
        XCTAssertEqual(score, 0.10, accuracy: 0.001)
    }

    @MainActor
    func testDocumentationScore_WithOnlyRoom_Returns0Point15() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let room = TestFixtures.testRoom()
        context.insert(room)

        let item = Item(
            name: "Room Only",
            room: room,
            condition: .good
        )
        context.insert(item)

        // Act
        let score = item.documentationScore

        // Assert - 6-field weighted scoring: Room = 15%
        XCTAssertEqual(score, 0.15, accuracy: 0.001)
    }

    // MARK: - Missing Documentation Edge Cases

    @MainActor
    func testMissingDocumentation_TracksSixFields() {
        // Arrange - Item with only value set
        let item = Item(
            name: "Partial Documentation",
            purchasePrice: Decimal(100),
            condition: .good
        )

        // Act
        let missing = item.missingDocumentation

        // Assert - 6-field scoring tracks all fields (Task 1.4.3)
        XCTAssertEqual(missing.count, 5) // Missing: Photo, Room, Category, Receipt, Serial (has Value)
        XCTAssertTrue(missing.contains("Photo"))
        XCTAssertTrue(missing.contains("Room"))
        XCTAssertTrue(missing.contains("Category"))
        XCTAssertTrue(missing.contains("Receipt"))
        XCTAssertTrue(missing.contains("Serial Number"))
    }

    // MARK: - Currency Code Edge Cases

    @MainActor
    func testItem_DifferentCurrencyCodes_ArePreserved() {
        // Arrange
        let currencies = ["USD", "EUR", "GBP", "JPY", "CNY", "BTC"]

        for currency in currencies {
            // Act
            let item = Item(
                name: "\(currency) Item",
                purchasePrice: Decimal(100),
                currencyCode: currency,
                condition: .good
            )

            // Assert
            XCTAssertEqual(item.currencyCode, currency)
        }
    }

    @MainActor
    func testItem_InvalidCurrencyCode_IsNotValidated() {
        // Arrange - Model doesn't validate currency codes
        let invalidCurrency = "NOTREAL"

        // Act
        let item = Item(
            name: "Invalid Currency Item",
            currencyCode: invalidCurrency,
            condition: .good
        )

        // Assert - Model accepts it (validation is elsewhere)
        XCTAssertEqual(item.currencyCode, invalidCurrency)
    }

    // MARK: - UUID Edge Cases

    @MainActor
    func testItem_HasUniqueUUID_OnCreation() {
        // Arrange & Act
        let item1 = Item(name: "Item 1", condition: .good)
        let item2 = Item(name: "Item 2", condition: .good)

        // Assert
        XCTAssertNotEqual(item1.id, item2.id)
    }

    // MARK: - Timestamps Edge Cases

    @MainActor
    func testItem_CreatedAtAndUpdatedAt_AreSet() {
        // Arrange
        let beforeCreation = Date()

        // Act
        let item = Item(name: "Timestamp Test", condition: .good)

        let afterCreation = Date()

        // Assert
        XCTAssertGreaterThanOrEqual(item.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(item.createdAt, afterCreation)
        XCTAssertGreaterThanOrEqual(item.updatedAt, beforeCreation)
        XCTAssertLessThanOrEqual(item.updatedAt, afterCreation)
    }
}

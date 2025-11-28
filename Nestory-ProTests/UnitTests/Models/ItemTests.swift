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
    
    // MARK: - Documentation Score Tests
    
    @MainActor
    func testDocumentationScore_AllFieldsFilled_Returns1() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let category = TestFixtures.testCategory()
        let room = TestFixtures.testRoom()
        context.insert(category)
        context.insert(room)
        
        let item = TestFixtures.testDocumentedItem(
            category: category,
            room: room
        )
        context.insert(item)
        
        let photo = TestFixtures.testItemPhoto()
        photo.item = item
        context.insert(photo)
        
        // Act
        let score = item.documentationScore
        
        // Assert
        XCTAssertEqual(score, 1.0, accuracy: 0.001)
        XCTAssertTrue(item.isDocumented)
        XCTAssertTrue(item.missingDocumentation.isEmpty)
    }
    
    @MainActor
    func testDocumentationScore_NoFieldsFilled_Returns0() {
        // Arrange
        let item = TestFixtures.testUndocumentedItem()
        
        // Act
        let score = item.documentationScore
        
        // Assert
        XCTAssertEqual(score, 0.0)
        XCTAssertFalse(item.isDocumented)
        XCTAssertEqual(item.missingDocumentation.count, 4)
    }
    
    @MainActor
    func testDocumentationScore_HalfFieldsFilled_Returns0Point5() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let category = TestFixtures.testCategory()
        context.insert(category)
        
        let item = Item(
            name: "Test Item",
            purchasePrice: Decimal(100),
            category: category,
            room: nil,
            condition: .good
        )
        context.insert(item)
        
        // Act
        let score = item.documentationScore
        
        // Assert
        XCTAssertEqual(score, 0.5, accuracy: 0.001)
        XCTAssertFalse(item.isDocumented)
    }
    
    // MARK: - Has Photo Tests
    
    @MainActor
    func testHasPhoto_WithPhotos_ReturnsTrue() throws {
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
    
    @MainActor
    func testHasPhoto_NoPhotos_ReturnsFalse() {
        // Arrange
        let item = TestFixtures.testItem()
        
        // Act & Assert
        XCTAssertFalse(item.hasPhoto)
        XCTAssertTrue(item.photos.isEmpty)
    }
    
    // MARK: - Has Value Tests
    
    @MainActor
    func testHasValue_WithPrice_ReturnsTrue() {
        // Arrange
        let item = TestFixtures.testItem(purchasePrice: Decimal(100))
        
        // Act & Assert
        XCTAssertTrue(item.hasValue)
    }
    
    @MainActor
    func testHasValue_NoPrice_ReturnsFalse() {
        // Arrange
        let item = TestFixtures.testItem(purchasePrice: Optional<Decimal>.none)
        
        // Act & Assert
        XCTAssertFalse(item.hasValue)
    }
    
    // MARK: - Missing Documentation Tests
    
    @MainActor
    func testMissingDocumentation_CompleteItem_ReturnsEmptyArray() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let category = TestFixtures.testCategory()
        let room = TestFixtures.testRoom()
        context.insert(category)
        context.insert(room)
        
        let item = TestFixtures.testDocumentedItem(
            category: category,
            room: room
        )
        context.insert(item)
        
        let photo = TestFixtures.testItemPhoto()
        photo.item = item
        context.insert(photo)
        
        // Act
        let missing = item.missingDocumentation
        
        // Assert
        XCTAssertTrue(missing.isEmpty)
    }
    
    @MainActor
    func testMissingDocumentation_IncompleteItem_ReturnsCorrectFields() {
        // Arrange
        let item = Item(
            name: "Test Item",
            purchasePrice: Decimal(100),
            category: nil,
            room: nil,
            condition: .good
        )
        
        // Act
        let missing = item.missingDocumentation
        
        // Assert
        XCTAssertEqual(missing.count, 2)
        XCTAssertTrue(missing.contains("Photo"))
        XCTAssertTrue(missing.contains("Room"))
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testInitialization_DefaultValues_AreSet() {
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
    
    @MainActor
    func testInitialization_AllFields_AreSet() throws {
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

//
//  TestFixtures.swift
//  Nestory-ProTests
//
//  Test fixtures and helpers for unit testing
//

import Foundation
import SwiftData
@testable import Nestory_Pro

/// Test-specific fixtures with predictable data for assertions
@MainActor
struct TestFixtures {
    
    // MARK: - Test Categories
    
    static func testCategory(
        name: String = "Test Category",
        iconName: String = "tag",
        colorHex: String = "#FF0000",
        isCustom: Bool = false,
        sortOrder: Int = 0
    ) -> Nestory_Pro.Category {
        Nestory_Pro.Category(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isCustom: isCustom,
            sortOrder: sortOrder
        )
    }
    
    // MARK: - Test Rooms

    static func testRoom(
        name: String = "Test Room",
        iconName: String = "house",
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) -> Room {
        Room(
            name: name,
            iconName: iconName,
            sortOrder: sortOrder,
            isDefault: isDefault
        )
    }
    
    // MARK: - Test Items
    
    static func testItem(
        name: String = "Test Item",
        brand: String? = "Test Brand",
        modelNumber: String? = "TEST-001",
        serialNumber: String? = "SN-TEST-12345",
        purchasePrice: Decimal? = Decimal(100.00),
        purchaseDate: Date? = Date(),
        category: Nestory_Pro.Category? = nil,
        room: Room? = nil,
        condition: ItemCondition = .good,
        notes: String? = nil
    ) -> Item {
        Item(
            name: name,
            brand: brand,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            purchasePrice: purchasePrice,
            purchaseDate: purchaseDate,
            currencyCode: "USD",
            category: category,
            room: room,
            condition: condition,
            notes: notes
        )
    }
    
    /// Item with no documentation
    static func testUndocumentedItem() -> Item {
        Item(
            name: "Undocumented Item",
            brand: nil,
            modelNumber: nil,
            serialNumber: nil,
            purchasePrice: nil,
            purchaseDate: nil,
            category: nil,
            room: nil,
            condition: .good
        )
    }
    
    /// Item with complete documentation (has photo, value, category, and room)
    static func testDocumentedItem(category: Nestory_Pro.Category, room: Room) -> Item {
        let item = Item(
            name: "Fully Documented Item",
            brand: "Test Brand",
            modelNumber: "MODEL-123",
            serialNumber: "SN-123456",
            purchasePrice: Decimal(500.00),
            purchaseDate: Date(),
            category: category,
            room: room,
            condition: .likeNew
        )
        // Add photo to make item fully documented
        let photo = testItemPhoto()
        item.photos.append(photo)
        return item
    }
    
    // MARK: - Test Receipts
    
    static func testReceipt(
        vendor: String = "Test Vendor",
        total: Decimal = Decimal(99.99),
        taxAmount: Decimal? = Decimal(8.00),
        purchaseDate: Date? = Date(),
        confidence: Double = 0.95,
        linkedItem: Item? = nil
    ) -> Receipt {
        let receipt = Receipt(
            imageIdentifier: "test-receipt-\(UUID().uuidString)",
            vendor: vendor,
            total: total,
            taxAmount: taxAmount,
            purchaseDate: purchaseDate,
            rawText: "Test receipt text",
            confidence: confidence
        )
        receipt.linkedItem = linkedItem
        return receipt
    }
    
    // MARK: - Test Item Photos

    static func testItemPhoto(
        imageIdentifier: String? = nil,
        sortOrder: Int = 0,
        isPrimary: Bool = false
    ) -> ItemPhoto {
        ItemPhoto(
            imageIdentifier: imageIdentifier ?? "test-photo-\(UUID().uuidString)",
            sortOrder: sortOrder,
            isPrimary: isPrimary
        )
    }
    
    // MARK: - Test Tags (P2-05)
    
    static func testTag(
        name: String = "Test Tag",
        colorHex: String = "#007AFF",
        isFavorite: Bool = false
    ) -> Tag {
        Tag(
            name: name,
            colorHex: colorHex,
            isFavorite: isFavorite
        )
    }
    
    // MARK: - Test Dates (Deterministic)
    // These date properties are nonisolated because they only use value types
    // and don't access any MainActor-isolated state

    /// Fixed reference date for all tests: January 1, 2024 at noon UTC
    nonisolated static let referenceDate: Date = {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }()

    nonisolated static var testDateInPast: Date {
        Calendar.current.date(byAdding: .year, value: -1, to: referenceDate)!
    }

    nonisolated static var testDateInFuture: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: referenceDate)!
    }

    nonisolated static var testDateRecent: Date {
        Calendar.current.date(byAdding: .day, value: -7, to: referenceDate)!
    }

    nonisolated static var testWarrantyExpired: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: referenceDate)!
    }

    nonisolated static var testWarrantyExpiringToday: Date {
        referenceDate
    }

    nonisolated static var testWarrantyExpiringTomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: referenceDate)!
    }
}

// MARK: - Test Container

@MainActor
struct TestContainer {

    /// Creates an empty in-memory container for testing
    /// Uses NestoryModelContainer.createForTesting() for consistency with production schema
    static func empty() -> ModelContainer {
        do {
            return try NestoryModelContainer.createForTesting()
        } catch {
            fatalError("Failed to create test container: \(error.localizedDescription)")
        }
    }
    
    /// Creates container with basic test data
    static func withBasicData() -> ModelContainer {
        let container = empty()
        let context = container.mainContext
        
        // Add test category
        let category = TestFixtures.testCategory(name: "Electronics")
        context.insert(category)
        
        // Add test room
        let room = TestFixtures.testRoom(name: "Living Room")
        context.insert(room)
        
        try? context.save()
        return container
    }
    
    /// Creates container with test items
    static func withTestItems(count: Int = 5) -> ModelContainer {
        let container = withBasicData()
        let context = container.mainContext
        
        // Fetch category and room
        let categoryDescriptor = FetchDescriptor<Nestory_Pro.Category>()
        let roomDescriptor = FetchDescriptor<Room>()

        guard let category = try? context.fetch(categoryDescriptor).first,
              let room = try? context.fetch(roomDescriptor).first else {
            return container
        }
        
        // Add test items
        for i in 0..<count {
            let item = TestFixtures.testItem(
                name: "Test Item \(i + 1)",
                purchasePrice: Decimal(Double(i + 1) * 100),
                category: category,
                room: room
            )
            context.insert(item)
        }
        
        try? context.save()
        return container
    }

    /// Creates container with many items for performance testing
    static func withManyItems(count: Int) -> ModelContainer {
        let container = withBasicData()
        let context = container.mainContext

        // Fetch category and room
        let categoryDescriptor = FetchDescriptor<Nestory_Pro.Category>()
        let roomDescriptor = FetchDescriptor<Room>()

        let category = try? context.fetch(categoryDescriptor).first
        let room = try? context.fetch(roomDescriptor).first

        // Add items
        for i in 0..<count {
            let item = Item(
                name: "Item \(i + 1)",
                brand: i % 2 == 0 ? "Brand A" : "Brand B",
                purchasePrice: Decimal(Double(i + 1) * 10),
                category: i % 3 == 0 ? category : nil,
                room: i % 4 == 0 ? room : nil,
                condition: .good
            )
            context.insert(item)
        }

        try? context.save()
        return container
    }
}

// MARK: - XCTest Extensions

import XCTest

extension XCTestCase {
    /// Creates a fresh test container for each test
    @MainActor
    func createTestContainer() -> ModelContainer {
        TestContainer.empty()
    }
    
    /// Helper to fetch all items from context
    @MainActor
    func fetchAllItems(from context: ModelContext) throws -> [Item] {
        let descriptor = FetchDescriptor<Item>()
        return try context.fetch(descriptor)
    }
    
    /// Helper to fetch all categories from context
    @MainActor
    func fetchAllCategories(from context: ModelContext) throws -> [Nestory_Pro.Category] {
        let descriptor = FetchDescriptor<Nestory_Pro.Category>()
        return try context.fetch(descriptor)
    }
    
    /// Helper to fetch all rooms from context
    @MainActor
    func fetchAllRooms(from context: ModelContext) throws -> [Room] {
        let descriptor = FetchDescriptor<Room>()
        return try context.fetch(descriptor)
    }
}

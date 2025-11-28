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
    ) -> Category {
        Category(
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
        sortOrder: Int = 0
    ) -> Room {
        Room(
            name: name,
            iconName: iconName,
            sortOrder: sortOrder
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
        category: Category? = nil,
        room: Room? = nil,
        condition: ItemCondition = .good
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
            condition: condition
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
    
    /// Item with complete documentation
    static func testDocumentedItem(category: Category, room: Room) -> Item {
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
        Receipt(
            vendor: vendor,
            total: total,
            taxAmount: taxAmount,
            purchaseDate: purchaseDate,
            imageIdentifier: "test-receipt-\(UUID().uuidString)",
            rawText: "Test receipt text",
            confidence: confidence,
            linkedItem: linkedItem
        )
    }
    
    // MARK: - Test Item Photos
    
    static func testItemPhoto(
        imageIdentifier: String? = nil,
        caption: String? = nil
    ) -> ItemPhoto {
        ItemPhoto(
            imageIdentifier: imageIdentifier ?? "test-photo-\(UUID().uuidString)",
            caption: caption
        )
    }
    
    // MARK: - Test Dates
    
    static var testDateInPast: Date {
        Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    }
    
    static var testDateInFuture: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    }
    
    static var testDateRecent: Date {
        Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    }
}

// MARK: - Test Container

@MainActor
struct TestContainer {
    
    /// Creates an empty in-memory container for testing
    static func empty() -> ModelContainer {
        let schema = Schema([
            Item.self,
            ItemPhoto.self,
            Receipt.self,
            Category.self,
            Room.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create test container: \(error)")
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
        let categoryDescriptor = FetchDescriptor<Category>()
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
    func fetchAllCategories(from context: ModelContext) throws -> [Category] {
        let descriptor = FetchDescriptor<Category>()
        return try context.fetch(descriptor)
    }
    
    /// Helper to fetch all rooms from context
    @MainActor
    func fetchAllRooms(from context: ModelContext) throws -> [Room] {
        let descriptor = FetchDescriptor<Room>()
        return try context.fetch(descriptor)
    }
}

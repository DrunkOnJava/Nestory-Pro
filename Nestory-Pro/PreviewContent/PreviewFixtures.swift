//
//  PreviewFixtures.swift
//  Nestory-Pro
//
//  Sample data for SwiftUI previews and development
//

import Foundation
import SwiftData

#if DEBUG

/// Factory for creating realistic sample data for previews and testing
@MainActor
struct PreviewFixtures {
    
    // MARK: - Categories
    
    static func sampleCategories() -> [Category] {
        return Category.defaultCategories.enumerated().map { index, cat in
            Category(
                name: cat.name,
                iconName: cat.icon,
                colorHex: cat.color,
                isCustom: false,
                sortOrder: index
            )
        }
    }
    
    static func sampleElectronicsCategory() -> Category {
        Category(
            name: "Electronics",
            iconName: "tv",
            colorHex: "#007AFF",
            isCustom: false,
            sortOrder: 0
        )
    }
    
    static func sampleJewelryCategory() -> Category {
        Category(
            name: "Jewelry",
            iconName: "sparkles",
            colorHex: "#FF9500",
            isCustom: false,
            sortOrder: 1
        )
    }
    
    // MARK: - Rooms
    
    static func sampleRooms() -> [Room] {
        return Room.defaultRooms.enumerated().map { index, room in
            Room(
                name: room.name,
                iconName: room.icon,
                sortOrder: index
            )
        }
    }
    
    static func sampleLivingRoom() -> Room {
        Room(name: "Living Room", iconName: "sofa", sortOrder: 0)
    }
    
    static func sampleBedroom() -> Room {
        Room(name: "Bedroom", iconName: "bed.double", sortOrder: 1)
    }
    
    // MARK: - Items
    
    /// Complete item with all documentation
    static func sampleDocumentedItem(category: Category? = nil, room: Room? = nil) -> Item {
        let item = Item(
            name: "MacBook Pro 16-inch",
            brand: "Apple",
            modelNumber: "M3 Max 2023",
            serialNumber: "C02XJ0ABJGH5",
            purchasePrice: Decimal(2999.00),
            purchaseDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            currencyCode: "USD",
            category: category,
            room: room,
            condition: .likeNew,
            conditionNotes: "Excellent condition, no scratches. Used with protective case.",
            warrantyExpiryDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()),
            tags: ["work", "high-value", "essential"]
        )
        return item
    }
    
    /// Item missing some documentation
    static func samplePartialItem(category: Category? = nil, room: Room? = nil) -> Item {
        Item(
            name: "Samsung 65\" TV",
            brand: "Samsung",
            modelNumber: "QN65Q80A",
            serialNumber: nil,
            purchasePrice: Decimal(1499.00),
            purchaseDate: nil,
            currencyCode: "USD",
            category: category,
            room: room,
            condition: .good,
            conditionNotes: nil
        )
    }
    
    /// Item with minimal information
    static func sampleMinimalItem(category: Category? = nil, room: Room? = nil) -> Item {
        Item(
            name: "Kitchen Table",
            brand: nil,
            modelNumber: nil,
            serialNumber: nil,
            purchasePrice: nil,
            purchaseDate: nil,
            currencyCode: "USD",
            category: category,
            room: room,
            condition: .good
        )
    }
    
    /// Collection of diverse items for testing lists
    static func sampleItemCollection(categories: [Category] = [], rooms: [Room] = []) -> [Item] {
        let electronics = categories.first { $0.name == "Electronics" }
        let jewelry = categories.first { $0.name == "Jewelry" }
        let furniture = categories.first { $0.name == "Furniture" }
        
        let livingRoom = rooms.first { $0.name == "Living Room" }
        let bedroom = rooms.first { $0.name == "Bedroom" }
        let kitchen = rooms.first { $0.name == "Kitchen" }
        
        return [
            Item(
                name: "MacBook Pro 16-inch",
                brand: "Apple",
                modelNumber: "M3 Max 2023",
                serialNumber: "C02XJ0ABJGH5",
                purchasePrice: Decimal(2999.00),
                purchaseDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
                category: electronics,
                room: bedroom,
                condition: .likeNew,
                conditionNotes: "Excellent condition",
                warrantyExpiryDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()),
                tags: ["work", "high-value"]
            ),
            Item(
                name: "Samsung 65\" TV",
                brand: "Samsung",
                modelNumber: "QN65Q80A",
                purchasePrice: Decimal(1499.00),
                category: electronics,
                room: livingRoom,
                condition: .good
            ),
            Item(
                name: "Diamond Ring",
                brand: "Tiffany & Co.",
                serialNumber: "TF-12345",
                purchasePrice: Decimal(5500.00),
                purchaseDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
                category: jewelry,
                room: bedroom,
                condition: .new,
                tags: ["high-value", "insurance"]
            ),
            Item(
                name: "Leather Sofa",
                brand: "West Elm",
                modelNumber: "Harmony",
                purchasePrice: Decimal(2200.00),
                purchaseDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
                category: furniture,
                room: livingRoom,
                condition: .good
            ),
            Item(
                name: "iPhone 15 Pro",
                brand: "Apple",
                serialNumber: "FLXJ3LL/A",
                purchasePrice: Decimal(1199.00),
                purchaseDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
                category: electronics,
                room: bedroom,
                condition: .likeNew,
                warrantyExpiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
            ),
            Item(
                name: "KitchenAid Mixer",
                brand: "KitchenAid",
                modelNumber: "KSM150PSER",
                purchasePrice: Decimal(429.00),
                category: furniture,
                room: kitchen,
                condition: .good
            ),
            Item(
                name: "Dyson V15 Vacuum",
                brand: "Dyson",
                modelNumber: "V15 Detect",
                serialNumber: "DY-V15-98765",
                purchasePrice: Decimal(649.00),
                purchaseDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
                category: furniture,
                room: livingRoom,
                condition: .likeNew
            ),
            Item(
                name: "Office Chair",
                brand: "Herman Miller",
                modelNumber: "Aeron",
                purchasePrice: Decimal(1395.00),
                purchaseDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()),
                category: furniture,
                room: bedroom,
                condition: .good,
                warrantyExpiryDate: Calendar.current.date(byAdding: .year, value: 9, to: Date())
            )
        ]
    }
    
    // MARK: - Receipts
    
    static func sampleReceipt(linkedItem: Item? = nil) -> Receipt {
        Receipt(
            vendor: "Apple Store",
            total: Decimal(2999.00),
            taxAmount: Decimal(239.92),
            purchaseDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            imageIdentifier: "receipt-\(UUID().uuidString)",
            rawText: """
            Apple Store
            123 Main Street
            San Francisco, CA 94102
            
            Date: \(DateFormatter.shortDate.string(from: Date()))
            
            MacBook Pro 16-inch M3 Max
            Qty: 1                    $2,999.00
            
            Subtotal:                 $2,999.00
            Tax (8%):                   $239.92
            Total:                    $3,238.92
            
            Payment: Visa ****1234
            """,
            confidence: 0.92,
            linkedItem: linkedItem
        )
    }
    
    static func sampleReceiptWithLowConfidence() -> Receipt {
        Receipt(
            vendor: "Unknown Store",
            total: Decimal(89.99),
            purchaseDate: Date(),
            imageIdentifier: "receipt-\(UUID().uuidString)",
            rawText: "Unclear text...",
            confidence: 0.45
        )
    }
    
    // MARK: - Item Photos
    
    static func sampleItemPhotos(count: Int = 3) -> [ItemPhoto] {
        (0..<count).map { index in
            ItemPhoto(
                imageIdentifier: "photo-\(UUID().uuidString)",
                caption: index == 0 ? "Front view" : nil
            )
        }
    }
}

// MARK: - Date Formatter Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

#endif

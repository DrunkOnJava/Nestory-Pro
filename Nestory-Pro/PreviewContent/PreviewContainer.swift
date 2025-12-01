//
//  PreviewContainer.swift
//  Nestory-Pro
//
//  In-memory SwiftData container for previews and tests
//

import Foundation
import SwiftData

#if DEBUG

/// Manages in-memory SwiftData containers for previews with sample data
@MainActor
struct PreviewContainer {
    
    /// Creates an in-memory container with no data
    /// Uses versioned schema from NestoryModelContainer for consistency with production
    static func empty() -> ModelContainer {
        do {
            return try NestoryModelContainer.createForTesting()
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
    
    /// Creates an in-memory container with sample categories and rooms
    static func withBasicData() -> ModelContainer {
        let container = empty()
        let context = container.mainContext
        
        // Add categories
        let categories = PreviewFixtures.sampleCategories()
        categories.forEach { context.insert($0) }
        
        // Add rooms
        let rooms = PreviewFixtures.sampleRooms()
        rooms.forEach { context.insert($0) }
        
        try? context.save()
        return container
    }
    
    /// Creates an in-memory container with sample items, categories, and rooms
    static func withSampleData() -> ModelContainer {
        let container = empty()
        let context = container.mainContext
        
        // Add categories
        let categories = PreviewFixtures.sampleCategories()
        categories.forEach { context.insert($0) }
        
        // Add rooms
        let rooms = PreviewFixtures.sampleRooms()
        rooms.forEach { context.insert($0) }
        
        // Add items with relationships
        let items = PreviewFixtures.sampleItemCollection(categories: categories, rooms: rooms)
        items.forEach { context.insert($0) }
        
        // Add photos to first few items
        if items.count >= 2 {
            let photos1 = PreviewFixtures.sampleItemPhotos(count: 3)
            photos1.forEach { photo in
                photo.item = items[0]
                context.insert(photo)
            }
            
            let photos2 = PreviewFixtures.sampleItemPhotos(count: 1)
            photos2.forEach { photo in
                photo.item = items[1]
                context.insert(photo)
            }
        }
        
        // Add receipt to first item
        if let firstItem = items.first {
            let receipt = PreviewFixtures.sampleReceipt(linkedItem: firstItem)
            context.insert(receipt)
        }
        
        try? context.save()
        return container
    }
    
    /// Creates container with many items for stress testing
    static func withManyItems(count: Int = 50) -> ModelContainer {
        let container = empty()
        let context = container.mainContext
        
        // Add categories and rooms
        let categories = PreviewFixtures.sampleCategories()
        categories.forEach { context.insert($0) }
        
        let rooms = PreviewFixtures.sampleRooms()
        rooms.forEach { context.insert($0) }
        
        // Generate many items
        for i in 0..<count {
            let category = categories.randomElement()
            let room = rooms.randomElement()
            
            let item = Item(
                name: "Item \(i + 1)",
                brand: i % 3 == 0 ? "Brand \(i)" : nil,
                modelNumber: i % 2 == 0 ? "Model-\(i)" : nil,
                serialNumber: i % 4 == 0 ? "SN-\(UUID().uuidString.prefix(8))" : nil,
                purchasePrice: i % 2 == 0 ? Decimal(Double.random(in: 50...5000)) : nil,
                purchaseDate: i % 3 == 0 ? Date().addingTimeInterval(-Double.random(in: 0...31536000)) : nil,
                category: category,
                room: room,
                condition: ItemCondition.allCases.randomElement() ?? .good
            )
            context.insert(item)
        }
        
        try? context.save()
        return container
    }
    
    /// Creates container for empty state testing
    static func emptyInventory() -> ModelContainer {
        let container = empty()
        let context = container.mainContext
        
        // Only add categories and rooms, no items
        let categories = PreviewFixtures.sampleCategories()
        categories.forEach { context.insert($0) }
        
        let rooms = PreviewFixtures.sampleRooms()
        rooms.forEach { context.insert($0) }
        
        try? context.save()
        return container
    }
}

// MARK: - Container Extension for SwiftUI

extension ModelContainer {
    /// Helper to get main context
    @MainActor
    var context: ModelContext {
        mainContext
    }
}

#endif

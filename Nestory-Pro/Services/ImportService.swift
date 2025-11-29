//
//  ImportService.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// CLAUDE CODE AGENT: IMPORT SERVICE
// ============================================================================
// Task 6.3.1: Implements backup restore functionality
// - Parses BackupData from JSON
// - Imports categories, rooms, items, receipts into SwiftData
// - Handles conflicts (skip duplicates, merge, or replace)
// - Thread-safe with @MainActor for SwiftData operations
//
// SEE: TODO.md Task 6.3.1 | BackupService.swift | BackupData structs
// ============================================================================

import Foundation
import SwiftData
import OSLog

/// Import conflict handling strategy
enum ImportConflictStrategy: String, CaseIterable, Sendable {
    case skip = "Skip Duplicates"
    case replace = "Replace Existing"
    case merge = "Merge Data"
    
    var description: String {
        switch self {
        case .skip:
            return "Existing items will be preserved, only new items will be imported"
        case .replace:
            return "Existing items with matching IDs will be replaced with backup data"
        case .merge:
            return "New data will be added, existing items will be updated with backup values"
        }
    }
}

/// Result of an import operation
struct ImportOperationResult: Sendable {
    let categoriesCreated: Int
    let categoriesSkipped: Int
    let roomsCreated: Int
    let roomsSkipped: Int
    let itemsCreated: Int
    let itemsUpdated: Int
    let itemsSkipped: Int
    let receiptsCreated: Int
    let receiptsSkipped: Int
    let errors: [String]
    
    var totalCreated: Int { categoriesCreated + roomsCreated + itemsCreated + receiptsCreated }
    var totalSkipped: Int { categoriesSkipped + roomsSkipped + itemsSkipped + receiptsSkipped }
    var hasErrors: Bool { !errors.isEmpty }
    
    var summary: String {
        var parts: [String] = []
        if itemsCreated > 0 { parts.append("\(itemsCreated) items imported") }
        if itemsUpdated > 0 { parts.append("\(itemsUpdated) items updated") }
        if itemsSkipped > 0 { parts.append("\(itemsSkipped) items skipped") }
        if categoriesCreated > 0 { parts.append("\(categoriesCreated) categories imported") }
        if roomsCreated > 0 { parts.append("\(roomsCreated) rooms imported") }
        if receiptsCreated > 0 { parts.append("\(receiptsCreated) receipts imported") }
        return parts.isEmpty ? "No changes made" : parts.joined(separator: ", ")
    }
}

/// Service for importing backup data into SwiftData
@MainActor
final class ImportService {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "ImportService")
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Import Methods
    
    /// Imports backup data into the model context
    func importBackup(
        _ backupData: BackupData,
        into modelContext: ModelContext,
        strategy: ImportConflictStrategy = .skip
    ) throws -> ImportOperationResult {
        logger.info("Starting import with strategy: \(strategy.rawValue)")
        logger.info("Backup contains: \(backupData.items.count) items, \(backupData.categories.count) categories, \(backupData.rooms.count) rooms, \(backupData.receipts.count) receipts")
        
        var errors: [String] = []
        
        // Step 1: Import Categories
        let categoryResult = try importCategories(backupData.categories, into: modelContext, strategy: strategy)
        
        // Step 2: Import Rooms
        let roomResult = try importRooms(backupData.rooms, into: modelContext, strategy: strategy)
        
        // Step 3: Fetch category and room maps for item relationships
        let categoryMap = try fetchCategoryMap(modelContext)
        let roomMap = try fetchRoomMap(modelContext)
        
        // Step 4: Import Items
        let itemResult = try importItems(
            backupData.items,
            into: modelContext,
            categoryMap: categoryMap,
            roomMap: roomMap,
            strategy: strategy
        )
        
        // Step 5: Fetch item map for receipt relationships
        let itemMap = try fetchItemMap(modelContext)
        
        // Step 6: Import Receipts
        let receiptResult = try importReceipts(
            backupData.receipts,
            into: modelContext,
            itemMap: itemMap,
            strategy: strategy
        )
        
        // Save changes
        do {
            try modelContext.save()
            logger.info("Import saved successfully")
        } catch {
            logger.error("Failed to save import: \(error.localizedDescription)")
            errors.append("Save failed: \(error.localizedDescription)")
        }
        
        return ImportOperationResult(
            categoriesCreated: categoryResult.created,
            categoriesSkipped: categoryResult.skipped,
            roomsCreated: roomResult.created,
            roomsSkipped: roomResult.skipped,
            itemsCreated: itemResult.created,
            itemsUpdated: itemResult.updated,
            itemsSkipped: itemResult.skipped,
            receiptsCreated: receiptResult.created,
            receiptsSkipped: receiptResult.skipped,
            errors: errors
        )
    }
    
    // MARK: - Private Import Methods
    
    private struct CountResult {
        let created: Int
        let skipped: Int
        let updated: Int
        
        init(created: Int = 0, skipped: Int = 0, updated: Int = 0) {
            self.created = created
            self.skipped = skipped
            self.updated = updated
        }
    }
    
    private func importCategories(
        _ exports: [CategoryExport],
        into context: ModelContext,
        strategy: ImportConflictStrategy
    ) throws -> CountResult {
        var created = 0
        var skipped = 0
        
        let descriptor = FetchDescriptor<Category>()
        let existing = try context.fetch(descriptor)
        let existingNames = Set(existing.map { $0.name.lowercased() })
        
        for export in exports {
            if existingNames.contains(export.name.lowercased()) {
                skipped += 1
                continue
            }
            
            let category = Category(
                name: export.name,
                iconName: export.iconName,
                colorHex: export.colorHex,
                isCustom: export.isCustom,
                sortOrder: export.sortOrder
            )
            context.insert(category)
            created += 1
        }
        
        logger.debug("Categories: \(created) created, \(skipped) skipped")
        return CountResult(created: created, skipped: skipped)
    }
    
    private func importRooms(
        _ exports: [RoomExport],
        into context: ModelContext,
        strategy: ImportConflictStrategy
    ) throws -> CountResult {
        var created = 0
        var skipped = 0
        
        let descriptor = FetchDescriptor<Room>()
        let existing = try context.fetch(descriptor)
        let existingNames = Set(existing.map { $0.name.lowercased() })
        
        for export in exports {
            if existingNames.contains(export.name.lowercased()) {
                skipped += 1
                continue
            }
            
            let room = Room(
                name: export.name,
                iconName: export.iconName,
                sortOrder: export.sortOrder,
                isDefault: export.isDefault
            )
            context.insert(room)
            created += 1
        }
        
        logger.debug("Rooms: \(created) created, \(skipped) skipped")
        return CountResult(created: created, skipped: skipped)
    }
    
    private func importItems(
        _ exports: [ItemExport],
        into context: ModelContext,
        categoryMap: [String: Category],
        roomMap: [String: Room],
        strategy: ImportConflictStrategy
    ) throws -> CountResult {
        var created = 0
        var updated = 0
        var skipped = 0
        
        let descriptor = FetchDescriptor<Item>()
        let existing = try context.fetch(descriptor)
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        
        for export in exports {
            if let existingItem = existingById[export.id] {
                switch strategy {
                case .skip:
                    skipped += 1
                    continue
                case .replace, .merge:
                    updateItem(existingItem, from: export, categoryMap: categoryMap, roomMap: roomMap)
                    updated += 1
                }
            } else {
                let item = createItem(from: export, categoryMap: categoryMap, roomMap: roomMap)
                context.insert(item)
                created += 1
            }
        }
        
        logger.debug("Items: \(created) created, \(updated) updated, \(skipped) skipped")
        return CountResult(created: created, skipped: skipped, updated: updated)
    }
    
    private func importReceipts(
        _ exports: [ReceiptExport],
        into context: ModelContext,
        itemMap: [UUID: Item],
        strategy: ImportConflictStrategy
    ) throws -> CountResult {
        var created = 0
        var skipped = 0
        
        let descriptor = FetchDescriptor<Receipt>()
        let existing = try context.fetch(descriptor)
        let existingById = Set(existing.map { $0.id })
        
        for export in exports {
            if existingById.contains(export.id) {
                skipped += 1
                continue
            }
            
            let receipt = Receipt(
                imageIdentifier: export.imageIdentifier,
                vendor: export.vendor,
                total: export.total,
                taxAmount: export.taxAmount,
                purchaseDate: export.purchaseDate,
                rawText: export.rawText,
                confidence: export.confidence
            )
            
            if let linkedItemId = export.linkedItemId, let item = itemMap[linkedItemId] {
                receipt.linkedItem = item
            }
            
            context.insert(receipt)
            created += 1
        }
        
        logger.debug("Receipts: \(created) created, \(skipped) skipped")
        return CountResult(created: created, skipped: skipped)
    }
    
    // MARK: - Helper Methods
    
    private func fetchCategoryMap(_ context: ModelContext) throws -> [String: Category] {
        let descriptor = FetchDescriptor<Category>()
        let categories = try context.fetch(descriptor)
        return Dictionary(uniqueKeysWithValues: categories.map { ($0.name.lowercased(), $0) })
    }
    
    private func fetchRoomMap(_ context: ModelContext) throws -> [String: Room] {
        let descriptor = FetchDescriptor<Room>()
        let rooms = try context.fetch(descriptor)
        return Dictionary(uniqueKeysWithValues: rooms.map { ($0.name.lowercased(), $0) })
    }
    
    private func fetchItemMap(_ context: ModelContext) throws -> [UUID: Item] {
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        return Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }
    
    private func createItem(
        from export: ItemExport,
        categoryMap: [String: Category],
        roomMap: [String: Room]
    ) -> Item {
        let category = export.categoryName.flatMap { categoryMap[$0.lowercased()] }
        let room = export.roomName.flatMap { roomMap[$0.lowercased()] }
        
        let item = Item(
            name: export.name,
            brand: export.brand,
            modelNumber: export.modelNumber,
            serialNumber: export.serialNumber,
            purchasePrice: export.purchasePrice,
            purchaseDate: export.purchaseDate,
            category: category,
            room: room,
            condition: ItemCondition(rawValue: export.condition) ?? .good
        )
        
        item.currencyCode = export.currencyCode
        item.conditionNotes = export.conditionNotes
        item.notes = export.notes
        item.barcode = export.barcode
        item.warrantyExpiryDate = export.warrantyExpiryDate
        item.tags = export.tags
        item.createdAt = export.createdAt
        item.updatedAt = export.updatedAt
        
        return item
    }
    
    private func updateItem(
        _ item: Item,
        from export: ItemExport,
        categoryMap: [String: Category],
        roomMap: [String: Room]
    ) {
        item.name = export.name
        item.brand = export.brand
        item.modelNumber = export.modelNumber
        item.serialNumber = export.serialNumber
        item.purchasePrice = export.purchasePrice
        item.purchaseDate = export.purchaseDate
        item.currencyCode = export.currencyCode
        item.condition = ItemCondition(rawValue: export.condition) ?? item.condition
        item.conditionNotes = export.conditionNotes
        item.notes = export.notes
        item.barcode = export.barcode
        item.warrantyExpiryDate = export.warrantyExpiryDate
        item.tags = export.tags
        item.updatedAt = Date()
        
        if let categoryName = export.categoryName {
            item.category = categoryMap[categoryName.lowercased()]
        }
        if let roomName = export.roomName {
            item.room = roomMap[roomName.lowercased()]
        }
    }
}

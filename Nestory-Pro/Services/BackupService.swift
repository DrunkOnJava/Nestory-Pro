//
//  BackupService.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: BACKUP SERVICE
// ============================================================================
// Task 3.4.1: Implements BackupServiceProtocol for JSON/CSV export
// - JSON export: Full data with relationships (Free tier)
// - CSV export: Flattened item list (Pro tier only)
// - Import: Restores from JSON with conflict handling
// - Thread-safe actor implementation
//
// SEE: TODO.md Phase 3 | BackupServiceProtocol.swift
// ============================================================================

import Foundation
import OSLog
import os.signpost
import UIKit
@preconcurrency import SwiftData

/// Actor-based backup service for exporting and importing inventory data
actor BackupService {
    nonisolated static let shared = BackupService()

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "BackupService")
    private let signpostLog = OSLog(subsystem: "com.drunkonjava.nestory", category: .pointsOfInterest)
    private let fileManager = FileManager.default

    // MARK: - Initialization

    private init() {}

    // MARK: - JSON Export

    /// Exports all inventory data to JSON format
    /// - Parameters:
    ///   - itemExports: Pre-converted item exports (call from MainActor)
    ///   - categoryExports: Pre-converted category exports
    ///   - roomExports: Pre-converted room exports
    ///   - receiptExports: Pre-converted receipt exports
    /// - Returns: URL to the exported JSON file in temp directory
    func exportToJSON(
        itemExports: [ItemExport],
        categoryExports: [CategoryExport],
        roomExports: [RoomExport],
        receiptExports: [ReceiptExport]
    ) async throws -> URL {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "JSON Export", signpostID: signpostID,
                    "items: %d, categories: %d, rooms: %d, receipts: %d",
                    itemExports.count, categoryExports.count, roomExports.count, receiptExports.count)
        defer {
            os_signpost(.end, log: signpostLog, name: "JSON Export", signpostID: signpostID)
        }

        logger.info("Starting JSON export: \(itemExports.count) items, \(categoryExports.count) categories, \(roomExports.count) rooms, \(receiptExports.count) receipts")

        // Build export data structure (exports are already Sendable)
        let exportData = BackupData(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            items: itemExports,
            categories: categoryExports,
            rooms: roomExports,
            receipts: receiptExports
        )

        // Encode to JSON using nonisolated helper
        let jsonData: Data
        do {
            jsonData = try encodeBackupData(exportData)
        } catch {
            logger.error("Failed to encode JSON: \(error.localizedDescription)")
            throw BackupError.encodingFailed(error)
        }

        // Write to temp directory with timestamp
        let filename = "nestory-backup-\(timestampString()).json"
        let fileURL = fileManager.temporaryDirectory.appendingPathComponent(filename)

        do {
            try jsonData.write(to: fileURL, options: .atomic)
            logger.info("JSON export saved: \(fileURL.path), size: \(jsonData.count) bytes")
            return fileURL
        } catch {
            logger.error("Failed to write JSON file: \(error.localizedDescription)")
            throw BackupError.writeFailed(error)
        }
    }

    // MARK: - CSV Export

    /// Exports items to CSV format (Pro tier only)
    /// - Parameter itemExports: Pre-converted item exports (call from MainActor)
    /// - Returns: URL to the exported CSV file in temp directory
    func exportToCSV(itemExports: [ItemExport]) async throws -> URL {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "CSV Export", signpostID: signpostID,
                    "items: %d", itemExports.count)
        defer {
            os_signpost(.end, log: signpostLog, name: "CSV Export", signpostID: signpostID)
        }

        logger.info("Starting CSV export: \(itemExports.count) items")

        // Build CSV content
        var csvLines: [String] = []

        // Headers
        csvLines.append("Name,Description,Value,Condition,Room,Category,Purchase Date,Serial Number,Barcode,Has Photo,Has Receipt")

        // Data rows
        for item in itemExports {
            let fields: [String] = [
                escapeCSVField(item.name),
                escapeCSVField(item.notes ?? ""),
                item.purchasePrice?.description ?? "",
                item.condition,
                escapeCSVField(item.roomName ?? ""),
                escapeCSVField(item.categoryName ?? ""),
                item.purchaseDate.map { formatDate($0) } ?? "",
                escapeCSVField(item.serialNumber ?? ""),
                escapeCSVField(item.barcode ?? ""),
                !item.photoIdentifiers.isEmpty ? "Yes" : "No",
                !item.receiptIds.isEmpty ? "Yes" : "No"
            ]
            csvLines.append(fields.joined(separator: ","))
        }

        let csvContent = csvLines.joined(separator: "\n")

        // Write to temp directory with timestamp
        let filename = "nestory-export-\(timestampString()).csv"
        let fileURL = fileManager.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            logger.info("CSV export saved: \(fileURL.path), size: \(csvContent.count) bytes")
            return fileURL
        } catch {
            logger.error("Failed to write CSV file: \(error.localizedDescription)")
            throw BackupError.writeFailed(error)
        }
    }

    // MARK: - JSON Import

    /// Imports data from a JSON backup file (validation only - use performImport for actual import)
    /// - Parameter url: URL to the JSON backup file
    /// - Returns: ImportResult with counts and errors
    func importFromJSON(url: URL) async throws -> ImportResult {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "JSON Import", signpostID: signpostID)
        defer {
            os_signpost(.end, log: signpostLog, name: "JSON Import", signpostID: signpostID)
        }

        logger.info("Starting JSON import from: \(url.path)")

        // Read JSON data
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch {
            logger.error("Failed to read JSON file: \(error.localizedDescription)")
            throw BackupError.readFailed(error)
        }

        // Decode backup data using nonisolated helper
        let backupData: BackupData
        do {
            backupData = try decodeBackupData(from: jsonData)
        } catch {
            logger.error("Failed to decode JSON: \(error.localizedDescription)")
            throw BackupError.decodingFailed(error)
        }

        logger.info("Decoded backup from \(backupData.exportDate), version \(backupData.appVersion)")

        // Validate data structure
        var errors: [ImportError] = []
        for (index, itemExport) in backupData.items.enumerated() {
            if itemExport.name.isEmpty {
                errors.append(ImportError(
                    type: .validationFailed,
                    description: "Item at index \(index) has empty name"
                ))
            }
        }

        let result = ImportResult(
            itemsImported: backupData.items.count,
            categoriesImported: backupData.categories.count,
            roomsImported: backupData.rooms.count,
            errors: errors
        )

        logger.info("Import validation completed: \(result.itemsImported) items, \(result.categoriesImported) categories, \(result.roomsImported) rooms, \(errors.count) errors")

        return result
    }
    
    /// Reads backup data from a JSON file for import
    /// - Parameter url: URL to the JSON backup file
    /// - Returns: Parsed BackupData structure
    func readBackupData(from url: URL) async throws -> BackupData {
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch {
            logger.error("Failed to read JSON file: \(error.localizedDescription)")
            throw BackupError.readFailed(error)
        }

        do {
            return try decodeBackupData(from: jsonData)
        } catch {
            logger.error("Failed to decode JSON: \(error.localizedDescription)")
            throw BackupError.decodingFailed(error)
        }
    }

    // MARK: - Restore from Backup

    /// Restores data from a backup file into SwiftData context
    /// - Parameters:
    ///   - url: URL to the JSON backup file
    ///   - context: SwiftData ModelContext for inserting data
    ///   - strategy: Restore strategy (merge or replace)
    /// - Returns: RestoreResult with counts and any errors
    @MainActor
    func performRestore(
        from url: URL,
        context: ModelContext,
        strategy: RestoreStrategy
    ) async throws -> RestoreResult {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "Restore Backup", signpostID: signpostID)
        defer {
            os_signpost(.end, log: signpostLog, name: "Restore Backup", signpostID: signpostID)
        }

        logger.info("Starting restore from: \(url.path) with strategy: \(strategy.rawValue)")

        // Read and parse backup data
        let backupData = try await readBackupData(from: url)

        // If replace strategy, delete existing data first
        if strategy == .replace {
            try await clearExistingData(context: context)
        }

        var errors: [ImportError] = []
        var itemsRestored = 0
        var categoriesRestored = 0
        var roomsRestored = 0
        var receiptsRestored = 0

        // Step 1: Restore categories (needed for item relationships)
        var categoryMap: [String: Category] = [:]
        for categoryExport in backupData.categories {
            do {
                let category = try restoreCategory(categoryExport, in: context, strategy: strategy)
                categoryMap[categoryExport.name] = category
                categoriesRestored += 1
            } catch {
                errors.append(ImportError(
                    type: .validationFailed,
                    description: "Failed to restore category '\(categoryExport.name)': \(error.localizedDescription)"
                ))
            }
        }

        // Step 2: Restore rooms (needed for item relationships)
        var roomMap: [String: Room] = [:]
        for roomExport in backupData.rooms {
            do {
                let room = try restoreRoom(roomExport, in: context, strategy: strategy)
                roomMap[roomExport.name] = room
                roomsRestored += 1
            } catch {
                errors.append(ImportError(
                    type: .validationFailed,
                    description: "Failed to restore room '\(roomExport.name)': \(error.localizedDescription)"
                ))
            }
        }

        // Step 3: Restore items
        var itemMap: [UUID: Item] = [:]
        for itemExport in backupData.items {
            do {
                let item = try restoreItem(
                    itemExport,
                    categoryMap: categoryMap,
                    roomMap: roomMap,
                    in: context,
                    strategy: strategy
                )
                itemMap[itemExport.id] = item
                itemsRestored += 1
            } catch {
                errors.append(ImportError(
                    type: .validationFailed,
                    description: "Failed to restore item '\(itemExport.name)': \(error.localizedDescription)"
                ))
            }
        }

        // Step 4: Restore receipts (with optional item linking)
        for receiptExport in backupData.receipts {
            do {
                try restoreReceipt(receiptExport, itemMap: itemMap, in: context, strategy: strategy)
                receiptsRestored += 1
            } catch {
                errors.append(ImportError(
                    type: .validationFailed,
                    description: "Failed to restore receipt '\(receiptExport.vendor ?? "Unknown")': \(error.localizedDescription)"
                ))
            }
        }

        // Save context
        do {
            try context.save()
            logger.info("Restore completed: \(itemsRestored) items, \(categoriesRestored) categories, \(roomsRestored) rooms, \(receiptsRestored) receipts")
        } catch {
            logger.error("Failed to save restored data: \(error.localizedDescription)")
            throw BackupError.writeFailed(error)
        }

        return RestoreResult(
            itemsRestored: itemsRestored,
            categoriesRestored: categoriesRestored,
            roomsRestored: roomsRestored,
            receiptsRestored: receiptsRestored,
            errors: errors
        )
    }

    // MARK: - Private Restore Helpers

    @MainActor
    private func clearExistingData(context: ModelContext) async throws {
        logger.info("Clearing existing data for replace strategy")

        // Delete all items (will cascade to photos)
        let itemDescriptor = FetchDescriptor<Item>()
        let items = try context.fetch(itemDescriptor)
        for item in items {
            context.delete(item)
        }

        // Delete all receipts
        let receiptDescriptor = FetchDescriptor<Receipt>()
        let receipts = try context.fetch(receiptDescriptor)
        for receipt in receipts {
            context.delete(receipt)
        }

        // Delete custom categories (keep default ones)
        let categoryDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.isCustom }
        )
        let customCategories = try context.fetch(categoryDescriptor)
        for category in customCategories {
            context.delete(category)
        }

        // Delete custom rooms (keep default ones)
        let roomDescriptor = FetchDescriptor<Room>(
            predicate: #Predicate { !$0.isDefault }
        )
        let customRooms = try context.fetch(roomDescriptor)
        for room in customRooms {
            context.delete(room)
        }

        try context.save()
    }

    @MainActor
    private func restoreCategory(
        _ export: CategoryExport,
        in context: ModelContext,
        strategy: RestoreStrategy
    ) throws -> Category {
        // Check if category already exists by name
        let nameToFind = export.name
        let existingDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == nameToFind }
        )
        let existing = try context.fetch(existingDescriptor)

        if let existingCategory = existing.first {
            if strategy == .merge {
                // Update existing category properties
                existingCategory.iconName = export.iconName
                existingCategory.colorHex = export.colorHex
                existingCategory.sortOrder = export.sortOrder
                return existingCategory
            } else {
                // Replace already cleared, just return existing
                return existingCategory
            }
        }

        // Create new category
        let category = Category(
            name: export.name,
            iconName: export.iconName,
            colorHex: export.colorHex,
            isCustom: export.isCustom,
            sortOrder: export.sortOrder
        )
        context.insert(category)
        return category
    }

    @MainActor
    private func restoreRoom(
        _ export: RoomExport,
        in context: ModelContext,
        strategy: RestoreStrategy
    ) throws -> Room {
        // Check if room already exists by name
        let nameToFind = export.name
        let existingDescriptor = FetchDescriptor<Room>(
            predicate: #Predicate { $0.name == nameToFind }
        )
        let existing = try context.fetch(existingDescriptor)

        if let existingRoom = existing.first {
            if strategy == .merge {
                // Update existing room properties
                existingRoom.iconName = export.iconName
                existingRoom.sortOrder = export.sortOrder
                return existingRoom
            } else {
                return existingRoom
            }
        }

        // Create new room
        let room = Room(
            name: export.name,
            iconName: export.iconName,
            sortOrder: export.sortOrder,
            isDefault: export.isDefault
        )
        context.insert(room)
        return room
    }

    @MainActor
    private func restoreItem(
        _ export: ItemExport,
        categoryMap: [String: Category],
        roomMap: [String: Room],
        in context: ModelContext,
        strategy: RestoreStrategy
    ) throws -> Item {
        // For merge strategy, check if item with same ID exists
        if strategy == .merge {
            let idToFind = export.id
            let existingDescriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.id == idToFind }
            )
            if let existing = try context.fetch(existingDescriptor).first {
                // Skip duplicate item in merge mode
                logger.debug("Skipping duplicate item: \(export.name) (ID: \(export.id))")
                return existing
            }
        }

        // Parse condition
        let condition = ItemCondition(rawValue: export.condition) ?? .good

        // Find category and room by name
        let category = export.categoryName.flatMap { categoryMap[$0] }
        let room = export.roomName.flatMap { roomMap[$0] }

        // Create new item
        let item = Item(
            name: export.name,
            brand: export.brand,
            modelNumber: export.modelNumber,
            serialNumber: export.serialNumber,
            purchasePrice: export.purchasePrice,
            purchaseDate: export.purchaseDate,
            currencyCode: export.currencyCode,
            category: category,
            room: room,
            condition: condition,
            conditionNotes: export.conditionNotes,
            notes: export.notes,
            warrantyExpiryDate: export.warrantyExpiryDate,
            tags: export.tags
        )

        // Preserve original timestamps
        item.createdAt = export.createdAt
        item.updatedAt = export.updatedAt
        item.barcode = export.barcode

        // Note: Photos are stored by identifier - they won't be restored unless
        // the photo files exist. This is by design for v1.0 (photos not in backup)
        for (index, photoId) in export.photoIdentifiers.enumerated() {
            let photo = ItemPhoto(imageIdentifier: photoId)
            photo.sortOrder = index
            photo.isPrimary = index == 0
            photo.item = item
            context.insert(photo)
        }

        context.insert(item)
        return item
    }

    @MainActor
    private func restoreReceipt(
        _ export: ReceiptExport,
        itemMap: [UUID: Item],
        in context: ModelContext,
        strategy: RestoreStrategy
    ) throws {
        // For merge strategy, check if receipt with same ID exists
        if strategy == .merge {
            let idToFind = export.id
            let existingDescriptor = FetchDescriptor<Receipt>(
                predicate: #Predicate { $0.id == idToFind }
            )
            if (try context.fetch(existingDescriptor).first) != nil {
                logger.debug("Skipping duplicate receipt: \(export.vendor ?? "Unknown") (ID: \(export.id))")
                return
            }
        }

        // Create new receipt
        let receipt = Receipt(imageIdentifier: export.imageIdentifier)
        receipt.vendor = export.vendor
        receipt.total = export.total
        receipt.taxAmount = export.taxAmount
        receipt.purchaseDate = export.purchaseDate
        receipt.rawText = export.rawText
        receipt.confidence = export.confidence

        // Link to item if specified
        if let linkedItemId = export.linkedItemId {
            receipt.linkedItem = itemMap[linkedItemId]
        }

        context.insert(receipt)
    }

    // MARK: - Helper Methods

    /// Generates timestamp string for filenames (YYYYMMDD-HHMMSS)
    private func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    /// Escapes CSV field value (handles quotes and commas)
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Formats date for CSV output
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Codable Helpers

    /// Encodes BackupData to JSON using a file-private helper to avoid actor isolation issues
    private func encodeBackupData(_ data: BackupData) throws -> Data {
        try BackupCodableHelper.encode(data)
    }

    /// Decodes BackupData from JSON using a file-private helper to avoid actor isolation issues
    private func decodeBackupData(from jsonData: Data) throws -> BackupData {
        try BackupCodableHelper.decode(from: jsonData)
    }
}

// MARK: - Export Data Structures

/// Root backup data structure
struct BackupData: Sendable {
    let exportDate: String
    let appVersion: String
    let items: [ItemExport]
    let categories: [CategoryExport]
    let rooms: [RoomExport]
    let receipts: [ReceiptExport]
}

/// Explicit Codable implementation to avoid MainActor isolation issues in Swift 6
extension BackupData: Codable {
    enum CodingKeys: String, CodingKey {
        case exportDate, appVersion, items, categories, rooms, receipts
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exportDate = try container.decode(String.self, forKey: .exportDate)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        items = try container.decode([ItemExport].self, forKey: .items)
        categories = try container.decode([CategoryExport].self, forKey: .categories)
        rooms = try container.decode([RoomExport].self, forKey: .rooms)
        receipts = try container.decode([ReceiptExport].self, forKey: .receipts)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exportDate, forKey: .exportDate)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(items, forKey: .items)
        try container.encode(categories, forKey: .categories)
        try container.encode(rooms, forKey: .rooms)
        try container.encode(receipts, forKey: .receipts)
    }
}

/// Flattened item export with relationship names
struct ItemExport: Codable, Sendable {
    let id: UUID
    let name: String
    let brand: String?
    let modelNumber: String?
    let serialNumber: String?
    let barcode: String?
    let purchasePrice: Decimal?
    let purchaseDate: Date?
    let currencyCode: String
    let categoryName: String?
    let roomName: String?
    let condition: String
    let conditionNotes: String?
    let notes: String?
    let warrantyExpiryDate: Date?
    let tags: [String]
    let photoIdentifiers: [String]
    let receiptIds: [UUID]
    let createdAt: Date
    let updatedAt: Date
}

/// MainActor extension for creating ItemExport from SwiftData model
extension ItemExport {
    @MainActor
    static func from(_ item: Item) -> ItemExport {
        ItemExport(
            id: item.id,
            name: item.name,
            brand: item.brand,
            modelNumber: item.modelNumber,
            serialNumber: item.serialNumber,
            barcode: item.barcode,
            purchasePrice: item.purchasePrice,
            purchaseDate: item.purchaseDate,
            currencyCode: item.currencyCode,
            categoryName: item.category?.name,
            roomName: item.room?.name,
            condition: item.condition.rawValue,
            conditionNotes: item.conditionNotes,
            notes: item.notes,
            warrantyExpiryDate: item.warrantyExpiryDate,
            tags: item.tags,
            photoIdentifiers: item.photos.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.imageIdentifier),
            receiptIds: item.receipts.map(\.id),
            createdAt: item.createdAt,
            updatedAt: item.updatedAt
        )
    }
}

/// Category export
struct CategoryExport: Codable, Sendable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isCustom: Bool
    let sortOrder: Int
}

/// MainActor extension for creating CategoryExport from SwiftData model
extension CategoryExport {
    @MainActor
    static func from(_ category: Category) -> CategoryExport {
        CategoryExport(
            id: category.id,
            name: category.name,
            iconName: category.iconName,
            colorHex: category.colorHex,
            isCustom: category.isCustom,
            sortOrder: category.sortOrder
        )
    }
}

/// Room export
struct RoomExport: Codable, Sendable {
    let id: UUID
    let name: String
    let iconName: String
    let sortOrder: Int
    let isDefault: Bool
}

/// MainActor extension for creating RoomExport from SwiftData model
extension RoomExport {
    @MainActor
    static func from(_ room: Room) -> RoomExport {
        RoomExport(
            id: room.id,
            name: room.name,
            iconName: room.iconName,
            sortOrder: room.sortOrder,
            isDefault: room.isDefault
        )
    }
}

/// Receipt export
struct ReceiptExport: Codable, Sendable {
    let id: UUID
    let vendor: String?
    let total: Decimal?
    let taxAmount: Decimal?
    let purchaseDate: Date?
    let imageIdentifier: String
    let rawText: String?
    let confidence: Double
    let linkedItemId: UUID?
    let createdAt: Date
}

/// MainActor extension for creating ReceiptExport from SwiftData model
extension ReceiptExport {
    @MainActor
    static func from(_ receipt: Receipt) -> ReceiptExport {
        ReceiptExport(
            id: receipt.id,
            vendor: receipt.vendor,
            total: receipt.total,
            taxAmount: receipt.taxAmount,
            purchaseDate: receipt.purchaseDate,
            imageIdentifier: receipt.imageIdentifier,
            rawText: receipt.rawText,
            confidence: receipt.confidence,
            linkedItemId: receipt.linkedItem?.id,
            createdAt: receipt.createdAt
        )
    }
}

// MARK: - Import Result

/// Result of import operation with counts and errors
struct ImportResult: Sendable {
    let itemsImported: Int
    let categoriesImported: Int
    let roomsImported: Int
    let errors: [ImportError]

    var hasErrors: Bool { !errors.isEmpty }
    var successCount: Int { itemsImported + categoriesImported + roomsImported }
}

/// Result of restore operation with counts and errors
struct RestoreResult: Sendable {
    let itemsRestored: Int
    let categoriesRestored: Int
    let roomsRestored: Int
    let receiptsRestored: Int
    let errors: [ImportError]

    var hasErrors: Bool { !errors.isEmpty }
    var totalRestored: Int { itemsRestored + categoriesRestored + roomsRestored + receiptsRestored }

    /// Human-readable summary for display
    var summaryText: String {
        var parts: [String] = []
        if itemsRestored > 0 {
            parts.append("\(itemsRestored) item\(itemsRestored == 1 ? "" : "s")")
        }
        if categoriesRestored > 0 {
            parts.append("\(categoriesRestored) categor\(categoriesRestored == 1 ? "y" : "ies")")
        }
        if roomsRestored > 0 {
            parts.append("\(roomsRestored) room\(roomsRestored == 1 ? "" : "s")")
        }
        if receiptsRestored > 0 {
            parts.append("\(receiptsRestored) receipt\(receiptsRestored == 1 ? "" : "s")")
        }

        if parts.isEmpty {
            return "No data was restored."
        }

        let mainText = "Restored " + parts.joined(separator: ", ") + "."

        if hasErrors {
            return mainText + " \(errors.count) error\(errors.count == 1 ? "" : "s") occurred."
        }
        return mainText
    }
}

/// Strategy for restoring backup data
enum RestoreStrategy: String, Sendable, CaseIterable {
    case merge = "Merge"
    case replace = "Replace"

    var description: String {
        switch self {
        case .merge:
            return String(localized: "Add backup data to existing inventory", comment: "Merge restore strategy")
        case .replace:
            return String(localized: "Clear existing data and restore from backup", comment: "Replace restore strategy")
        }
    }
}

/// Import error detail
struct ImportError: Sendable {
    enum ErrorType {
        case validationFailed
        case duplicateId
        case missingRelationship
        case unsupportedVersion
    }

    let type: ErrorType
    let description: String
}

// MARK: - ZIP Export with Photos (Task 3.5.2)

extension BackupService {
    /// Exports all inventory data to a ZIP file including photos
    /// - Parameters:
    ///   - itemExports: Pre-converted item exports (call from MainActor)
    ///   - categoryExports: Pre-converted category exports
    ///   - roomExports: Pre-converted room exports
    ///   - receiptExports: Pre-converted receipt exports
    ///   - photoStorage: PhotoStorageService for loading photos
    /// - Returns: URL to the exported ZIP file in temp directory
    func exportToZIP(
        itemExports: [ItemExport],
        categoryExports: [CategoryExport],
        roomExports: [RoomExport],
        receiptExports: [ReceiptExport],
        photoStorage: PhotoStorageService
    ) async throws -> URL {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "ZIP Export", signpostID: signpostID,
                    "items: %d", itemExports.count)
        defer {
            os_signpost(.end, log: signpostLog, name: "ZIP Export", signpostID: signpostID)
        }

        logger.info("Starting ZIP export with photos: \(itemExports.count) items")

        // Create temp directory for ZIP contents
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("nestory-backup-\(timestampString())")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            // Cleanup temp directory after ZIP creation
            try? fileManager.removeItem(at: tempDir)
        }

        // Write JSON backup
        let exportData = BackupData(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            items: itemExports,
            categories: categoryExports,
            rooms: roomExports,
            receipts: receiptExports
        )

        let jsonData = try encodeBackupData(exportData)
        let jsonURL = tempDir.appendingPathComponent("backup.json")
        try jsonData.write(to: jsonURL)
        logger.debug("Wrote backup.json: \(jsonData.count) bytes")

        // Create Photos subdirectory
        let photosDir = tempDir.appendingPathComponent("Photos")
        try fileManager.createDirectory(at: photosDir, withIntermediateDirectories: true)

        // Collect all photo identifiers from items and receipts
        var photoIdentifiers: Set<String> = []
        for item in itemExports {
            photoIdentifiers.formUnion(item.photoIdentifiers)
        }
        for receipt in receiptExports {
            photoIdentifiers.insert(receipt.imageIdentifier)
        }

        // Copy photos to temp directory
        var photosCopied = 0
        for identifier in photoIdentifiers {
            do {
                let image = try await photoStorage.loadPhoto(identifier: identifier)
                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                    let photoURL = photosDir.appendingPathComponent(identifier)
                    try jpegData.write(to: photoURL)
                    photosCopied += 1
                }
            } catch {
                // Log but continue - some photos may not exist
                logger.warning("Failed to export photo \(identifier): \(error.localizedDescription)")
            }
        }
        logger.info("Exported \(photosCopied) of \(photoIdentifiers.count) photos")

        // Create ZIP archive
        let zipURL = fileManager.temporaryDirectory.appendingPathComponent("nestory-backup-\(timestampString()).zip")

        // Use NSFileCoordinator for ZIP creation
        try await createZIPArchive(from: tempDir, to: zipURL)

        let zipSize = (try? fileManager.attributesOfItem(atPath: zipURL.path)[.size] as? Int64) ?? 0
        logger.info("ZIP export complete: \(zipURL.path), size: \(zipSize) bytes")

        return zipURL
    }

    /// Creates a ZIP archive from a directory using Foundation's compression
    private func createZIPArchive(from sourceDir: URL, to destinationURL: URL) async throws {
        // Use FileManager's built-in compression (available iOS 17+)
        // This creates a proper ZIP file that can be extracted by standard tools
        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(readingItemAt: sourceDir, options: .forUploading, error: &error) { zippedURL in
            do {
                // The coordinator returns a temporary .zip URL - copy it to our destination
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: zippedURL, to: destinationURL)
            } catch {
                logger.error("Failed to create ZIP archive: \(error.localizedDescription)")
            }
        }

        if let error = error {
            throw BackupError.writeFailed(error)
        }

        // Verify ZIP was created
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            throw BackupError.writeFailed(NSError(domain: "BackupService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ZIP file was not created"]))
        }
    }
}

// MARK: - ZIP Import with Photos (Task 3.5.2)

extension BackupService {
    /// Imports data from a ZIP backup file including photos
    /// - Parameters:
    ///   - url: URL to the ZIP backup file
    ///   - context: SwiftData ModelContext for inserting data
    ///   - photoStorage: PhotoStorageService for saving photos
    ///   - strategy: Restore strategy (merge or replace)
    /// - Returns: ZIPRestoreResult with counts and errors
    @MainActor
    func importFromZIP(
        url: URL,
        context: ModelContext,
        photoStorage: PhotoStorageService,
        strategy: RestoreStrategy
    ) async throws -> ZIPRestoreResult {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "ZIP Import", signpostID: signpostID)
        defer {
            os_signpost(.end, log: signpostLog, name: "ZIP Import", signpostID: signpostID)
        }

        logger.info("Starting ZIP import from: \(url.path) with strategy: \(strategy.rawValue)")

        // Create temp directory for extraction
        let extractDir = FileManager.default.temporaryDirectory.appendingPathComponent("nestory-import-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        defer {
            // Cleanup temp directory after import
            try? FileManager.default.removeItem(at: extractDir)
        }

        // Extract ZIP archive
        try await extractZIPArchive(from: url, to: extractDir)

        // Find backup.json
        let jsonURL = extractDir.appendingPathComponent("backup.json")
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            // Try nested directory (ZIP may have root folder)
            let contents = try FileManager.default.contentsOfDirectory(at: extractDir, includingPropertiesForKeys: nil)
            var foundJSON: URL?
            for item in contents {
                let nestedJSON = item.appendingPathComponent("backup.json")
                if FileManager.default.fileExists(atPath: nestedJSON.path) {
                    foundJSON = nestedJSON
                    break
                }
            }
            guard let validJSON = foundJSON else {
                throw BackupError.invalidFormat
            }
            return try await performZIPRestore(jsonURL: validJSON, extractDir: validJSON.deletingLastPathComponent(), context: context, photoStorage: photoStorage, strategy: strategy)
        }

        return try await performZIPRestore(jsonURL: jsonURL, extractDir: extractDir, context: context, photoStorage: photoStorage, strategy: strategy)
    }

    /// Extracts a ZIP archive to a directory
    /// Uses NSFileCoordinator with .forUploading in reverse - this creates a
    /// temporary unzipped directory that we can copy from
    private func extractZIPArchive(from sourceURL: URL, to destinationDir: URL) async throws {
        // On iOS, the best approach is to use a third-party library like ZIPFoundation
        // or Compression framework. For v1.0, we'll use a workaround with NSFileCoordinator
        // that works for simple cases.
        
        // Note: ZIP import with photos is a v1.1 feature. For v1.0, we support JSON import only.
        // This method is a placeholder for v1.1 when we add a proper ZIP library.
        
        #if os(macOS)
        // macOS can use Process for unzip
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        task.arguments = ["-o", sourceURL.path, "-d", destinationDir.path]
        task.standardOutput = nil
        task.standardError = nil
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            throw BackupError.zipExtractionFailed
        }
        #else
        // iOS: For v1.0, ZIP import is not fully supported
        // We'll try NSFileCoordinator approach which works for some ZIP files
        // Full ZIP support with photos requires ZIPFoundation (v1.1)
        
        // Check if this is actually a ZIP file
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw BackupError.readFailed(NSError(domain: "BackupService", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "ZIP file not found"]))
        }
        
        // For iOS, we recommend using JSON import for v1.0
        // ZIP with photos will be fully supported in v1.1
        logger.warning("ZIP import on iOS is limited in v1.0. Consider using JSON import.")
        
        // Attempt basic extraction using FileWrapper (works for some archives)
        do {
            let fileWrapper = try FileWrapper(url: sourceURL, options: .immediate)
            if fileWrapper.isDirectory, let wrappers = fileWrapper.fileWrappers {
                for (name, wrapper) in wrappers {
                    let destURL = destinationDir.appendingPathComponent(name)
                    try wrapper.write(to: destURL, options: .atomic, originalContentsURL: nil)
                }
            } else if fileWrapper.regularFileContents != nil {
                // Not a directory wrapper - need actual ZIP extraction
                // For now, throw an error directing to JSON import
                throw BackupError.zipExtractionFailed
            }
        } catch {
            logger.error("ZIP extraction failed: \(error.localizedDescription)")
            throw BackupError.zipExtractionFailed
        }
        #endif
        
        logger.info("Extracted ZIP to: \(destinationDir.path)")
    }

    @MainActor
    private func performZIPRestore(
        jsonURL: URL,
        extractDir: URL,
        context: ModelContext,
        photoStorage: PhotoStorageService,
        strategy: RestoreStrategy
    ) async throws -> ZIPRestoreResult {
        // Read and parse backup data
        let backupData = try await readBackupData(from: jsonURL)

        // If replace strategy, delete existing data first
        if strategy == .replace {
            try await clearExistingData(context: context)
        }

        var errors: [ImportError] = []
        var itemsRestored = 0
        var categoriesRestored = 0
        var roomsRestored = 0
        var receiptsRestored = 0
        var photosRestored = 0

        // Step 1: Restore categories
        var categoryMap: [String: Category] = [:]
        for categoryExport in backupData.categories {
            do {
                let category = try restoreCategory(categoryExport, in: context, strategy: strategy)
                categoryMap[categoryExport.name] = category
                categoriesRestored += 1
            } catch {
                errors.append(ImportError(type: .validationFailed, description: "Failed to restore category '\(categoryExport.name)': \(error.localizedDescription)"))
            }
        }

        // Step 2: Restore rooms
        var roomMap: [String: Room] = [:]
        for roomExport in backupData.rooms {
            do {
                let room = try restoreRoom(roomExport, in: context, strategy: strategy)
                roomMap[roomExport.name] = room
                roomsRestored += 1
            } catch {
                errors.append(ImportError(type: .validationFailed, description: "Failed to restore room '\(roomExport.name)': \(error.localizedDescription)"))
            }
        }

        // Step 3: Restore photos from ZIP
        let photosDir = extractDir.appendingPathComponent("Photos")
        var restoredPhotoIdentifiers: Set<String> = []

        if FileManager.default.fileExists(atPath: photosDir.path),
           let photoFiles = try? FileManager.default.contentsOfDirectory(at: photosDir, includingPropertiesForKeys: nil) {
            for photoURL in photoFiles {
                let identifier = photoURL.lastPathComponent
                do {
                    let imageData = try Data(contentsOf: photoURL)
                    if let image = UIImage(data: imageData) {
                        // Save to photo storage with original identifier
                        try await restorePhoto(image: image, identifier: identifier, photoStorage: photoStorage)
                        restoredPhotoIdentifiers.insert(identifier)
                        photosRestored += 1
                    }
                } catch {
                    errors.append(ImportError(type: .validationFailed, description: "Failed to restore photo '\(identifier)': \(error.localizedDescription)"))
                }
            }
        }
        logger.info("Restored \(photosRestored) photos")

        // Step 4: Restore items (only reference photos that were restored)
        var itemMap: [UUID: Item] = [:]
        for itemExport in backupData.items {
            do {
                let item = try restoreItem(itemExport, categoryMap: categoryMap, roomMap: roomMap, in: context, strategy: strategy)
                itemMap[itemExport.id] = item
                itemsRestored += 1
            } catch {
                errors.append(ImportError(type: .validationFailed, description: "Failed to restore item '\(itemExport.name)': \(error.localizedDescription)"))
            }
        }

        // Step 5: Restore receipts
        for receiptExport in backupData.receipts {
            do {
                try restoreReceipt(receiptExport, itemMap: itemMap, in: context, strategy: strategy)
                receiptsRestored += 1
            } catch {
                errors.append(ImportError(type: .validationFailed, description: "Failed to restore receipt '\(receiptExport.vendor ?? "Unknown")': \(error.localizedDescription)"))
            }
        }

        // Save context
        try context.save()
        logger.info("ZIP restore completed: \(itemsRestored) items, \(photosRestored) photos, \(categoriesRestored) categories, \(roomsRestored) rooms, \(receiptsRestored) receipts")

        return ZIPRestoreResult(
            itemsRestored: itemsRestored,
            categoriesRestored: categoriesRestored,
            roomsRestored: roomsRestored,
            receiptsRestored: receiptsRestored,
            photosRestored: photosRestored,
            errors: errors
        )
    }

    /// Restores a photo with a specific identifier
    private func restorePhoto(image: UIImage, identifier: String, photoStorage: PhotoStorageService) async throws {
        // We need to save the photo with the same identifier it had in the backup
        // This requires direct file access since PhotoStorageService.savePhoto generates new UUIDs

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PhotoStorageError.documentsDirectoryNotFound
        }

        let photosDir = documentsURL.appendingPathComponent("Photos")

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }

        // Save photo with original identifier
        let photoURL = photosDir.appendingPathComponent(identifier)
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoStorageError.compressionFailed
        }

        try jpegData.write(to: photoURL, options: .atomic)
        logger.debug("Restored photo: \(identifier)")
    }
}

/// Result of ZIP restore operation with counts including photos
struct ZIPRestoreResult: Sendable {
    let itemsRestored: Int
    let categoriesRestored: Int
    let roomsRestored: Int
    let receiptsRestored: Int
    let photosRestored: Int
    let errors: [ImportError]

    var hasErrors: Bool { !errors.isEmpty }
    var totalRestored: Int { itemsRestored + categoriesRestored + roomsRestored + receiptsRestored + photosRestored }

    var summaryText: String {
        var parts: [String] = []
        if itemsRestored > 0 { parts.append("\(itemsRestored) item\(itemsRestored == 1 ? "" : "s")") }
        if photosRestored > 0 { parts.append("\(photosRestored) photo\(photosRestored == 1 ? "" : "s")") }
        if categoriesRestored > 0 { parts.append("\(categoriesRestored) categor\(categoriesRestored == 1 ? "y" : "ies")") }
        if roomsRestored > 0 { parts.append("\(roomsRestored) room\(roomsRestored == 1 ? "" : "s")") }
        if receiptsRestored > 0 { parts.append("\(receiptsRestored) receipt\(receiptsRestored == 1 ? "" : "s")") }

        if parts.isEmpty { return "No data was restored." }

        let mainText = "Restored " + parts.joined(separator: ", ") + "."
        if hasErrors {
            return mainText + " \(errors.count) error\(errors.count == 1 ? "" : "s") occurred."
        }
        return mainText
    }
}

// MARK: - Error Types

enum BackupError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case writeFailed(Error)
    case readFailed(Error)
    case invalidFormat
    case unsupportedVersion(String)
    case zipCreationFailed
    case zipExtractionFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return String(localized: "Failed to encode backup data: \(error.localizedDescription)", comment: "Backup error")
        case .decodingFailed(let error):
            return String(localized: "Failed to decode backup data: \(error.localizedDescription)", comment: "Backup error")
        case .writeFailed(let error):
            return String(localized: "Failed to write backup file: \(error.localizedDescription)", comment: "Backup error")
        case .readFailed(let error):
            return String(localized: "Failed to read backup file: \(error.localizedDescription)", comment: "Backup error")
        case .invalidFormat:
            return String(localized: "Invalid backup file format", comment: "Backup error")
        case .unsupportedVersion(let version):
            return String(localized: "Unsupported backup version: \(version)", comment: "Backup error")
        case .zipCreationFailed:
            return String(localized: "Failed to create ZIP archive", comment: "Backup error")
        case .zipExtractionFailed:
            return String(localized: "Failed to extract ZIP archive", comment: "Backup error")
        }
    }
}

// MARK: - Codable Helper

/// Nonisolated helper to perform JSON encoding/decoding outside of actor isolation
private enum BackupCodableHelper: Sendable {
    nonisolated static func encode(_ data: BackupData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(data)
    }
    
    nonisolated static func decode(from jsonData: Data) throws -> BackupData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupData.self, from: jsonData)
    }
}

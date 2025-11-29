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
import SwiftData

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

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData: Data
        do {
            jsonData = try encoder.encode(exportData)
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
    /// - Parameter items: Items to export
    /// - Returns: URL to the exported CSV file in temp directory
    func exportToCSV(items: [Item]) async throws -> URL {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "CSV Export", signpostID: signpostID,
                    "items: %d", items.count)
        defer {
            os_signpost(.end, log: signpostLog, name: "CSV Export", signpostID: signpostID)
        }

        logger.info("Starting CSV export: \(items.count) items")

        // Build CSV content
        var csvLines: [String] = []

        // Headers
        csvLines.append("Name,Description,Value,Condition,Room,Category,Purchase Date,Serial Number,Barcode,Has Photo,Has Receipt")

        // Data rows
        for item in items {
            let fields: [String] = [
                escapeCSVField(item.name),
                escapeCSVField(item.notes ?? ""),
                item.purchasePrice?.description ?? "",
                item.condition.rawValue,
                escapeCSVField(item.room?.name ?? ""),
                escapeCSVField(item.category?.name ?? ""),
                item.purchaseDate.map { formatDate($0) } ?? "",
                escapeCSVField(item.serialNumber ?? ""),
                escapeCSVField(item.barcode ?? ""),
                item.hasPhoto ? "Yes" : "No",
                item.hasReceipt ? "Yes" : "No"
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

        // Decode backup data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backupData: BackupData
        do {
            backupData = try decoder.decode(BackupData.self, from: jsonData)
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(BackupData.self, from: jsonData)
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
        let existingDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == export.name }
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
        let existingDescriptor = FetchDescriptor<Room>(
            predicate: #Predicate { $0.name == export.name }
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
            let existingDescriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.id == export.id }
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
            let existingDescriptor = FetchDescriptor<Receipt>(
                predicate: #Predicate { $0.id == export.id }
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
}

// MARK: - Export Data Structures

/// Root backup data structure
struct BackupData: Codable, Sendable {
    let exportDate: String
    let appVersion: String
    let items: [ItemExport]
    let categories: [CategoryExport]
    let rooms: [RoomExport]
    let receipts: [ReceiptExport]
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

    init(from item: Item) {
        self.id = item.id
        self.name = item.name
        self.brand = item.brand
        self.modelNumber = item.modelNumber
        self.serialNumber = item.serialNumber
        self.barcode = item.barcode
        self.purchasePrice = item.purchasePrice
        self.purchaseDate = item.purchaseDate
        self.currencyCode = item.currencyCode
        self.categoryName = item.category?.name
        self.roomName = item.room?.name
        self.condition = item.condition.rawValue
        self.conditionNotes = item.conditionNotes
        self.notes = item.notes
        self.warrantyExpiryDate = item.warrantyExpiryDate
        self.tags = item.tags
        self.photoIdentifiers = item.photos.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.imageIdentifier)
        self.receiptIds = item.receipts.map(\.id)
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
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

    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.iconName = category.iconName
        self.colorHex = category.colorHex
        self.isCustom = category.isCustom
        self.sortOrder = category.sortOrder
    }
}

/// Room export
struct RoomExport: Codable, Sendable {
    let id: UUID
    let name: String
    let iconName: String
    let sortOrder: Int
    let isDefault: Bool

    init(from room: Room) {
        self.id = room.id
        self.name = room.name
        self.iconName = room.iconName
        self.sortOrder = room.sortOrder
        self.isDefault = room.isDefault
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

    init(from receipt: Receipt) {
        self.id = receipt.id
        self.vendor = receipt.vendor
        self.total = receipt.total
        self.taxAmount = receipt.taxAmount
        self.purchaseDate = receipt.purchaseDate
        self.imageIdentifier = receipt.imageIdentifier
        self.rawText = receipt.rawText
        self.confidence = receipt.confidence
        self.linkedItemId = receipt.linkedItem?.id
        self.createdAt = receipt.createdAt
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

// MARK: - Error Types

enum BackupError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case writeFailed(Error)
    case readFailed(Error)
    case invalidFormat
    case unsupportedVersion(String)

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
        }
    }
}

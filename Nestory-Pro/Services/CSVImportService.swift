//
//  CSVImportService.swift
//  Nestory-Pro
//
//  F6: Batch import service for spreadsheet data
//

// ============================================================================
// F6: CSVImportService
// ============================================================================
// Coordinates the full CSV import workflow from file selection to item creation.
// - File reading via CSVParser
// - Column mapping via ColumnMapper
// - Validation and error handling
// - Batch item creation with progress tracking
//
// SEE: TODO.md F6 | CSVParser.swift | ColumnMapper.swift
// ============================================================================

import Foundation
import SwiftData
import OSLog

// MARK: - CSVImportService

@Observable
final class CSVImportService {

    // MARK: - Types

    /// Import workflow state
    enum ImportState: Sendable, Equatable {
        case idle
        case parsing
        case mapping
        case validating
        case importing(progress: Double)
        case completed(ImportSummary)
        case failed(String)
    }

    /// Summary of completed import
    struct ImportSummary: Sendable, Equatable {
        let totalRows: Int
        let importedCount: Int
        let skippedCount: Int
        let errorCount: Int
        let errors: [CSVImportError]
        let duration: TimeInterval

        var successRate: Double {
            guard totalRows > 0 else { return 0 }
            return Double(importedCount) / Double(totalRows)
        }
    }

    /// Individual row import error
    struct CSVImportError: Sendable, Equatable, Identifiable {
        let id = UUID()
        let rowNumber: Int
        let field: String
        let message: String

        static func == (lhs: CSVImportError, rhs: CSVImportError) -> Bool {
            lhs.rowNumber == rhs.rowNumber && lhs.field == rhs.field && lhs.message == rhs.message
        }
    }

    /// Validated row ready for import
    struct ValidatedRow: Sendable {
        let rowIndex: Int
        let name: String
        let brand: String?
        let modelNumber: String?
        let serialNumber: String?
        let purchasePrice: Decimal?
        let purchaseDate: Date?
        let warrantyExpiration: Date?
        let condition: String
        let notes: String?
        let categoryName: String?
        let roomName: String?
        let quantity: Int
    }

    // MARK: - Properties

    private(set) var state: ImportState = .idle
    private(set) var parseResult: CSVParser.ParseResult?
    private(set) var mappingResult: ColumnMapper.MappingResult?
    private(set) var validatedRows: [ValidatedRow] = []
    private(set) var validationErrors: [CSVImportError] = []

    private let csvParser = CSVParser()
    private let columnMapper = ColumnMapper()
    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "CSVImportService")

    // MARK: - Public API

    /// Set error state externally
    /// - Parameter message: Error message to display
    func setError(_ message: String) {
        state = .failed(message)
    }

    /// Parse a CSV file and prepare for mapping
    /// - Parameter url: File URL to parse
    func parseFile(url: URL) async {
        state = .parsing
        logger.info("Starting CSV import from: \(url.lastPathComponent)")

        do {
            parseResult = try await csvParser.parse(url: url)
            guard let result = parseResult else {
                throw CSVParser.ParseError.emptyFile
            }

            logger.info("Parsed \(result.rowCount) rows, \(result.columnCount) columns")

            // Auto-analyze column mappings
            state = .mapping
            mappingResult = await columnMapper.analyzeHeaders(result.headers)

            let mappedCount = self.mappingResult?.mappedFieldCount ?? 0
            logger.info("Column mapping complete, \(mappedCount) fields mapped")

        } catch {
            logger.error("Parse failed: \(error.localizedDescription)")
            state = .failed(error.localizedDescription)
        }
    }

    /// Update column mapping for a specific column
    /// - Parameters:
    ///   - columnIndex: Index of the column
    ///   - field: Target field to map (nil to unmap)
    func updateColumnMapping(columnIndex: Int, field: ColumnMapper.TargetField?) async {
        guard let currentMapping = mappingResult else { return }

        mappingResult = await columnMapper.updateMapping(
            currentMapping,
            columnIndex: columnIndex,
            newField: field
        )
    }

    /// Validate all rows against current mapping
    func validateRows() async {
        guard let parse = parseResult, let mapping = mappingResult else {
            state = .failed("No data to validate")
            return
        }

        state = .validating
        validatedRows = []
        validationErrors = []

        logger.info("Validating \(parse.rows.count) rows")

        for (rowIndex, row) in parse.rows.enumerated() {
            let validated = validateRow(
                row: row,
                rowIndex: rowIndex,
                mapping: mapping
            )

            if let validated = validated {
                validatedRows.append(validated)
            }
        }

        let validCount = validatedRows.count
        let errorCount = validationErrors.count
        logger.info("Validation complete: \(validCount) valid, \(errorCount) errors")

        // Stay in validating state - UI will transition to import
    }

    /// Execute import of validated rows
    /// - Parameter modelContext: SwiftData model context for creating items
    @MainActor
    func executeImport(modelContext: ModelContext) async {
        guard !validatedRows.isEmpty else {
            state = .failed("No valid rows to import")
            return
        }

        let startTime = Date()
        let totalRows = validatedRows.count
        var importedCount = 0
        var errors: [CSVImportError] = []

        logger.info("Starting import of \(totalRows) items")

        // Fetch existing categories and rooms for matching
        let categories = fetchCategories(modelContext: modelContext)
        let rooms = fetchRooms(modelContext: modelContext)

        for (index, validatedRow) in validatedRows.enumerated() {
            let progress = Double(index + 1) / Double(totalRows)
            state = .importing(progress: progress)

            do {
                try createItem(
                    from: validatedRow,
                    categories: categories,
                    rooms: rooms,
                    modelContext: modelContext
                )
                importedCount += 1
            } catch {
                errors.append(CSVImportError(
                    rowNumber: validatedRow.rowIndex + 2,  // +2 for header and 1-based
                    field: "item",
                    message: error.localizedDescription
                ))
            }

            // Yield to allow UI updates
            if index % 10 == 0 {
                await Task.yield()
            }
        }

        // Save context
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save imported items: \(error.localizedDescription)")
            state = .failed("Failed to save: \(error.localizedDescription)")
            return
        }

        let duration = Date().timeIntervalSince(startTime)

        let summary = ImportSummary(
            totalRows: parseResult?.rowCount ?? totalRows,
            importedCount: importedCount,
            skippedCount: validationErrors.count,
            errorCount: errors.count,
            errors: errors,
            duration: duration
        )

        logger.info("Import complete: \(importedCount)/\(totalRows) items in \(String(format: "%.1f", duration))s")

        state = .completed(summary)
    }

    /// Reset service to initial state
    func reset() {
        state = .idle
        parseResult = nil
        mappingResult = nil
        validatedRows = []
        validationErrors = []
    }

    // MARK: - Private Helpers

    /// Validate a single row and extract values
    private func validateRow(
        row: [String],
        rowIndex: Int,
        mapping: ColumnMapper.MappingResult
    ) -> ValidatedRow? {
        var name: String?
        var brand: String?
        var modelNumber: String?
        var serialNumber: String?
        var purchasePrice: Decimal?
        var purchaseDate: Date?
        var warrantyExpiration: Date?
        var condition: String = "good"
        var notes: String?
        var categoryName: String?
        var roomName: String?
        var quantity: Int = 1

        // Extract values based on mapping
        for columnMapping in mapping.mappings {
            guard let field = columnMapping.targetField else { continue }
            guard columnMapping.columnIndex < row.count else { continue }

            let value = row[columnMapping.columnIndex].trimmingCharacters(in: .whitespaces)
            guard !value.isEmpty else { continue }

            switch field {
            case .name:
                name = value
            case .brand:
                brand = value
            case .modelNumber:
                modelNumber = value
            case .serialNumber:
                serialNumber = value
            case .purchasePrice:
                if let price = ColumnMapper.parsePrice(value) {
                    purchasePrice = price
                } else {
                    validationErrors.append(CSVImportError(
                        rowNumber: rowIndex + 2,
                        field: field.displayName,
                        message: "Invalid price format: \(value)"
                    ))
                }
            case .purchaseDate:
                if let date = ColumnMapper.parseDate(value) {
                    purchaseDate = date
                } else {
                    validationErrors.append(CSVImportError(
                        rowNumber: rowIndex + 2,
                        field: field.displayName,
                        message: "Invalid date format: \(value)"
                    ))
                }
            case .warrantyExpiration:
                if let date = ColumnMapper.parseDate(value) {
                    warrantyExpiration = date
                } else {
                    validationErrors.append(CSVImportError(
                        rowNumber: rowIndex + 2,
                        field: field.displayName,
                        message: "Invalid date format: \(value)"
                    ))
                }
            case .condition:
                condition = ColumnMapper.parseCondition(value)
            case .notes:
                notes = value
            case .category:
                categoryName = value
            case .room:
                roomName = value
            case .quantity:
                if let qty = ColumnMapper.parseQuantity(value), qty > 0 {
                    quantity = qty
                }
            }
        }

        // Validate required fields
        guard let itemName = name, !itemName.isEmpty else {
            validationErrors.append(CSVImportError(
                rowNumber: rowIndex + 2,
                field: "Name",
                message: "Item name is required"
            ))
            return nil
        }

        return ValidatedRow(
            rowIndex: rowIndex,
            name: itemName,
            brand: brand,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            purchasePrice: purchasePrice,
            purchaseDate: purchaseDate,
            warrantyExpiration: warrantyExpiration,
            condition: condition,
            notes: notes,
            categoryName: categoryName,
            roomName: roomName,
            quantity: quantity
        )
    }

    /// Fetch all categories from the database
    @MainActor
    private func fetchCategories(modelContext: ModelContext) -> [Category] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Fetch all rooms from the database
    @MainActor
    private func fetchRooms(modelContext: ModelContext) -> [Room] {
        let descriptor = FetchDescriptor<Room>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Create an Item from validated row data
    @MainActor
    private func createItem(
        from row: ValidatedRow,
        categories: [Category],
        rooms: [Room],
        modelContext: ModelContext
    ) throws {
        // Create item(s) based on quantity
        for _ in 0..<row.quantity {
            let item = Item(name: row.name)
            item.brand = row.brand
            item.modelNumber = row.modelNumber
            item.serialNumber = row.serialNumber
            item.purchasePrice = row.purchasePrice
            item.purchaseDate = row.purchaseDate
            item.warrantyExpiryDate = row.warrantyExpiration
            item.notes = row.notes

            // Set condition (map string to enum)
            if let conditionValue = ItemCondition(rawValue: row.condition) {
                item.condition = conditionValue
            }

            // Match category by name (case-insensitive)
            if let categoryName = row.categoryName {
                item.category = categories.first {
                    $0.name.lowercased() == categoryName.lowercased()
                }
            }

            // Match room by name (case-insensitive)
            if let roomName = row.roomName {
                item.room = rooms.first {
                    $0.name.lowercased() == roomName.lowercased()
                }
            }

            modelContext.insert(item)
        }
    }
}

// MARK: - File Type Support

extension CSVImportService {

    /// Supported import file types
    static let supportedTypes = ["csv", "tsv", "txt"]

    /// Check if a file URL is a supported import type
    static func isSupported(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedTypes.contains(ext)
    }
}

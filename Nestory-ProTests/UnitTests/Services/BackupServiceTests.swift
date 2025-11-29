//
//  BackupServiceTests.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// CLAUDE CODE AGENT: BACKUP SERVICE TESTS
// ============================================================================
// Task 9.1.3: Unit tests for BackupService
// Tests JSON/CSV export, import validation, and error handling
//
// SEE: TODO.md Phase 9 | BackupService.swift | BackupServiceProtocol.swift
// ============================================================================

import XCTest
@testable import Nestory_Pro

@MainActor
final class BackupServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: BackupService!
    var exportedFileURLs: [URL] = []

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = await BackupService.shared
        exportedFileURLs = []
    }

    override func tearDown() async throws {
        // Clean up exported files
        for url in exportedFileURLs {
            try? FileManager.default.removeItem(at: url)
        }
        exportedFileURLs = []
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createSampleItemExports(count: Int = 3) -> [ItemExport] {
        (0..<count).map { index in
            ItemExport(
                id: UUID(),
                name: "Test Item \(index + 1)",
                brand: "Brand \(index + 1)",
                modelNumber: "Model-\(index + 1)",
                serialNumber: "SN-\(index + 1)",
                barcode: nil,
                purchasePrice: Decimal(100 * (index + 1)),
                purchaseDate: Date(),
                currencyCode: "USD",
                categoryName: "Electronics",
                roomName: "Living Room",
                condition: "good",
                conditionNotes: nil,
                notes: "Test notes for item \(index + 1)",
                warrantyExpiryDate: nil,
                tags: ["test", "sample"],
                photoIdentifiers: [],
                receiptIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }

    private func createSampleCategoryExports() -> [CategoryExport] {
        [
            CategoryExport(
                id: UUID(),
                name: "Electronics",
                iconName: "laptopcomputer",
                colorHex: "#007AFF",
                isCustom: false,
                sortOrder: 0
            ),
            CategoryExport(
                id: UUID(),
                name: "Furniture",
                iconName: "sofa.fill",
                colorHex: "#34C759",
                isCustom: false,
                sortOrder: 1
            )
        ]
    }

    private func createSampleRoomExports() -> [RoomExport] {
        [
            RoomExport(
                id: UUID(),
                name: "Living Room",
                iconName: "sofa.fill",
                sortOrder: 0,
                isDefault: true
            ),
            RoomExport(
                id: UUID(),
                name: "Kitchen",
                iconName: "fork.knife",
                sortOrder: 1,
                isDefault: true
            )
        ]
    }

    private func createSampleReceiptExports() -> [ReceiptExport] {
        [
            ReceiptExport(
                id: UUID(),
                vendor: "Best Buy",
                total: Decimal(string: "299.99"),
                taxAmount: Decimal(string: "24.00"),
                purchaseDate: Date(),
                imageIdentifier: "receipt-1.jpg",
                rawText: "Receipt text here",
                confidence: 0.95,
                linkedItemId: nil,
                createdAt: Date()
            )
        ]
    }

    // MARK: - JSON Export Tests

    func testExportToJSON_WithData_CreatesValidFile() async throws {
        // Arrange
        let items = createSampleItemExports()
        let categories = createSampleCategoryExports()
        let rooms = createSampleRoomExports()
        let receipts = createSampleReceiptExports()

        // Act
        let fileURL = try await sut.exportToJSON(
            itemExports: items,
            categoryExports: categories,
            roomExports: rooms,
            receiptExports: receipts
        )
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.pathExtension == "json")
    }

    func testExportToJSON_FileContainsAllData() async throws {
        // Arrange
        let items = createSampleItemExports(count: 2)
        let categories = createSampleCategoryExports()
        let rooms = createSampleRoomExports()
        let receipts = createSampleReceiptExports()

        // Act
        let fileURL = try await sut.exportToJSON(
            itemExports: items,
            categoryExports: categories,
            roomExports: rooms,
            receiptExports: receipts
        )
        exportedFileURLs.append(fileURL)

        // Read and verify content
        let jsonData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: jsonData)

        // Assert
        XCTAssertEqual(backupData.items.count, 2)
        XCTAssertEqual(backupData.categories.count, 2)
        XCTAssertEqual(backupData.rooms.count, 2)
        XCTAssertEqual(backupData.receipts.count, 1)
        XCTAssertFalse(backupData.exportDate.isEmpty)
        XCTAssertFalse(backupData.appVersion.isEmpty)
    }

    func testExportToJSON_EmptyData_CreatesValidFile() async throws {
        // Arrange - Empty data
        let items: [ItemExport] = []
        let categories: [CategoryExport] = []
        let rooms: [RoomExport] = []
        let receipts: [ReceiptExport] = []

        // Act
        let fileURL = try await sut.exportToJSON(
            itemExports: items,
            categoryExports: categories,
            roomExports: rooms,
            receiptExports: receipts
        )
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let jsonData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: jsonData)

        XCTAssertEqual(backupData.items.count, 0)
        XCTAssertEqual(backupData.categories.count, 0)
    }

    func testExportToJSON_FilenameHasTimestamp() async throws {
        // Arrange
        let items = createSampleItemExports(count: 1)

        // Act
        let fileURL = try await sut.exportToJSON(
            itemExports: items,
            categoryExports: [],
            roomExports: [],
            receiptExports: []
        )
        exportedFileURLs.append(fileURL)

        // Assert
        let filename = fileURL.lastPathComponent
        XCTAssertTrue(filename.hasPrefix("nestory-backup-"))
        XCTAssertTrue(filename.hasSuffix(".json"))
    }

    // MARK: - CSV Export Tests

    func testExportToCSV_WithData_CreatesValidFile() async throws {
        // Arrange
        let items = createSampleItemExports()

        // Act
        let fileURL = try await sut.exportToCSV(itemExports: items)
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.pathExtension == "csv")
    }

    func testExportToCSV_HasHeaderRow() async throws {
        // Arrange
        let items = createSampleItemExports(count: 1)

        // Act
        let fileURL = try await sut.exportToCSV(itemExports: items)
        exportedFileURLs.append(fileURL)

        // Read content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = csvContent.components(separatedBy: "\n")

        // Assert
        XCTAssertGreaterThan(lines.count, 0)
        let header = lines[0]
        XCTAssertTrue(header.contains("Name"))
        XCTAssertTrue(header.contains("Value"))
        XCTAssertTrue(header.contains("Room"))
        XCTAssertTrue(header.contains("Category"))
    }

    func testExportToCSV_CorrectRowCount() async throws {
        // Arrange
        let items = createSampleItemExports(count: 5)

        // Act
        let fileURL = try await sut.exportToCSV(itemExports: items)
        exportedFileURLs.append(fileURL)

        // Read content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = csvContent.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Assert - 1 header + 5 data rows
        XCTAssertEqual(lines.count, 6)
    }

    func testExportToCSV_EscapesCommasInFields() async throws {
        // Arrange
        let items = [
            ItemExport(
                id: UUID(),
                name: "Item with, comma",
                brand: nil,
                modelNumber: nil,
                serialNumber: nil,
                barcode: nil,
                purchasePrice: nil,
                purchaseDate: nil,
                currencyCode: "USD",
                categoryName: nil,
                roomName: nil,
                condition: "good",
                conditionNotes: nil,
                notes: nil,
                warrantyExpiryDate: nil,
                tags: [],
                photoIdentifiers: [],
                receiptIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]

        // Act
        let fileURL = try await sut.exportToCSV(itemExports: items)
        exportedFileURLs.append(fileURL)

        // Read content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Assert - Field with comma should be quoted
        XCTAssertTrue(csvContent.contains("\"Item with, comma\""))
    }

    func testExportToCSV_EmptyData_CreatesFileWithHeaderOnly() async throws {
        // Arrange
        let items: [ItemExport] = []

        // Act
        let fileURL = try await sut.exportToCSV(itemExports: items)
        exportedFileURLs.append(fileURL)

        // Read content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = csvContent.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Assert - Header only
        XCTAssertEqual(lines.count, 1)
    }

    // MARK: - JSON Import Validation Tests

    func testImportFromJSON_ValidFile_ReturnsCorrectCounts() async throws {
        // Arrange - Create and export valid data
        let items = createSampleItemExports(count: 3)
        let categories = createSampleCategoryExports()
        let rooms = createSampleRoomExports()
        let receipts = createSampleReceiptExports()

        let fileURL = try await sut.exportToJSON(
            itemExports: items,
            categoryExports: categories,
            roomExports: rooms,
            receiptExports: receipts
        )
        exportedFileURLs.append(fileURL)

        // Act
        let result = try await sut.importFromJSON(url: fileURL)

        // Assert
        XCTAssertEqual(result.itemsImported, 3)
        XCTAssertEqual(result.categoriesImported, 2)
        XCTAssertEqual(result.roomsImported, 2)
        XCTAssertFalse(result.hasErrors)
    }

    func testImportFromJSON_ItemWithEmptyName_ReportsError() async throws {
        // Arrange - Create backup with invalid item
        let invalidItem = ItemExport(
            id: UUID(),
            name: "", // Invalid empty name
            brand: nil,
            modelNumber: nil,
            serialNumber: nil,
            barcode: nil,
            purchasePrice: nil,
            purchaseDate: nil,
            currencyCode: "USD",
            categoryName: nil,
            roomName: nil,
            condition: "good",
            conditionNotes: nil,
            notes: nil,
            warrantyExpiryDate: nil,
            tags: [],
            photoIdentifiers: [],
            receiptIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        let fileURL = try await sut.exportToJSON(
            itemExports: [invalidItem],
            categoryExports: [],
            roomExports: [],
            receiptExports: []
        )
        exportedFileURLs.append(fileURL)

        // Act
        let result = try await sut.importFromJSON(url: fileURL)

        // Assert
        XCTAssertTrue(result.hasErrors)
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertTrue(result.errors[0].description.contains("empty name"))
    }

    func testImportFromJSON_NonExistentFile_ThrowsError() async throws {
        // Arrange
        let fakeURL = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent.json")

        // Act & Assert
        do {
            _ = try await sut.importFromJSON(url: fakeURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            XCTAssertTrue(error is BackupError)
        }
    }

    func testImportFromJSON_InvalidJSON_ThrowsError() async throws {
        // Arrange - Create file with invalid JSON
        let invalidJSON = "{ invalid json content"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("invalid.json")
        try invalidJSON.write(to: fileURL, atomically: true, encoding: .utf8)
        exportedFileURLs.append(fileURL)

        // Act & Assert
        do {
            _ = try await sut.importFromJSON(url: fileURL)
            XCTFail("Should throw error for invalid JSON")
        } catch {
            XCTAssertTrue(error is BackupError)
        }
    }

    // MARK: - BackupData Codable Tests

    func testBackupData_RoundTrip_PreservesAllData() async throws {
        // Arrange
        let items = createSampleItemExports(count: 2)
        let categories = createSampleCategoryExports()
        let rooms = createSampleRoomExports()
        let receipts = createSampleReceiptExports()

        let originalData = BackupData(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            appVersion: "1.0.0",
            items: items,
            categories: categories,
            rooms: rooms,
            receipts: receipts
        )

        // Act - Encode and decode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(originalData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(BackupData.self, from: jsonData)

        // Assert
        XCTAssertEqual(decodedData.items.count, originalData.items.count)
        XCTAssertEqual(decodedData.categories.count, originalData.categories.count)
        XCTAssertEqual(decodedData.rooms.count, originalData.rooms.count)
        XCTAssertEqual(decodedData.receipts.count, originalData.receipts.count)
        XCTAssertEqual(decodedData.appVersion, originalData.appVersion)

        // Verify item data preserved
        XCTAssertEqual(decodedData.items[0].name, items[0].name)
        XCTAssertEqual(decodedData.items[0].purchasePrice, items[0].purchasePrice)
    }

    // MARK: - Restore Result Tests

    func testRestoreResult_SummaryText_NoData() {
        // Arrange
        let result = RestoreResult(
            itemsRestored: 0,
            categoriesRestored: 0,
            roomsRestored: 0,
            receiptsRestored: 0,
            errors: []
        )

        // Assert
        XCTAssertEqual(result.summaryText, "No data was restored.")
    }

    func testRestoreResult_SummaryText_SingleItems() {
        // Arrange
        let result = RestoreResult(
            itemsRestored: 1,
            categoriesRestored: 1,
            roomsRestored: 1,
            receiptsRestored: 1,
            errors: []
        )

        // Assert
        XCTAssertTrue(result.summaryText.contains("1 item"))
        XCTAssertTrue(result.summaryText.contains("1 category"))
        XCTAssertTrue(result.summaryText.contains("1 room"))
        XCTAssertTrue(result.summaryText.contains("1 receipt"))
        XCTAssertFalse(result.summaryText.contains("error"))
    }

    func testRestoreResult_SummaryText_MultipleItems() {
        // Arrange
        let result = RestoreResult(
            itemsRestored: 5,
            categoriesRestored: 3,
            roomsRestored: 2,
            receiptsRestored: 4,
            errors: []
        )

        // Assert
        XCTAssertTrue(result.summaryText.contains("5 items"))
        XCTAssertTrue(result.summaryText.contains("3 categories"))
        XCTAssertTrue(result.summaryText.contains("2 rooms"))
        XCTAssertTrue(result.summaryText.contains("4 receipts"))
    }

    func testRestoreResult_SummaryText_WithErrors() {
        // Arrange
        let result = RestoreResult(
            itemsRestored: 5,
            categoriesRestored: 0,
            roomsRestored: 0,
            receiptsRestored: 0,
            errors: [
                ImportError(type: .validationFailed, description: "Error 1"),
                ImportError(type: .validationFailed, description: "Error 2")
            ]
        )

        // Assert
        XCTAssertTrue(result.summaryText.contains("5 items"))
        XCTAssertTrue(result.summaryText.contains("2 errors"))
    }

    // MARK: - Restore Strategy Tests

    func testRestoreStrategy_HasCorrectDescriptions() {
        // Assert
        XCTAssertFalse(RestoreStrategy.merge.description.isEmpty)
        XCTAssertFalse(RestoreStrategy.replace.description.isEmpty)
        XCTAssertNotEqual(RestoreStrategy.merge.description, RestoreStrategy.replace.description)
    }

    // MARK: - ImportResult Tests

    func testImportResult_SuccessCount_CalculatesCorrectly() {
        // Arrange
        let result = ImportResult(
            itemsImported: 10,
            categoriesImported: 5,
            roomsImported: 3,
            errors: []
        )

        // Assert
        XCTAssertEqual(result.successCount, 18)
    }

    func testImportResult_HasErrors_TrueWhenErrorsExist() {
        // Arrange
        let resultWithErrors = ImportResult(
            itemsImported: 5,
            categoriesImported: 2,
            roomsImported: 1,
            errors: [ImportError(type: .validationFailed, description: "Test error")]
        )

        let resultNoErrors = ImportResult(
            itemsImported: 5,
            categoriesImported: 2,
            roomsImported: 1,
            errors: []
        )

        // Assert
        XCTAssertTrue(resultWithErrors.hasErrors)
        XCTAssertFalse(resultNoErrors.hasErrors)
    }
}

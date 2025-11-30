//
//  ReportGeneratorServiceTests.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// CLAUDE CODE AGENT: REPORT GENERATOR SERVICE TESTS
// ============================================================================
// Task 9.1.4: Unit tests for ReportGeneratorService
// Tests PDF generation, grouping options, and report configuration
//
// SEE: TODO.md Phase 9 | ReportGeneratorService.swift
// ============================================================================

import XCTest
import PDFKit
@testable import Nestory_Pro

final class ReportGeneratorServiceTests: XCTestCase {

    // MARK: - Properties

    nonisolated(unsafe) var sut: ReportGeneratorService!
    nonisolated(unsafe) var exportedFileURLs: [URL] = []

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = await ReportGeneratorService.shared
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

    nonisolated private func createTestItems(count: Int = 3) -> [Item] {
        (0..<count).map { index in
            let item = Item(
                name: "Test Item \(index + 1)",
                brand: "Brand \(index + 1)",
                modelNumber: nil,
                serialNumber: nil,
                purchasePrice: Decimal(100 * (index + 1)),
                purchaseDate: Date(),
                condition: .good
            )
            return item
        }
    }

    // MARK: - ReportOptions Tests

    func testReportOptions_DefaultValues() async {
        await MainActor.run {
            // Act
            let options = ReportOptions()

            // Assert
            XCTAssertEqual(options.grouping, .byRoom)
            XCTAssertFalse(options.includePhotos)
            XCTAssertFalse(options.includeReceipts)
        }
    }

    func testReportOptions_CustomConfiguration() async {
        await MainActor.run {
            // Act
            let options = ReportOptions(
                grouping: .byCategory,
                includePhotos: true,
                includeReceipts: true
            )

            // Assert
            XCTAssertEqual(options.grouping, .byCategory)
            XCTAssertTrue(options.includePhotos)
            XCTAssertTrue(options.includeReceipts)
        }
    }

    // MARK: - ReportGrouping Tests

    func testReportGrouping_RawValues() async {
        await MainActor.run {
            // Assert
            XCTAssertEqual(ReportGrouping.byRoom.rawValue, "room")
            XCTAssertEqual(ReportGrouping.byCategory.rawValue, "category")
            XCTAssertEqual(ReportGrouping.alphabetical.rawValue, "alphabetical")
        }
    }

    func testReportGrouping_DisplayNames() async {
        await MainActor.run {
            // Assert
            XCTAssertEqual(ReportGrouping.byRoom.displayName, "By Room")
            XCTAssertEqual(ReportGrouping.byCategory.displayName, "By Category")
            XCTAssertEqual(ReportGrouping.alphabetical.displayName, "Alphabetical")
        }
    }

    // MARK: - PDF Generation Tests

    func testGenerateFullInventoryPDF_WithItems_CreatesPDFFile() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 5)
        }

        let options = await MainActor.run {
            ReportOptions()
        }

        // Act
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(fileURL.pathExtension, "pdf")
    }

    func testGenerateFullInventoryPDF_EmptyItems_CreatesPDFFile() async throws {
        // Arrange
        let items: [Item] = []
        let options = await MainActor.run {
            ReportOptions()
        }

        // Act
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testGenerateFullInventoryPDF_PDFIsValid() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 3)
        }

        let options = await MainActor.run {
            ReportOptions()
        }

        // Act
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)

        // Assert - PDF should be loadable by PDFKit
        let pdfDocument = PDFDocument(url: fileURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0)
    }

    func testGenerateFullInventoryPDF_AlphabeticalGrouping_Works() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 3)
        }

        let options = await MainActor.run {
            ReportOptions(grouping: .alphabetical)
        }

        // Act
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testGenerateFullInventoryPDF_ByCategoryGrouping_Works() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 3)
        }

        let options = await MainActor.run {
            ReportOptions(grouping: .byCategory)
        }

        // Act
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    // MARK: - Loss List PDF Tests

    func testGenerateLossListPDF_WithItems_CreatesPDFFile() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 3)
        }

        let incidentDetails = await MainActor.run {
            IncidentDetails(
                incidentDate: Date(),
                incidentType: .theft,
                description: "Items stolen from property"
            )
        }

        // Act
        let fileURL = try await sut.generateLossListPDF(
            items: items,
            incident: incidentDetails
        )
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(fileURL.pathExtension, "pdf")
    }

    func testGenerateLossListPDF_PDFIsValid() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 2)
        }

        let incidentDetails = await MainActor.run {
            IncidentDetails(
                incidentDate: Date(),
                incidentType: .fire,
                description: "Fire damage"
            )
        }

        // Act
        let fileURL = try await sut.generateLossListPDF(
            items: items,
            incident: incidentDetails
        )
        exportedFileURLs.append(fileURL)

        // Assert
        let pdfDocument = PDFDocument(url: fileURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0)
    }

    // MARK: - IncidentDetails Tests

    func testIncidentDetails_AllTypes() async {
        await MainActor.run {
            // Assert - All incident types can be instantiated
            let types: [IncidentType] = [.fire, .theft, .flood, .waterDamage, .other]

            for type in types {
                let details = IncidentDetails(
                    incidentDate: Date(),
                    incidentType: type,
                    description: "Test description"
                )
                XCTAssertEqual(details.incidentType, type)
            }
        }
    }

    func testIncidentType_DisplayNames() async {
        await MainActor.run {
            // Assert
            XCTAssertFalse(IncidentType.fire.displayName.isEmpty)
            XCTAssertFalse(IncidentType.theft.displayName.isEmpty)
            XCTAssertFalse(IncidentType.flood.displayName.isEmpty)
            XCTAssertFalse(IncidentType.waterDamage.displayName.isEmpty)
            XCTAssertFalse(IncidentType.other.displayName.isEmpty)
        }
    }

    // MARK: - File Naming Tests

    func testGenerateFullInventoryPDF_FilenameFormat() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 1)
        }

        let options = await MainActor.run {
            ReportOptions()
        }

        // Act
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)

        // Assert
        let filename = fileURL.lastPathComponent
        XCTAssertTrue(filename.hasPrefix("inventory-"))
        XCTAssertTrue(filename.hasSuffix(".pdf"))
    }

    func testGenerateLossListPDF_FilenameFormat() async throws {
        // Arrange
        let items = await MainActor.run {
            createTestItems(count: 1)
        }

        let incidentDetails = await MainActor.run {
            IncidentDetails(
                incidentDate: Date(),
                incidentType: .other,
                description: "Description"
            )
        }

        // Act
        let fileURL = try await sut.generateLossListPDF(
            items: items,
            incident: incidentDetails
        )
        exportedFileURLs.append(fileURL)

        // Assert
        let filename = fileURL.lastPathComponent
        XCTAssertTrue(filename.hasPrefix("loss-list-"))
        XCTAssertTrue(filename.hasSuffix(".pdf"))
    }

    // MARK: - Large Dataset Tests

    func testGenerateFullInventoryPDF_LargeDataset_Works() async throws {
        // Arrange - Create 100 items
        let items = await MainActor.run {
            createTestItems(count: 100)
        }

        let options = await MainActor.run {
            ReportOptions()
        }

        // Act
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // Should have multiple pages
        let pdfDocument = PDFDocument(url: fileURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 1)
    }
}

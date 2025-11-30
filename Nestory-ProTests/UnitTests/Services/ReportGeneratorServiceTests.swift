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

    @MainActor
    private func createTestItems(count: Int = 3) -> [Item] {
        (0..<count).map { index in
            Item(
                name: "Test Item \(index + 1)",
                brand: "Brand \(index + 1)",
                modelNumber: nil,
                serialNumber: nil,
                purchasePrice: Decimal(100 * (index + 1)),
                purchaseDate: Date(),
                condition: .good
            )
        }
    }

    // MARK: - ReportOptions Tests

    @MainActor
    func testReportOptions_DefaultValues() {
        let options = ReportOptions()
        XCTAssertEqual(options.grouping, .byRoom)
        XCTAssertFalse(options.includePhotos)
        XCTAssertFalse(options.includeReceipts)
    }

    @MainActor
    func testReportOptions_CustomConfiguration() {
        let options = ReportOptions(
            grouping: .byCategory,
            includePhotos: true,
            includeReceipts: true
        )
        XCTAssertEqual(options.grouping, .byCategory)
        XCTAssertTrue(options.includePhotos)
        XCTAssertTrue(options.includeReceipts)
    }

    // MARK: - ReportGrouping Tests

    @MainActor
    func testReportGrouping_RawValues() {
        XCTAssertEqual(ReportGrouping.byRoom.rawValue, "room")
        XCTAssertEqual(ReportGrouping.byCategory.rawValue, "category")
        XCTAssertEqual(ReportGrouping.alphabetical.rawValue, "alphabetical")
    }

    @MainActor
    func testReportGrouping_DisplayNames() {
        XCTAssertEqual(ReportGrouping.byRoom.displayName, "By Room")
        XCTAssertEqual(ReportGrouping.byCategory.displayName, "By Category")
        XCTAssertEqual(ReportGrouping.alphabetical.displayName, "Alphabetical")
    }

    // MARK: - PDF Generation Tests

    @MainActor
    func testGenerateFullInventoryPDF_WithItems_CreatesPDFFile() async throws {
        let items = createTestItems(count: 5)
        let options = ReportOptions()
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(fileURL.pathExtension, "pdf")
    }

    @MainActor
    func testGenerateFullInventoryPDF_EmptyItems_CreatesPDFFile() async throws {
        let items: [Item] = []
        let options = ReportOptions()
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @MainActor
    func testGenerateFullInventoryPDF_PDFIsValid() async throws {
        let items = createTestItems(count: 3)
        let options = ReportOptions()
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)
        let pdfDocument = PDFDocument(url: fileURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0)
    }

    @MainActor
    func testGenerateFullInventoryPDF_AlphabeticalGrouping_Works() async throws {
        let items = createTestItems(count: 3)
        let options = ReportOptions(grouping: .alphabetical)
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @MainActor
    func testGenerateFullInventoryPDF_ByCategoryGrouping_Works() async throws {
        let items = createTestItems(count: 3)
        let options = ReportOptions(grouping: .byCategory)
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    // MARK: - Loss List PDF Tests

    @MainActor
    func testGenerateLossListPDF_WithItems_CreatesPDFFile() async throws {
        let items = createTestItems(count: 3)
        let incidentDetails = IncidentDetails(
            incidentDate: Date(),
            incidentType: .theft,
            description: "Items stolen from property"
        )
        let fileURL = try await sut.generateLossListPDF(items: items, incident: incidentDetails)
        exportedFileURLs.append(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(fileURL.pathExtension, "pdf")
    }

    @MainActor
    func testGenerateLossListPDF_PDFIsValid() async throws {
        let items = createTestItems(count: 2)
        let incidentDetails = IncidentDetails(
            incidentDate: Date(),
            incidentType: .fire,
            description: "Fire damage"
        )
        let fileURL = try await sut.generateLossListPDF(items: items, incident: incidentDetails)
        exportedFileURLs.append(fileURL)
        let pdfDocument = PDFDocument(url: fileURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0)
    }

    // MARK: - IncidentDetails Tests

    @MainActor
    func testIncidentDetails_AllTypes() {
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

    @MainActor
    func testIncidentType_DisplayNames() {
        XCTAssertFalse(IncidentType.fire.displayName.isEmpty)
        XCTAssertFalse(IncidentType.theft.displayName.isEmpty)
        XCTAssertFalse(IncidentType.flood.displayName.isEmpty)
        XCTAssertFalse(IncidentType.waterDamage.displayName.isEmpty)
        XCTAssertFalse(IncidentType.other.displayName.isEmpty)
    }

    // MARK: - File Naming Tests

    @MainActor
    func testGenerateFullInventoryPDF_FilenameFormat() async throws {
        let items = createTestItems(count: 1)
        let options = ReportOptions()
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)
        let filename = fileURL.lastPathComponent
        XCTAssertTrue(filename.hasPrefix("inventory-"))
        XCTAssertTrue(filename.hasSuffix(".pdf"))
    }

    @MainActor
    func testGenerateLossListPDF_FilenameFormat() async throws {
        let items = createTestItems(count: 1)
        let incidentDetails = IncidentDetails(
            incidentDate: Date(),
            incidentType: .other,
            description: "Description"
        )
        let fileURL = try await sut.generateLossListPDF(items: items, incident: incidentDetails)
        exportedFileURLs.append(fileURL)
        let filename = fileURL.lastPathComponent
        XCTAssertTrue(filename.hasPrefix("loss-list-"))
        XCTAssertTrue(filename.hasSuffix(".pdf"))
    }

    // MARK: - Large Dataset Tests

    @MainActor
    func testGenerateFullInventoryPDF_LargeDataset_Works() async throws {
        let items = createTestItems(count: 100)
        let options = ReportOptions()
        let fileURL = try await sut.generateFullInventoryPDF(items: items, options: options)
        exportedFileURLs.append(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        let pdfDocument = PDFDocument(url: fileURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 1)
    }
}

//
//  ReportGeneratorOutputTests.swift
//  Nestory-ProTests
//
//  Integration test that generates actual PDF files for visual verification
//

import XCTest
import SwiftData
import PDFKit
@testable import Nestory_Pro

/// Integration tests that generate actual PDF files for visual verification
/// PDFs are attached to test results and can be viewed in Xcode's test navigator
final class ReportGeneratorOutputTests: XCTestCase {
    
    // MARK: - Full Inventory Report Test
    
    @MainActor
    func testGenerateFullInventoryPDF_ProducesValidFile() async throws {
        // Arrange - Create test container with sample data
        let container = try NestoryModelContainer.createForTesting()
        let context = container.mainContext
        
        // Create rooms
        let livingRoom = Room(name: "Living Room", iconName: "sofa", sortOrder: 0)
        let kitchen = Room(name: "Kitchen", iconName: "fork.knife", sortOrder: 1)
        context.insert(livingRoom)
        context.insert(kitchen)
        
        // Create categories
        let electronics = Nestory_Pro.Category(name: "Electronics", iconName: "tv", colorHex: "#007AFF", sortOrder: 0)
        let furniture = Nestory_Pro.Category(name: "Furniture", iconName: "chair.lounge", colorHex: "#8B4513", sortOrder: 1)
        context.insert(electronics)
        context.insert(furniture)
        
        // Create test items
        let item1 = Item(
            name: "Samsung 65\" OLED Smart TV",
            brand: "Samsung",
            purchasePrice: 1899.99,
            category: electronics,
            room: livingRoom,
            condition: .likeNew
        )
        let item2 = Item(
            name: "Leather Sectional Sofa",
            brand: "West Elm",
            purchasePrice: 3499.00,
            category: furniture,
            room: livingRoom,
            condition: .good
        )
        let item3 = Item(
            name: "KitchenAid Stand Mixer",
            brand: "KitchenAid",
            purchasePrice: 449.99,
            category: electronics,
            room: kitchen,
            condition: .good
        )
        
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()
        
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.name)])
        let items = try context.fetch(descriptor)
        
        XCTAssertEqual(items.count, 3, "Should have 3 test items")
        
        // Act - Generate PDF
        let reportGenerator = ReportGeneratorService.shared
        let options = ReportOptions(
            grouping: .byRoom,
            includePhotos: false,
            includeReceipts: false
        )
        
        let pdfURL = try await reportGenerator.generateFullInventoryPDF(items: items, options: options)
        
        // Verify PDF was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path), "PDF file should exist at \(pdfURL.path)")
        
        // Verify PDF is valid and has content
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            XCTFail("Could not load generated PDF from \(pdfURL.path)")
            return
        }
        
        XCTAssertGreaterThan(pdfDocument.pageCount, 0, "PDF should have at least one page")
        
        // Assert file size is reasonable (not empty, not corrupted)
        let attrs = try FileManager.default.attributesOfItem(atPath: pdfURL.path)
        let fileSize = attrs[.size] as? Int ?? 0
        XCTAssertGreaterThan(fileSize, 1000, "PDF should be larger than 1KB, got \(fileSize) bytes")
        
        // Copy PDF to Desktop for easy access
        let desktopPath = NSHomeDirectory() + "/../../../../../../Desktop/NestoryTestPDFs"
        try? FileManager.default.createDirectory(atPath: desktopPath, withIntermediateDirectories: true)
        let destPath = desktopPath + "/FullInventoryReport_Test.pdf"
        try? FileManager.default.removeItem(atPath: destPath)
        try? FileManager.default.copyItem(at: pdfURL, to: URL(fileURLWithPath: destPath))
        
        // Attach PDF to test results for viewing in Xcode
        let pdfData = try Data(contentsOf: pdfURL)
        let attachment = XCTAttachment(data: pdfData, uniformTypeIdentifier: "com.adobe.pdf")
        attachment.name = "FullInventoryReport.pdf"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Loss List Report Test
    
    @MainActor
    func testGenerateLossListPDF_ProducesValidFile() async throws {
        // Arrange
        let container = try NestoryModelContainer.createForTesting()
        let context = container.mainContext
        
        // Create minimal test data
        let room = Room(name: "Test Room", iconName: "house", sortOrder: 0)
        context.insert(room)
        
        let category = Nestory_Pro.Category(name: "Test Category", iconName: "tag", colorHex: "#007AFF", sortOrder: 0)
        context.insert(category)
        
        // Create test items
        for i in 1...5 {
            let item = Item(
                name: "Lost Item \(i)",
                purchasePrice: Decimal(i * 100),
                category: category,
                room: room,
                condition: .good
            )
            context.insert(item)
        }
        try context.save()
        
        let items = try context.fetch(FetchDescriptor<Item>())
        XCTAssertEqual(items.count, 5)
        
        let incident = IncidentDetails(
            incidentDate: Date(),
            incidentType: .fire,
            description: "Test fire incident"
        )
        
        // Act
        let reportGenerator = ReportGeneratorService.shared
        let pdfURL = try await reportGenerator.generateLossListPDF(items: items, incident: incident)
        
        // Verify
        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
        
        let pdfDocument = PDFDocument(url: pdfURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0)
        
        // Copy to Desktop
        let desktopPath = NSHomeDirectory() + "/../../../../../../Desktop/NestoryTestPDFs"
        try? FileManager.default.createDirectory(atPath: desktopPath, withIntermediateDirectories: true)
        let destPath = desktopPath + "/LossListReport_Test.pdf"
        try? FileManager.default.removeItem(atPath: destPath)
        try? FileManager.default.copyItem(at: pdfURL, to: URL(fileURLWithPath: destPath))
        
        // Attach PDF to test results
        let pdfData = try Data(contentsOf: pdfURL)
        let attachment = XCTAttachment(data: pdfData, uniformTypeIdentifier: "com.adobe.pdf")
        attachment.name = "LossListReport.pdf"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

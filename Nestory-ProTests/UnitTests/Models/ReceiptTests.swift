//
//  ReceiptTests.swift
//  Nestory-ProTests
//
//  Unit tests for Receipt model
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class ReceiptTests: XCTestCase {

    // MARK: - Initialization Tests

    func testReceipt_InitWithRequiredFields_SetsDefaults() async {
        // Arrange & Act
        let receipt = Receipt(imageIdentifier: "test-receipt-123")

        // Assert
        XCTAssertEqual(receipt.imageIdentifier, "test-receipt-123")
        XCTAssertNil(receipt.vendor)
        XCTAssertNil(receipt.total)
        XCTAssertNil(receipt.taxAmount)
        XCTAssertNil(receipt.purchaseDate)
        XCTAssertNil(receipt.rawText)
        XCTAssertEqual(receipt.confidence, 0.0)
        XCTAssertNil(receipt.linkedItem)
        XCTAssertNotNil(receipt.id)
        XCTAssertNotNil(receipt.createdAt)
    }

    func testReceipt_InitWithAllFields_SetsCorrectly() async {
        // Arrange
        let testDate = TestFixtures.referenceDate

        // Act
        let receipt = Receipt(
            imageIdentifier: "receipt-full",
            vendor: "Apple Store",
            total: Decimal(2999.00),
            taxAmount: Decimal(239.92),
            purchaseDate: testDate,
            rawText: "Apple Store\nMacBook Pro\n$2,999.00",
            confidence: 0.95
        )

        // Assert
        XCTAssertEqual(receipt.vendor, "Apple Store")
        XCTAssertEqual(receipt.total, Decimal(2999.00))
        XCTAssertEqual(receipt.taxAmount, Decimal(239.92))
        XCTAssertEqual(receipt.purchaseDate, testDate)
        XCTAssertEqual(receipt.rawText, "Apple Store\nMacBook Pro\n$2,999.00")
        XCTAssertEqual(receipt.confidence, 0.95)
    }

    // MARK: - Confidence Score Tests

    func testReceipt_ConfidenceZero_IsValid() async {
        // Arrange & Act
        let receipt = Receipt(
            imageIdentifier: "low-conf",
            confidence: 0.0
        )

        // Assert
        XCTAssertEqual(receipt.confidence, 0.0)
    }

    func testReceipt_ConfidenceOne_IsValid() async {
        // Arrange & Act
        let receipt = Receipt(
            imageIdentifier: "high-conf",
            confidence: 1.0
        )

        // Assert
        XCTAssertEqual(receipt.confidence, 1.0)
    }

    func testReceipt_ConfidenceOutOfRange_IsNotValidated() async {
        // Arrange & Act - Model doesn't enforce 0-1 range
        let receipt = Receipt(
            imageIdentifier: "invalid-conf",
            confidence: 1.5
        )

        // Assert - Model accepts it (validation is elsewhere)
        XCTAssertEqual(receipt.confidence, 1.5)
    }

    // MARK: - OCR Text Tests

    func testReceipt_LongRawText_IsPreserved() async {
        // Arrange
        let longText = String(repeating: "Receipt line item with details\n", count: 100)

        // Act
        let receipt = Receipt(
            imageIdentifier: "long-text",
            rawText: longText
        )

        // Assert
        XCTAssertEqual(receipt.rawText, longText)
    }

    func testReceipt_SpecialCharactersInText_ArePreserved() async {
        // Arrange
        let specialText = """
        APPLE STORE
        123 Main St. • San Francisco, CA
        —————————————————
        MacBook Pro 16" M3 Max™
        Qty: 1 × $2,999.00
        Tax (8.625%): $258.66
        TOTAL: $3,257.66
        ★ Thank you! ★
        """

        // Act
        let receipt = Receipt(
            imageIdentifier: "special-chars",
            rawText: specialText
        )

        // Assert
        XCTAssertEqual(receipt.rawText, specialText)
    }

    // MARK: - Relationship Tests

    func testReceipt_LinkToItem_Works() async throws {
        await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let item = TestFixtures.testItem()
            context.insert(item)

            let receipt = TestFixtures.testReceipt()
            context.insert(receipt)

            // Act
            receipt.linkedItem = item

            try? context.save()

            // Assert
            XCTAssertEqual(receipt.linkedItem?.id, item.id)
            XCTAssertTrue(item.receipts.contains(receipt))
        }
    }

    func testReceipt_UnlinkFromItem_Works() async throws {
        await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let item = TestFixtures.testItem()
            context.insert(item)

            let receipt = TestFixtures.testReceipt(linkedItem: item)
            context.insert(receipt)

            try? context.save()

            XCTAssertNotNil(receipt.linkedItem)

            // Act
            receipt.linkedItem = nil
            try? context.save()

            // Assert
            XCTAssertNil(receipt.linkedItem)
        }
    }

    // MARK: - Decimal Edge Cases

    func testReceipt_ZeroTotal_IsValid() async {
        // Arrange & Act (e.g., free items, store credits)
        let receipt = Receipt(
            imageIdentifier: "zero-total",
            total: Decimal(0)
        )

        // Assert
        XCTAssertEqual(receipt.total, Decimal(0))
    }

    func testReceipt_NegativeTotal_IsValid() async {
        // Arrange & Act (refunds)
        let receipt = Receipt(
            imageIdentifier: "refund",
            total: Decimal(-150.00)
        )

        // Assert
        XCTAssertEqual(receipt.total, Decimal(-150.00))
    }

    func testReceipt_TaxGreaterThanTotal_IsNotValidated() async {
        // Arrange & Act - Model doesn't validate tax logic
        let receipt = Receipt(
            imageIdentifier: "bad-tax",
            total: Decimal(100.00),
            taxAmount: Decimal(500.00)
        )

        // Assert
        XCTAssertEqual(receipt.total, Decimal(100.00))
        XCTAssertEqual(receipt.taxAmount, Decimal(500.00))
    }

    // MARK: - UUID Tests

    func testReceipt_HasUniqueUUID_OnCreation() async {
        // Arrange & Act
        let receipt1 = Receipt(imageIdentifier: "receipt-1")
        let receipt2 = Receipt(imageIdentifier: "receipt-2")

        // Assert
        XCTAssertNotEqual(receipt1.id, receipt2.id)
    }

    // MARK: - Timestamp Tests

    func testReceipt_CreatedAt_IsSetOnInit() async {
        // Arrange
        let before = Date()

        // Act
        let receipt = Receipt(imageIdentifier: "timestamp-test")

        let after = Date()

        // Assert
        XCTAssertGreaterThanOrEqual(receipt.createdAt, before)
        XCTAssertLessThanOrEqual(receipt.createdAt, after)
    }
}

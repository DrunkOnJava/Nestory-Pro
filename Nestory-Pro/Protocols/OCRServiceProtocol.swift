//
//  OCRServiceProtocol.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import VisionKit

/// Protocol for OCR text recognition services
protocol OCRServiceProtocol: Sendable {
    /// Processes an image and extracts text via OCR
    /// - Parameter imageIdentifier: Identifier for the image to process
    /// - Returns: Tuple containing extracted text and confidence score (0.0-1.0)
    /// - Throws: Error if OCR processing fails
    func recognizeText(from imageIdentifier: String) async throws -> (text: String, confidence: Double)

    /// Processes receipt image and extracts structured data
    /// - Parameter imageIdentifier: Identifier for the receipt image
    /// - Returns: Parsed receipt data including vendor, total, tax, and date
    /// - Throws: Error if OCR processing fails
    func processReceipt(from imageIdentifier: String) async throws -> ReceiptData
}

/// Structured receipt data extracted from OCR
/// Note: nonisolated required to prevent MainActor inference in Swift 6
nonisolated struct ReceiptData: Sendable {
    let vendor: String?
    let total: Decimal?
    let taxAmount: Decimal?
    let purchaseDate: Date?
    let rawText: String
    let confidence: Double

    init(
        vendor: String? = nil,
        total: Decimal? = nil,
        taxAmount: Decimal? = nil,
        purchaseDate: Date? = nil,
        rawText: String = "",
        confidence: Double = 0.0
    ) {
        self.vendor = vendor
        self.total = total
        self.taxAmount = taxAmount
        self.purchaseDate = purchaseDate
        self.rawText = rawText
        self.confidence = confidence
    }
}

//
//  MockOCRService.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/28/25.
//

import Foundation
@testable import Nestory_Pro

/// Mock implementation of OCRServiceProtocol for testing
final class MockOCRService: OCRServiceProtocol {
    // MARK: - Mock Configuration
    var recognizedText: String = "Mock OCR Text"
    var recognizedConfidence: Double = 0.95
    var shouldThrowError: Bool = false
    var errorToThrow: Error = OCRError.processingFailed

    // Mock receipt data
    var mockReceiptData = ReceiptData(
        vendor: "Mock Store",
        total: 99.99,
        taxAmount: 8.99,
        purchaseDate: Date(),
        rawText: "Mock receipt text",
        confidence: 0.95
    )

    // MARK: - Call Tracking
    var recognizeTextCallCount = 0
    var processReceiptCallCount = 0
    var lastProcessedImageIdentifier: String?

    // MARK: - OCRServiceProtocol
    func recognizeText(from imageIdentifier: String) async throws -> (text: String, confidence: Double) {
        recognizeTextCallCount += 1
        lastProcessedImageIdentifier = imageIdentifier

        if shouldThrowError {
            throw errorToThrow
        }

        return (recognizedText, recognizedConfidence)
    }

    func processReceipt(from imageIdentifier: String) async throws -> ReceiptData {
        processReceiptCallCount += 1
        lastProcessedImageIdentifier = imageIdentifier

        if shouldThrowError {
            throw errorToThrow
        }

        return mockReceiptData
    }

    // MARK: - Test Helpers
    func reset() {
        recognizedText = "Mock OCR Text"
        recognizedConfidence = 0.95
        shouldThrowError = false
        errorToThrow = OCRError.processingFailed
        mockReceiptData = ReceiptData(
            vendor: "Mock Store",
            total: 99.99,
            taxAmount: 8.99,
            purchaseDate: Date(),
            rawText: "Mock receipt text",
            confidence: 0.95
        )
        recognizeTextCallCount = 0
        processReceiptCallCount = 0
        lastProcessedImageIdentifier = nil
    }
}

// MARK: - Mock Errors
enum OCRError: Error, Sendable {
    case processingFailed
    case invalidImage
    case noTextFound
}

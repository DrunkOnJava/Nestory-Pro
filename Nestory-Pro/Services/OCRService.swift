//
//  OCRService.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: OCR SERVICE
// ============================================================================
// Task 2.3.1: Implements OCRServiceProtocol using Vision framework
// - Uses VNRecognizeTextRequest for text extraction
// - Parses vendor, total, date, tax from raw text
// - Returns confidence score (0.0-1.0)
//
// SEE: TODO.md Phase 2 | OCRServiceProtocol.swift | MockOCRService.swift
// ============================================================================

import Foundation
import Vision
import UIKit
import OSLog

/// OCR service using Apple's Vision framework for text recognition
actor OCRService: OCRServiceProtocol {
    static let shared = OCRService()

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "OCRService")
    private let photoStorage: PhotoStorageService

    // MARK: - Initialization

    private init(photoStorage: PhotoStorageService = .shared) {
        self.photoStorage = photoStorage
    }

    // MARK: - OCRServiceProtocol Implementation

    func recognizeText(from imageIdentifier: String) async throws -> (text: String, confidence: Double) {
        // Load the image
        let image = try await photoStorage.loadPhoto(identifier: imageIdentifier)

        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        // Perform OCR
        let (text, confidence) = try await performOCR(on: cgImage)

        logger.info("OCR complete: \(text.count) chars, confidence: \(confidence)")
        return (text, confidence)
    }

    func processReceipt(from imageIdentifier: String) async throws -> ReceiptData {
        let (rawText, confidence) = try await recognizeText(from: imageIdentifier)

        // Parse structured data from text
        let vendor = parseVendor(from: rawText)
        let total = parseTotal(from: rawText)
        let tax = parseTax(from: rawText)
        let date = parseDate(from: rawText)

        logger.info("Receipt parsed: vendor=\(vendor ?? "nil"), total=\(String(describing: total)), tax=\(String(describing: tax))")

        return ReceiptData(
            vendor: vendor,
            total: total,
            taxAmount: tax,
            purchaseDate: date,
            rawText: rawText,
            confidence: confidence
        )
    }

    // MARK: - Core OCR Engine

    private func performOCR(on cgImage: CGImage) async throws -> (String, Double) {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: ("", 0.0))
                    return
                }

                // Extract text and calculate average confidence
                var allText: [String] = []
                var totalConfidence: Float = 0

                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        allText.append(topCandidate.string)
                        totalConfidence += topCandidate.confidence
                    }
                }

                let text = allText.joined(separator: "\n")
                let avgConfidence = observations.isEmpty ? 0.0 : Double(totalConfidence / Float(observations.count))

                continuation.resume(returning: (text, avgConfidence))
            }

            // Configure for best accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            // Execute the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }

    // MARK: - Receipt Parsing Helpers

    /// Attempts to extract vendor name from receipt text
    /// Usually the first meaningful line (not a date/address)
    private func parseVendor(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Skip lines that look like addresses, dates, or phone numbers
        for line in lines.prefix(5) {
            // Skip if looks like a date
            if containsDatePattern(line) { continue }

            // Skip if looks like a phone number
            if line.range(of: #"\d{3}[-.\s]?\d{3}[-.\s]?\d{4}"#, options: .regularExpression) != nil {
                continue
            }

            // Skip if looks like an address (contains state abbreviations + zip)
            if line.range(of: #"[A-Z]{2}\s+\d{5}"#, options: .regularExpression) != nil {
                continue
            }

            // Skip very short lines
            if line.count < 3 { continue }

            // This might be the vendor name
            return line
        }

        return nil
    }

    /// Extracts total amount from receipt
    /// Looks for patterns like "Total: $XX.XX" or "TOTAL $XX.XX"
    private func parseTotal(from text: String) -> Decimal? {
        // Common patterns for total
        // OPTIMIZE: Consider using a more sophisticated NLP approach for complex receipts
        let patterns = [
            #"(?i)(?:grand\s*)?total[\s:]*\$?\s*(\d+[,.]?\d*\.?\d{0,2})"#,
            #"(?i)amount\s*due[\s:]*\$?\s*(\d+[,.]?\d*\.?\d{0,2})"#,
            #"(?i)balance[\s:]*\$?\s*(\d+[,.]?\d*\.?\d{0,2})"#
        ]

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let matchText = String(text[match])
                if let amount = extractAmount(from: matchText) {
                    return amount
                }
            }
        }

        return nil
    }

    /// Extracts tax amount from receipt
    private func parseTax(from text: String) -> Decimal? {
        let patterns = [
            #"(?i)(?:sales\s*)?tax[\s:]*\$?\s*(\d+[,.]?\d*\.?\d{0,2})"#,
            #"(?i)HST[\s:]*\$?\s*(\d+[,.]?\d*\.?\d{0,2})"#,
            #"(?i)GST[\s:]*\$?\s*(\d+[,.]?\d*\.?\d{0,2})"#,
            #"(?i)VAT[\s:]*\$?\s*(\d+[,.]?\d*\.?\d{0,2})"#
        ]

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let matchText = String(text[match])
                if let amount = extractAmount(from: matchText) {
                    return amount
                }
            }
        }

        return nil
    }

    /// Extracts purchase date from receipt
    private func parseDate(from text: String) -> Date? {
        // Common date formats on receipts
        let patterns = [
            #"\d{1,2}/\d{1,2}/\d{2,4}"#,      // MM/DD/YYYY or M/D/YY
            #"\d{1,2}-\d{1,2}-\d{2,4}"#,      // MM-DD-YYYY
            #"\d{4}-\d{2}-\d{2}"#,            // YYYY-MM-DD (ISO)
            #"[A-Z][a-z]{2}\s+\d{1,2},?\s+\d{4}"#  // Jan 15, 2024
        ]

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let dateString = String(text[match])
                if let date = parseFoundDateString(dateString) {
                    return date
                }
            }
        }

        return nil
    }

    // MARK: - Parsing Utilities

    private func extractAmount(from text: String) -> Decimal? {
        // Extract numeric value, handling commas in numbers
        let pattern = #"(\d+[,.]?\d*\.?\d{0,2})"#

        guard let match = text.range(of: pattern, options: .regularExpression) else {
            return nil
        }

        var numberString = String(text[match])
            .replacingOccurrences(of: ",", with: "") // Remove thousand separators

        // Handle European comma as decimal
        if numberString.filter({ $0 == "." }).count > 1 {
            // Multiple dots - probably European format with . as thousand sep
            numberString = numberString.replacingOccurrences(of: ".", with: "")
        }

        return Decimal(string: numberString)
    }

    private func containsDatePattern(_ text: String) -> Bool {
        let datePatterns = [
            #"\d{1,2}/\d{1,2}/\d{2,4}"#,
            #"\d{1,2}-\d{1,2}-\d{2,4}"#,
            #"[A-Z][a-z]{2}\s+\d{1,2}"#
        ]

        for pattern in datePatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    private func parseFoundDateString(_ dateString: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = [
                "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy", "M/d/yy",
                "MM-dd-yyyy", "MM-dd-yy",
                "yyyy-MM-dd",
                "MMM d, yyyy", "MMM dd, yyyy"
            ]

            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }
}

// MARK: - Error Types

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(Error)
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return String(localized: "Invalid image format for OCR", comment: "OCR error")
        case .recognitionFailed(let error):
            return String(localized: "Text recognition failed: \(error.localizedDescription)", comment: "OCR error")
        case .noTextFound:
            return String(localized: "No text found in image", comment: "OCR error")
        }
    }
}

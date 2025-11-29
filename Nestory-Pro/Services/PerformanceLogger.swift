//
//  PerformanceLogger.swift
//  Nestory-Pro
//
//  Performance optimization: os_signpost logging for Instruments profiling
//

import Foundation
import os.signpost

/// Centralized performance logging using os_signpost
/// Use Instruments "Points of Interest" or "os_signpost" to visualize
enum PerformanceLogger {

    // MARK: - Log Handles

    private static let subsystem = "com.drunkonjava.nestory"

    static let photoOperations = OSLog(subsystem: subsystem, category: "PhotoOperations")
    static let pdfGeneration = OSLog(subsystem: subsystem, category: "PDFGeneration")
    static let ocrProcessing = OSLog(subsystem: subsystem, category: "OCRProcessing")
    static let dataOperations = OSLog(subsystem: subsystem, category: "DataOperations")

    // MARK: - Signpost IDs

    /// Creates a unique signpost ID for tracking an operation
    static func makeSignpostID(_ log: OSLog) -> OSSignpostID {
        OSSignpostID(log: log)
    }

    // MARK: - Photo Operations

    static func beginPhotoSave(_ id: OSSignpostID) {
        os_signpost(.begin, log: photoOperations, name: "Photo Save", signpostID: id)
    }

    static func endPhotoSave(_ id: OSSignpostID, identifier: String) {
        os_signpost(.end, log: photoOperations, name: "Photo Save", signpostID: id, "identifier: %{public}@", identifier)
    }

    static func beginPhotoResize(_ id: OSSignpostID, originalSize: CGSize) {
        os_signpost(.begin, log: photoOperations, name: "Photo Resize", signpostID: id, "original: %.0fx%.0f", originalSize.width, originalSize.height)
    }

    static func endPhotoResize(_ id: OSSignpostID, newSize: CGSize) {
        os_signpost(.end, log: photoOperations, name: "Photo Resize", signpostID: id, "resized: %.0fx%.0f", newSize.width, newSize.height)
    }

    // MARK: - PDF Generation

    static func beginPDFGeneration(_ id: OSSignpostID, itemCount: Int) {
        os_signpost(.begin, log: pdfGeneration, name: "PDF Generation", signpostID: id, "items: %d", itemCount)
    }

    static func endPDFGeneration(_ id: OSSignpostID, pageCount: Int) {
        os_signpost(.end, log: pdfGeneration, name: "PDF Generation", signpostID: id, "pages: %d", pageCount)
    }

    static func beginPhotoPrefetch(_ id: OSSignpostID, count: Int) {
        os_signpost(.begin, log: pdfGeneration, name: "Photo Prefetch", signpostID: id, "count: %d", count)
    }

    static func endPhotoPrefetch(_ id: OSSignpostID) {
        os_signpost(.end, log: pdfGeneration, name: "Photo Prefetch", signpostID: id)
    }

    // MARK: - OCR Processing

    static func beginOCR(_ id: OSSignpostID) {
        os_signpost(.begin, log: ocrProcessing, name: "OCR Recognition", signpostID: id)
    }

    static func endOCR(_ id: OSSignpostID, characterCount: Int, confidence: Double) {
        os_signpost(.end, log: ocrProcessing, name: "OCR Recognition", signpostID: id, "chars: %d, conf: %.2f", characterCount, confidence)
    }

    // MARK: - Data Operations

    static func beginDataFetch(_ id: OSSignpostID, entity: String) {
        os_signpost(.begin, log: dataOperations, name: "Data Fetch", signpostID: id, "entity: %{public}@", entity)
    }

    static func endDataFetch(_ id: OSSignpostID, count: Int) {
        os_signpost(.end, log: dataOperations, name: "Data Fetch", signpostID: id, "count: %d", count)
    }

    // MARK: - Convenience

    /// Measures the execution time of an async operation
    static func measure<T>(
        _ log: OSLog,
        name: StaticString,
        _ operation: () async throws -> T
    ) async rethrows -> T {
        let id = makeSignpostID(log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        defer { os_signpost(.end, log: log, name: name, signpostID: id) }
        return try await operation()
    }
}

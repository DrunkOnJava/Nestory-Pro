//
//  ColumnMapper.swift
//  Nestory-Pro
//
//  F6-02: Column mapping service for CSV import
//

// ============================================================================
// F6-02: ColumnMapper
// ============================================================================
// Maps CSV column headers to Item model fields using intelligent detection.
// - Fuzzy matching for common column name variations
// - Confidence scoring (0-1) for each mapping
// - Support for both automatic and manual mapping
// - Category/Room name resolution
//
// SEE: TODO.md F6-02 | CSVParser.swift | ImportService.swift
// ============================================================================

import Foundation
import OSLog

// MARK: - ColumnMapper

actor ColumnMapper {

    // MARK: - Types

    /// Target fields that can be mapped from CSV
    enum TargetField: String, CaseIterable, Sendable {
        case name
        case brand
        case modelNumber
        case serialNumber
        case purchasePrice
        case purchaseDate
        case warrantyExpiration
        case condition
        case notes
        case category
        case room
        case quantity

        var displayName: String {
            switch self {
            case .name: return "Item Name"
            case .brand: return "Brand"
            case .modelNumber: return "Model Number"
            case .serialNumber: return "Serial Number"
            case .purchasePrice: return "Purchase Price"
            case .purchaseDate: return "Purchase Date"
            case .warrantyExpiration: return "Warranty Expiration"
            case .condition: return "Condition"
            case .notes: return "Notes"
            case .category: return "Category"
            case .room: return "Room"
            case .quantity: return "Quantity"
            }
        }

        var isRequired: Bool {
            self == .name
        }

        /// Common header variations for auto-detection
        var headerVariations: [String] {
            switch self {
            case .name:
                return ["name", "item", "item name", "product", "product name", "title", "description", "item description"]
            case .brand:
                return ["brand", "manufacturer", "make", "company", "vendor"]
            case .modelNumber:
                return ["model", "model number", "model no", "model #", "model no.", "sku", "part number", "part no"]
            case .serialNumber:
                return ["serial", "serial number", "serial no", "serial #", "serial no.", "sn", "s/n"]
            case .purchasePrice:
                return ["price", "purchase price", "cost", "amount", "value", "paid", "purchase amount", "item price", "retail price", "original price"]
            case .purchaseDate:
                return ["purchase date", "date purchased", "bought", "date bought", "acquired", "date acquired", "purchase", "buy date"]
            case .warrantyExpiration:
                return ["warranty", "warranty expiration", "warranty expires", "warranty end", "warranty date", "guarantee"]
            case .condition:
                return ["condition", "status", "state", "quality"]
            case .notes:
                return ["notes", "note", "comments", "comment", "remarks", "description", "details", "memo"]
            case .category:
                return ["category", "type", "group", "classification", "class", "kind"]
            case .room:
                return ["room", "location", "place", "area", "zone", "where", "stored in", "storage"]
            case .quantity:
                return ["quantity", "qty", "count", "amount", "number", "units", "pieces"]
            }
        }
    }

    /// A single column-to-field mapping
    struct ColumnMapping: Sendable, Identifiable {
        let id = UUID()
        let columnIndex: Int
        let columnHeader: String
        var targetField: TargetField?
        var confidence: Double  // 0-1, higher = more confident

        var isAutoMapped: Bool {
            confidence > 0
        }
    }

    /// Result of mapping analysis
    struct MappingResult: Sendable {
        let mappings: [ColumnMapping]
        let unmappedColumns: [Int]
        let missingRequiredFields: [TargetField]
        let warnings: [String]

        var isValid: Bool {
            missingRequiredFields.isEmpty
        }

        var mappedFieldCount: Int {
            mappings.filter { $0.targetField != nil }.count
        }
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "ColumnMapper")

    // MARK: - Public API

    /// Analyze CSV headers and suggest column mappings
    /// - Parameter headers: Array of column header strings from CSV
    /// - Returns: MappingResult with suggested mappings and validation info
    func analyzeHeaders(_ headers: [String]) async -> MappingResult {
        logger.info("Analyzing \(headers.count) CSV headers")

        var mappings: [ColumnMapping] = []
        var usedFields: Set<TargetField> = []

        // First pass: exact and fuzzy matching
        for (index, header) in headers.enumerated() {
            let normalizedHeader = normalizeHeader(header)

            // Try to find best matching field
            var bestMatch: (field: TargetField, confidence: Double)?

            for field in TargetField.allCases {
                guard !usedFields.contains(field) else { continue }

                let confidence = calculateConfidence(header: normalizedHeader, field: field)
                if confidence > 0.5 {
                    if bestMatch == nil || confidence > bestMatch!.confidence {
                        bestMatch = (field, confidence)
                    }
                }
            }

            let mapping = ColumnMapping(
                columnIndex: index,
                columnHeader: header,
                targetField: bestMatch?.field,
                confidence: bestMatch?.confidence ?? 0
            )

            if let field = bestMatch?.field {
                usedFields.insert(field)
            }

            mappings.append(mapping)
        }

        // Identify unmapped columns
        let unmappedColumns = mappings
            .filter { $0.targetField == nil }
            .map { $0.columnIndex }

        // Check for missing required fields
        let mappedFields = Set(mappings.compactMap { $0.targetField })
        let missingRequiredFields = TargetField.allCases
            .filter { $0.isRequired && !mappedFields.contains($0) }

        // Generate warnings
        var warnings: [String] = []

        if !missingRequiredFields.isEmpty {
            let fieldNames = missingRequiredFields.map { $0.displayName }.joined(separator: ", ")
            warnings.append("Required fields not mapped: \(fieldNames)")
        }

        if unmappedColumns.count > headers.count / 2 {
            warnings.append("More than half of columns could not be auto-mapped")
        }

        let lowConfidenceMappings = mappings.filter { $0.targetField != nil && $0.confidence < 0.7 }
        if !lowConfidenceMappings.isEmpty {
            let headers = lowConfidenceMappings.map { "\"\($0.columnHeader)\"" }.joined(separator: ", ")
            warnings.append("Low confidence mappings (review recommended): \(headers)")
        }

        logger.info("Mapped \(mappedFields.count)/\(TargetField.allCases.count) fields, \(unmappedColumns.count) unmapped columns")

        return MappingResult(
            mappings: mappings,
            unmappedColumns: unmappedColumns,
            missingRequiredFields: missingRequiredFields,
            warnings: warnings
        )
    }

    /// Update a specific column mapping
    /// - Parameters:
    ///   - result: Existing mapping result
    ///   - columnIndex: Index of column to update
    ///   - newField: New target field (nil to unmap)
    /// - Returns: Updated MappingResult
    func updateMapping(
        _ result: MappingResult,
        columnIndex: Int,
        newField: TargetField?
    ) async -> MappingResult {
        var mappings = result.mappings

        guard let mappingIndex = mappings.firstIndex(where: { $0.columnIndex == columnIndex }) else {
            return result
        }

        // If assigning a field that's already used, unmap it first
        if let newField = newField {
            for (index, mapping) in mappings.enumerated() where mapping.targetField == newField && index != mappingIndex {
                mappings[index] = ColumnMapping(
                    columnIndex: mapping.columnIndex,
                    columnHeader: mapping.columnHeader,
                    targetField: nil,
                    confidence: 0
                )
            }
        }

        // Update the target mapping
        let oldMapping = mappings[mappingIndex]
        mappings[mappingIndex] = ColumnMapping(
            columnIndex: oldMapping.columnIndex,
            columnHeader: oldMapping.columnHeader,
            targetField: newField,
            confidence: newField != nil ? 1.0 : 0  // Manual mapping = 100% confidence
        )

        // Recalculate unmapped and missing
        let unmappedColumns = mappings
            .filter { $0.targetField == nil }
            .map { $0.columnIndex }

        let mappedFields = Set(mappings.compactMap { $0.targetField })
        let missingRequiredFields = TargetField.allCases
            .filter { $0.isRequired && !mappedFields.contains($0) }

        // Update warnings
        var warnings: [String] = []
        if !missingRequiredFields.isEmpty {
            let fieldNames = missingRequiredFields.map { $0.displayName }.joined(separator: ", ")
            warnings.append("Required fields not mapped: \(fieldNames)")
        }

        return MappingResult(
            mappings: mappings,
            unmappedColumns: unmappedColumns,
            missingRequiredFields: missingRequiredFields,
            warnings: warnings
        )
    }

    // MARK: - Private Helpers

    /// Normalize header string for comparison
    private func normalizeHeader(_ header: String) -> String {
        header
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")
    }

    /// Calculate confidence score for header-field match
    private func calculateConfidence(header: String, field: TargetField) -> Double {
        let normalizedHeader = normalizeHeader(header)
        let variations = field.headerVariations

        // Exact match
        if variations.contains(normalizedHeader) {
            return 1.0
        }

        // Check if header contains any variation
        for variation in variations {
            if normalizedHeader.contains(variation) || variation.contains(normalizedHeader) {
                // Longer match = higher confidence
                let matchRatio = Double(min(normalizedHeader.count, variation.count)) /
                                 Double(max(normalizedHeader.count, variation.count))
                return 0.6 + (matchRatio * 0.3)  // 0.6-0.9 range
            }
        }

        // Levenshtein distance for fuzzy matching
        var bestScore: Double = 0
        for variation in variations {
            let distance = levenshteinDistance(normalizedHeader, variation)
            let maxLength = max(normalizedHeader.count, variation.count)
            guard maxLength > 0 else { continue }

            let similarity = 1.0 - (Double(distance) / Double(maxLength))
            if similarity > 0.7 {  // At least 70% similar
                bestScore = max(bestScore, similarity * 0.8)  // Cap at 0.8 for fuzzy
            }
        }

        return bestScore
    }

    /// Calculate Levenshtein edit distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }
}

// MARK: - Value Parsing Helpers

extension ColumnMapper {

    /// Parse a price string into Decimal
    static func parsePrice(_ string: String) -> Decimal? {
        let cleaned = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Decimal(string: cleaned)
    }

    /// Parse various date formats
    static func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try common formats
        let formatters: [DateFormatter] = [
            createFormatter("yyyy-MM-dd"),
            createFormatter("MM/dd/yyyy"),
            createFormatter("dd/MM/yyyy"),
            createFormatter("MM-dd-yyyy"),
            createFormatter("dd-MM-yyyy"),
            createFormatter("yyyy/MM/dd"),
            createFormatter("MMM d, yyyy"),
            createFormatter("MMMM d, yyyy"),
            createFormatter("d MMM yyyy"),
            createFormatter("d MMMM yyyy"),
        ]

        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        // Try ISO8601
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        if let date = iso.date(from: trimmed) {
            return date
        }

        return nil
    }

    private static func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    /// Parse quantity string to Int
    static func parseQuantity(_ string: String) -> Int? {
        let cleaned = string
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Int(cleaned)
    }

    /// Parse condition string to ItemCondition
    static func parseCondition(_ string: String) -> String {
        let normalized = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Map common variations
        switch normalized {
        case "new", "brand new", "mint", "excellent":
            return "new"
        case "like new", "very good", "great":
            return "likeNew"
        case "good", "nice":
            return "good"
        case "fair", "ok", "okay", "average":
            return "fair"
        case "poor", "bad", "damaged", "broken":
            return "poor"
        default:
            return "good"  // Default condition
        }
    }
}

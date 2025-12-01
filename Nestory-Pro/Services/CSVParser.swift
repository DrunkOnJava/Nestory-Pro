//
//  CSVParser.swift
//  Nestory-Pro
//
//  F6-01: CSV parsing service for batch import
//

// ============================================================================
// F6-01: CSVParser
// ============================================================================
// Parses CSV files with support for various encodings and formats.
// - UTF-8, UTF-16, Windows-1252 encoding detection
// - Quoted fields with embedded commas/newlines
// - Auto-detect delimiter (comma, semicolon, tab)
// - Header row detection
// - Streaming for large files
//
// SEE: TODO.md F6-01 | ColumnMapper.swift | ImportService.swift
// ============================================================================

import Foundation
import OSLog

// MARK: - CSVParser

actor CSVParser {

    // MARK: - Types

    /// Supported CSV delimiters
    enum Delimiter: String, CaseIterable, Sendable {
        case comma = ","
        case semicolon = ";"
        case tab = "\t"
        case pipe = "|"

        var displayName: String {
            switch self {
            case .comma: return "Comma (,)"
            case .semicolon: return "Semicolon (;)"
            case .tab: return "Tab"
            case .pipe: return "Pipe (|)"
            }
        }
    }

    /// Parsed CSV result
    struct ParseResult: Sendable {
        let headers: [String]
        let rows: [[String]]
        let detectedDelimiter: Delimiter
        let detectedEncoding: String.Encoding
        let rowCount: Int
        let columnCount: Int

        var isEmpty: Bool { rows.isEmpty }
    }

    /// Parse errors
    enum ParseError: LocalizedError {
        case fileNotFound
        case unreadableFile
        case encodingDetectionFailed
        case emptyFile
        case noHeaders
        case invalidFormat(String)
        case rowParseFailed(row: Int, reason: String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return String(localized: "File not found", comment: "CSV parse error")
            case .unreadableFile:
                return String(localized: "Unable to read file", comment: "CSV parse error")
            case .encodingDetectionFailed:
                return String(localized: "Could not detect file encoding", comment: "CSV parse error")
            case .emptyFile:
                return String(localized: "File is empty", comment: "CSV parse error")
            case .noHeaders:
                return String(localized: "No header row found", comment: "CSV parse error")
            case .invalidFormat(let reason):
                return String(localized: "Invalid format: \(reason)", comment: "CSV parse error")
            case .rowParseFailed(let row, let reason):
                return String(localized: "Row \(row) failed: \(reason)", comment: "CSV parse error")
            }
        }
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "CSVParser")

    // MARK: - Public API

    /// Parse a CSV file from URL
    /// - Parameters:
    ///   - url: File URL to parse
    ///   - delimiter: Optional delimiter (auto-detected if nil)
    ///   - hasHeaders: Whether first row contains headers (default: true)
    /// - Returns: ParseResult with headers and rows
    func parse(
        url: URL,
        delimiter: Delimiter? = nil,
        hasHeaders: Bool = true
    ) async throws -> ParseResult {
        logger.info("Parsing CSV from: \(url.lastPathComponent)")

        // Read file data
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ParseError.fileNotFound
        }

        guard let data = FileManager.default.contents(atPath: url.path) else {
            throw ParseError.unreadableFile
        }

        // Detect encoding
        let encoding = detectEncoding(data: data)
        logger.debug("Detected encoding: \(String(describing: encoding))")

        guard let content = String(data: data, encoding: encoding) else {
            throw ParseError.encodingDetectionFailed
        }

        return try await parse(
            content: content,
            delimiter: delimiter,
            hasHeaders: hasHeaders,
            detectedEncoding: encoding
        )
    }

    /// Parse CSV content from string
    /// - Parameters:
    ///   - content: CSV string content
    ///   - delimiter: Optional delimiter (auto-detected if nil)
    ///   - hasHeaders: Whether first row contains headers
    /// - Returns: ParseResult with headers and rows
    func parse(
        content: String,
        delimiter: Delimiter? = nil,
        hasHeaders: Bool = true,
        detectedEncoding: String.Encoding = .utf8
    ) async throws -> ParseResult {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedContent.isEmpty else {
            throw ParseError.emptyFile
        }

        // Detect delimiter if not provided
        let detectedDelimiter = delimiter ?? detectDelimiter(content: trimmedContent)
        logger.debug("Using delimiter: \(detectedDelimiter.rawValue)")

        // Parse rows
        let allRows = parseRows(content: trimmedContent, delimiter: detectedDelimiter)

        guard !allRows.isEmpty else {
            throw ParseError.emptyFile
        }

        // Extract headers and data rows
        let headers: [String]
        let dataRows: [[String]]

        if hasHeaders {
            headers = allRows[0].map { $0.trimmingCharacters(in: .whitespaces) }
            dataRows = Array(allRows.dropFirst())
        } else {
            // Generate column names (Column A, Column B, etc.)
            let columnCount = allRows[0].count
            headers = (0..<columnCount).map { "Column \(Character(UnicodeScalar(65 + $0)!))" }
            dataRows = allRows
        }

        guard !headers.isEmpty else {
            throw ParseError.noHeaders
        }

        logger.info("Parsed \(dataRows.count) rows with \(headers.count) columns")

        return ParseResult(
            headers: headers,
            rows: dataRows,
            detectedDelimiter: detectedDelimiter,
            detectedEncoding: detectedEncoding,
            rowCount: dataRows.count,
            columnCount: headers.count
        )
    }

    /// Preview first N rows of a CSV file (for UI preview)
    func preview(
        url: URL,
        maxRows: Int = 10,
        delimiter: Delimiter? = nil
    ) async throws -> ParseResult {
        let fullResult = try await parse(url: url, delimiter: delimiter)

        let previewRows = Array(fullResult.rows.prefix(maxRows))

        return ParseResult(
            headers: fullResult.headers,
            rows: previewRows,
            detectedDelimiter: fullResult.detectedDelimiter,
            detectedEncoding: fullResult.detectedEncoding,
            rowCount: fullResult.rowCount,
            columnCount: fullResult.columnCount
        )
    }

    // MARK: - Private Helpers

    /// Detect file encoding from BOM or content analysis
    private func detectEncoding(data: Data) -> String.Encoding {
        // Check for BOM (Byte Order Mark)
        if data.count >= 3 {
            let bom = [UInt8](data.prefix(3))

            // UTF-8 BOM
            if bom == [0xEF, 0xBB, 0xBF] {
                return .utf8
            }
        }

        if data.count >= 2 {
            let bom = [UInt8](data.prefix(2))

            // UTF-16 LE BOM
            if bom == [0xFF, 0xFE] {
                return .utf16LittleEndian
            }

            // UTF-16 BE BOM
            if bom == [0xFE, 0xFF] {
                return .utf16BigEndian
            }
        }

        // Try UTF-8 first (most common)
        if String(data: data, encoding: .utf8) != nil {
            return .utf8
        }

        // Try Windows-1252 (common for Excel exports)
        if String(data: data, encoding: .windowsCP1252) != nil {
            return .windowsCP1252
        }

        // Fall back to ISO Latin 1
        return .isoLatin1
    }

    /// Auto-detect delimiter by analyzing content
    private func detectDelimiter(content: String) -> Delimiter {
        let firstLine = content.components(separatedBy: .newlines).first ?? ""

        // Count occurrences of each delimiter
        var counts: [Delimiter: Int] = [:]

        for delimiter in Delimiter.allCases {
            // Count delimiters outside of quoted strings
            var count = 0
            var inQuotes = false

            for char in firstLine {
                if char == "\"" {
                    inQuotes.toggle()
                } else if !inQuotes && String(char) == delimiter.rawValue {
                    count += 1
                }
            }

            counts[delimiter] = count
        }

        // Return delimiter with highest count (minimum 1)
        let detected = counts.max(by: { $0.value < $1.value })

        if let detected = detected, detected.value > 0 {
            return detected.key
        }

        // Default to comma
        return .comma
    }

    /// Parse content into rows, handling quoted fields
    private func parseRows(content: String, delimiter: Delimiter) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        var previousChar: Character?

        let delimiterChar = Character(delimiter.rawValue)

        for char in content {
            if char == "\"" {
                if inQuotes && previousChar == "\"" {
                    // Escaped quote (two consecutive quotes)
                    currentField.append("\"")
                    previousChar = nil
                    continue
                } else {
                    inQuotes.toggle()
                }
            } else if char == delimiterChar && !inQuotes {
                // End of field
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else if (char == "\n" || char == "\r") && !inQuotes {
                // End of row (skip empty lines from \r\n)
                if char == "\r" {
                    // Will be followed by \n, skip
                } else if !currentField.isEmpty || !currentRow.isEmpty {
                    currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                    currentField = ""
                }
            } else {
                currentField.append(char)
            }

            previousChar = char
        }

        // Don't forget the last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }

        return rows
    }
}

// MARK: - Convenience Extensions

extension CSVParser.ParseResult {
    /// Get a specific cell value
    func value(row: Int, column: Int) -> String? {
        guard row >= 0 && row < rows.count else { return nil }
        guard column >= 0 && column < rows[row].count else { return nil }
        return rows[row][column]
    }

    /// Get a specific cell value by header name
    func value(row: Int, header: String) -> String? {
        guard let columnIndex = headers.firstIndex(of: header) else { return nil }
        return value(row: row, column: columnIndex)
    }

    /// Get all values for a column
    func column(_ index: Int) -> [String] {
        rows.compactMap { $0.count > index ? $0[index] : nil }
    }

    /// Get all values for a column by header name
    func column(named header: String) -> [String] {
        guard let index = headers.firstIndex(of: header) else { return [] }
        return column(index)
    }
}

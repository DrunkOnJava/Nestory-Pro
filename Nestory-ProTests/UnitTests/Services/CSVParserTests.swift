//
//  CSVParserTests.swift
//  Nestory-ProTests
//
//  F6-11: Unit tests for CSV parsing
//

import XCTest
@testable import Nestory_Pro

final class CSVParserTests: XCTestCase {

    var sut: CSVParser!

    override func setUp() {
        super.setUp()
        sut = CSVParser()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Parsing Tests

    func testParseSimpleCSV_WithCommaDelimiter_ParsesCorrectly() async throws {
        let csv = """
        Name,Price,Category
        MacBook Pro,$2499,Electronics
        iPhone,$999,Electronics
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.headers, ["Name", "Price", "Category"])
        XCTAssertEqual(result.rowCount, 2)
        XCTAssertEqual(result.columnCount, 3)
        XCTAssertEqual(result.detectedDelimiter, .comma)
        XCTAssertEqual(result.rows[0], ["MacBook Pro", "$2499", "Electronics"])
        XCTAssertEqual(result.rows[1], ["iPhone", "$999", "Electronics"])
    }

    func testParseCSV_WithSemicolonDelimiter_DetectsCorrectly() async throws {
        let csv = """
        Name;Price;Category
        MacBook Pro;$2499;Electronics
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.detectedDelimiter, .semicolon)
        XCTAssertEqual(result.headers, ["Name", "Price", "Category"])
    }

    func testParseCSV_WithTabDelimiter_DetectsCorrectly() async throws {
        let csv = "Name\tPrice\tCategory\nMacBook Pro\t$2499\tElectronics"

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.detectedDelimiter, .tab)
        XCTAssertEqual(result.headers, ["Name", "Price", "Category"])
    }

    func testParseCSV_WithPipeDelimiter_DetectsCorrectly() async throws {
        let csv = """
        Name|Price|Category
        MacBook Pro|$2499|Electronics
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.detectedDelimiter, .pipe)
    }

    // MARK: - Quoted Fields Tests

    func testParseCSV_WithQuotedFields_HandlesCorrectly() async throws {
        let csv = """
        Name,Description,Price
        "MacBook Pro","Laptop, 16 inch",$2499
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.rows[0][0], "MacBook Pro")
        XCTAssertEqual(result.rows[0][1], "Laptop, 16 inch")
        XCTAssertEqual(result.rows[0][2], "$2499")
    }

    func testParseCSV_WithEscapedQuotes_HandlesCorrectly() async throws {
        let csv = """
        Name,Description
        "Test Item","Has ""quoted"" text"
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.rows[0][1], "Has \"quoted\" text")
    }

    func testParseCSV_WithNewlineInQuotedField_HandlesCorrectly() async throws {
        let csv = "Name,Description\n\"Item\",\"Line 1\nLine 2\""

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.rowCount, 1)
        XCTAssertTrue(result.rows[0][1].contains("\n"))
    }

    // MARK: - Header Tests

    func testParseCSV_WithoutHeaders_GeneratesColumnNames() async throws {
        let csv = """
        MacBook Pro,$2499,Electronics
        iPhone,$999,Electronics
        """

        let result = try await sut.parse(content: csv, hasHeaders: false)

        XCTAssertEqual(result.headers, ["Column A", "Column B", "Column C"])
        XCTAssertEqual(result.rowCount, 2)
    }

    func testParseCSV_TrimsWhitespaceFromHeaders() async throws {
        let csv = """
         Name , Price , Category
        MacBook Pro,$2499,Electronics
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.headers, ["Name", "Price", "Category"])
    }

    // MARK: - Edge Cases

    func testParseCSV_EmptyContent_ThrowsError() async {
        let csv = ""

        do {
            _ = try await sut.parse(content: csv)
            XCTFail("Expected error for empty content")
        } catch {
            XCTAssertTrue(error is CSVParser.ParseError)
        }
    }

    func testParseCSV_OnlyWhitespace_ThrowsError() async {
        let csv = "   \n\n   "

        do {
            _ = try await sut.parse(content: csv)
            XCTFail("Expected error for whitespace-only content")
        } catch {
            XCTAssertTrue(error is CSVParser.ParseError)
        }
    }

    func testParseCSV_SingleRow_ParsesCorrectly() async throws {
        let csv = "Name,Price"

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.headers, ["Name", "Price"])
        XCTAssertEqual(result.rowCount, 0)
    }

    func testParseCSV_UnevenRowLengths_ParsesAvailable() async throws {
        let csv = """
        Name,Price,Category
        MacBook Pro,$2499
        iPhone,$999,Electronics,Extra
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.rowCount, 2)
        XCTAssertEqual(result.rows[0].count, 2)
        XCTAssertEqual(result.rows[1].count, 4)
    }

    // MARK: - Windows Line Endings

    func testParseCSV_WithWindowsLineEndings_ParsesCorrectly() async throws {
        let csv = "Name,Price\r\nMacBook Pro,$2499\r\niPhone,$999"

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.rowCount, 2)
        XCTAssertEqual(result.headers, ["Name", "Price"])
    }

    // MARK: - Preview Tests

    func testPreview_ReturnsCorrectRowCount() async throws {
        let csv = """
        Name,Price
        Item1,$100
        Item2,$200
        Item3,$300
        Item4,$400
        Item5,$500
        """

        // Create temp file for preview test
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = try await sut.preview(url: tempURL, maxRows: 3)

        XCTAssertEqual(result.rows.count, 3)
        XCTAssertEqual(result.rowCount, 5)  // Original count preserved
    }

    // MARK: - Result Extension Tests

    func testParseResult_ValueByIndex_ReturnsCorrectValue() async throws {
        let csv = """
        Name,Price
        MacBook,$2499
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.value(row: 0, column: 0), "MacBook")
        XCTAssertEqual(result.value(row: 0, column: 1), "$2499")
        XCTAssertNil(result.value(row: 1, column: 0))
        XCTAssertNil(result.value(row: 0, column: 5))
    }

    func testParseResult_ValueByHeader_ReturnsCorrectValue() async throws {
        let csv = """
        Name,Price
        MacBook,$2499
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.value(row: 0, header: "Name"), "MacBook")
        XCTAssertEqual(result.value(row: 0, header: "Price"), "$2499")
        XCTAssertNil(result.value(row: 0, header: "Unknown"))
    }

    func testParseResult_ColumnByIndex_ReturnsAllValues() async throws {
        let csv = """
        Name,Price
        MacBook,$2499
        iPhone,$999
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.column(0), ["MacBook", "iPhone"])
        XCTAssertEqual(result.column(1), ["$2499", "$999"])
    }

    func testParseResult_ColumnByName_ReturnsAllValues() async throws {
        let csv = """
        Name,Price
        MacBook,$2499
        iPhone,$999
        """

        let result = try await sut.parse(content: csv)

        XCTAssertEqual(result.column(named: "Name"), ["MacBook", "iPhone"])
        XCTAssertEqual(result.column(named: "Unknown"), [])
    }
}

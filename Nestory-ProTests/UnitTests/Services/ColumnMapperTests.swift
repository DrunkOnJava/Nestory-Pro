//
//  ColumnMapperTests.swift
//  Nestory-ProTests
//
//  F6-11: Unit tests for column mapping
//

import XCTest
@testable import Nestory_Pro

final class ColumnMapperTests: XCTestCase {

    var sut: ColumnMapper!

    override func setUp() {
        super.setUp()
        sut = ColumnMapper()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Header Analysis Tests

    func testAnalyzeHeaders_ExactMatch_ReturnsHighConfidence() async {
        let headers = ["name", "brand", "price"]

        let result = await sut.analyzeHeaders(headers)

        let nameMapping = result.mappings.first { $0.targetField == .name }
        let brandMapping = result.mappings.first { $0.targetField == .brand }

        XCTAssertNotNil(nameMapping)
        XCTAssertNotNil(brandMapping)
        XCTAssertEqual(nameMapping?.confidence, 1.0)
        XCTAssertEqual(brandMapping?.confidence, 1.0)
    }

    func testAnalyzeHeaders_VariationMatch_DetectsCorrectly() async {
        let headers = ["Item Name", "Purchase Price", "Room"]

        let result = await sut.analyzeHeaders(headers)

        let nameMapping = result.mappings.first { $0.targetField == .name }
        let priceMapping = result.mappings.first { $0.targetField == .purchasePrice }
        let roomMapping = result.mappings.first { $0.targetField == .room }

        XCTAssertNotNil(nameMapping)
        XCTAssertNotNil(priceMapping)
        XCTAssertNotNil(roomMapping)
    }

    func testAnalyzeHeaders_UnknownHeader_RemainsUnmapped() async {
        let headers = ["name", "xyz123", "unknown_field"]

        let result = await sut.analyzeHeaders(headers)

        XCTAssertEqual(result.unmappedColumns.count, 2)
        XCTAssertTrue(result.unmappedColumns.contains(1))
        XCTAssertTrue(result.unmappedColumns.contains(2))
    }

    func testAnalyzeHeaders_MissingRequired_GeneratesWarning() async {
        let headers = ["brand", "price", "category"]

        let result = await sut.analyzeHeaders(headers)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.missingRequiredFields.contains(.name))
        XCTAssertTrue(result.warnings.contains { $0.contains("Required") })
    }

    func testAnalyzeHeaders_AllFieldsMapped_IsValid() async {
        let headers = ["name", "brand", "price"]

        let result = await sut.analyzeHeaders(headers)

        // Name is required, so if it's mapped, result should be valid
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Mapping Update Tests

    func testUpdateMapping_ChangesField_UpdatesCorrectly() async {
        let headers = ["name", "unknown"]
        let result = await sut.analyzeHeaders(headers)

        let updated = await sut.updateMapping(result, columnIndex: 1, newField: .notes)

        let notesMapping = updated.mappings.first { $0.targetField == .notes }
        XCTAssertNotNil(notesMapping)
        XCTAssertEqual(notesMapping?.columnIndex, 1)
        XCTAssertEqual(notesMapping?.confidence, 1.0)  // Manual = 100% confidence
    }

    func testUpdateMapping_UnmapsField_SetsToNil() async {
        let headers = ["name", "brand"]
        let result = await sut.analyzeHeaders(headers)

        let updated = await sut.updateMapping(result, columnIndex: 1, newField: nil)

        let brandMapping = updated.mappings.first { $0.columnIndex == 1 }
        XCTAssertNil(brandMapping?.targetField)
        XCTAssertTrue(updated.unmappedColumns.contains(1))
    }

    func testUpdateMapping_ReassignsField_UnmapsPrevious() async {
        let headers = ["name", "brand", "unknown"]
        let result = await sut.analyzeHeaders(headers)

        // Assign "brand" field to column 2 (should unmap from column 1)
        let updated = await sut.updateMapping(result, columnIndex: 2, newField: .brand)

        let col1Mapping = updated.mappings.first { $0.columnIndex == 1 }
        let col2Mapping = updated.mappings.first { $0.columnIndex == 2 }

        XCTAssertNil(col1Mapping?.targetField)  // Was unassigned
        XCTAssertEqual(col2Mapping?.targetField, .brand)
    }

    // MARK: - Value Parsing Tests

    func testParsePrice_StandardFormat_ParsesCorrectly() {
        XCTAssertEqual(ColumnMapper.parsePrice("$2499"), Decimal(2499))
        XCTAssertEqual(ColumnMapper.parsePrice("2499.99"), Decimal(string: "2499.99"))
        XCTAssertEqual(ColumnMapper.parsePrice("$1,234.56"), Decimal(string: "1234.56"))
        XCTAssertEqual(ColumnMapper.parsePrice(" $99 "), Decimal(99))
    }

    func testParsePrice_InvalidFormat_ReturnsNil() {
        XCTAssertNil(ColumnMapper.parsePrice(""))
        XCTAssertNil(ColumnMapper.parsePrice("abc"))
        XCTAssertNil(ColumnMapper.parsePrice("N/A"))
    }

    func testParseDate_VariousFormats_ParsesCorrectly() {
        // ISO format
        let isoDate = ColumnMapper.parseDate("2024-03-15")
        XCTAssertNotNil(isoDate)

        // US format
        let usDate = ColumnMapper.parseDate("03/15/2024")
        XCTAssertNotNil(usDate)

        // EU format
        let euDate = ColumnMapper.parseDate("15-03-2024")
        XCTAssertNotNil(euDate)

        // Verbose format
        let verboseDate = ColumnMapper.parseDate("Mar 15, 2024")
        XCTAssertNotNil(verboseDate)
    }

    func testParseDate_InvalidFormat_ReturnsNil() {
        XCTAssertNil(ColumnMapper.parseDate(""))
        XCTAssertNil(ColumnMapper.parseDate("yesterday"))
        XCTAssertNil(ColumnMapper.parseDate("invalid"))
    }

    func testParseQuantity_ValidNumbers_ParsesCorrectly() {
        XCTAssertEqual(ColumnMapper.parseQuantity("5"), 5)
        XCTAssertEqual(ColumnMapper.parseQuantity("100"), 100)
        XCTAssertEqual(ColumnMapper.parseQuantity(" 42 "), 42)
        XCTAssertEqual(ColumnMapper.parseQuantity("1,000"), 1000)
    }

    func testParseQuantity_InvalidFormat_ReturnsNil() {
        XCTAssertNil(ColumnMapper.parseQuantity(""))
        XCTAssertNil(ColumnMapper.parseQuantity("abc"))
        XCTAssertNil(ColumnMapper.parseQuantity("5.5"))
    }

    func testParseCondition_StandardValues_MapsCorrectly() {
        XCTAssertEqual(ColumnMapper.parseCondition("new"), "new")
        XCTAssertEqual(ColumnMapper.parseCondition("New"), "new")
        XCTAssertEqual(ColumnMapper.parseCondition("brand new"), "new")
        XCTAssertEqual(ColumnMapper.parseCondition("excellent"), "new")
        XCTAssertEqual(ColumnMapper.parseCondition("like new"), "likeNew")
        XCTAssertEqual(ColumnMapper.parseCondition("very good"), "likeNew")
        XCTAssertEqual(ColumnMapper.parseCondition("good"), "good")
        XCTAssertEqual(ColumnMapper.parseCondition("fair"), "fair")
        XCTAssertEqual(ColumnMapper.parseCondition("poor"), "poor")
        XCTAssertEqual(ColumnMapper.parseCondition("damaged"), "poor")
    }

    func testParseCondition_UnknownValue_DefaultsToGood() {
        XCTAssertEqual(ColumnMapper.parseCondition("unknown"), "good")
        XCTAssertEqual(ColumnMapper.parseCondition("xyz"), "good")
    }

    // MARK: - Target Field Tests

    func testTargetField_RequiredFields_OnlyNameIsRequired() {
        for field in ColumnMapper.TargetField.allCases {
            if field == .name {
                XCTAssertTrue(field.isRequired)
            } else {
                XCTAssertFalse(field.isRequired)
            }
        }
    }

    func testTargetField_HasDisplayName() {
        for field in ColumnMapper.TargetField.allCases {
            XCTAssertFalse(field.displayName.isEmpty)
        }
    }

    func testTargetField_HasHeaderVariations() {
        for field in ColumnMapper.TargetField.allCases {
            XCTAssertFalse(field.headerVariations.isEmpty, "\(field) should have variations")
        }
    }

    // MARK: - Fuzzy Matching Tests

    func testAnalyzeHeaders_FuzzyMatch_DetectsWithLowerConfidence() async {
        // "item_name" should fuzzy match to "name" field
        let headers = ["item_name"]

        let result = await sut.analyzeHeaders(headers)

        let nameMapping = result.mappings.first { $0.targetField == .name }
        XCTAssertNotNil(nameMapping)
        XCTAssertLessThan(nameMapping?.confidence ?? 1.0, 1.0)  // Not exact match
        XCTAssertGreaterThan(nameMapping?.confidence ?? 0, 0.5)  // But still detected
    }

    func testAnalyzeHeaders_CaseInsensitive_MatchesCorrectly() async {
        let headers = ["NAME", "BRAND", "PRICE"]

        let result = await sut.analyzeHeaders(headers)

        XCTAssertEqual(result.mappedFieldCount, 3)
    }

    // MARK: - Mapping Result Tests

    func testMappingResult_MappedFieldCount_CalculatesCorrectly() async {
        let headers = ["name", "brand", "unknown1", "unknown2"]

        let result = await sut.analyzeHeaders(headers)

        XCTAssertEqual(result.mappedFieldCount, 2)  // name and brand
        XCTAssertEqual(result.unmappedColumns.count, 2)
    }
}

//
//  PresentationModelTests.swift
//  Nestory-ProTests
//
//  P2-18-1: Unit tests for ViewModel presentation models
//

import XCTest
@testable import Nestory_Pro

// MARK: - DocumentationStatus Tests

@MainActor
final class DocumentationStatusTests: XCTestCase {

    // MARK: - Core Score Tests

    func testCoreScore_AllFieldsMissing_ReturnsZero() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: false,
            hasValue: false,
            hasCategory: false,
            hasRoom: false,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.coreScore, 0.0)
    }

    func testCoreScore_AllCoreFieldsPresent_ReturnsOne() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: true,
            hasRoom: true,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.coreScore, 1.0)
    }

    func testCoreScore_HalfFieldsPresent_ReturnsHalf() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: false,
            hasRoom: false,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.coreScore, 0.5)
    }

    func testCoreScore_OneFieldPresent_ReturnsQuarter() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: false,
            hasCategory: false,
            hasRoom: false,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.coreScore, 0.25)
    }

    // MARK: - Extended Score Tests

    func testExtendedScore_AllFieldsMissing_ReturnsZero() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: false,
            hasValue: false,
            hasCategory: false,
            hasRoom: false,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.extendedScore, 0.0)
    }

    func testExtendedScore_AllFieldsPresent_ReturnsOne() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: true,
            hasRoom: true,
            hasReceipt: true,
            hasSerialNumber: true
        )

        // Assert
        XCTAssertEqual(status.extendedScore, 1.0)
    }

    func testExtendedScore_HalfFieldsPresent_ReturnsHalf() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: true,
            hasRoom: false,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.extendedScore, 0.5)
    }

    // MARK: - isFullyDocumented Tests

    func testIsFullyDocumented_AllCoreFieldsPresent_ReturnsTrue() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: true,
            hasRoom: true,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertTrue(status.isFullyDocumented)
    }

    func testIsFullyDocumented_MissingOneField_ReturnsFalse() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: true,
            hasRoom: false,
            hasReceipt: true,
            hasSerialNumber: true
        )

        // Assert
        XCTAssertFalse(status.isFullyDocumented)
    }

    // MARK: - Missing Fields Tests

    func testMissingCoreFields_AllMissing_ReturnsAllFields() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: false,
            hasValue: false,
            hasCategory: false,
            hasRoom: false,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.missingCoreFields, ["Photo", "Value", "Category", "Room"])
    }

    func testMissingCoreFields_AllPresent_ReturnsEmptyArray() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: true,
            hasRoom: true,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertTrue(status.missingCoreFields.isEmpty)
    }

    func testMissingCoreFields_SomeMissing_ReturnsCorrectFields() {
        // Arrange
        let status = DocumentationStatus(
            hasPhoto: true,
            hasValue: false,
            hasCategory: true,
            hasRoom: false,
            hasReceipt: false,
            hasSerialNumber: false
        )

        // Assert
        XCTAssertEqual(status.missingCoreFields, ["Value", "Room"])
    }

    // MARK: - Equatable Tests

    func testEquatable_SameValues_ReturnsTrue() {
        // Arrange
        let status1 = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: false,
            hasRoom: true,
            hasReceipt: false,
            hasSerialNumber: true
        )
        let status2 = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: false,
            hasRoom: true,
            hasReceipt: false,
            hasSerialNumber: true
        )

        // Assert
        XCTAssertEqual(status1, status2)
    }

    func testEquatable_DifferentValues_ReturnsFalse() {
        // Arrange
        let status1 = DocumentationStatus(
            hasPhoto: true,
            hasValue: true,
            hasCategory: false,
            hasRoom: true,
            hasReceipt: false,
            hasSerialNumber: true
        )
        let status2 = DocumentationStatus(
            hasPhoto: false,
            hasValue: true,
            hasCategory: false,
            hasRoom: true,
            hasReceipt: false,
            hasSerialNumber: true
        )

        // Assert
        XCTAssertNotEqual(status1, status2)
    }
}

// MARK: - SearchMatchMetadata Tests

@MainActor
final class SearchMatchMetadataTests: XCTestCase {

    // MARK: - hasMatch Tests

    func testHasMatch_NoMatches_ReturnsFalse() {
        // Arrange
        let metadata = SearchMatchMetadata.noMatch

        // Assert
        XCTAssertFalse(metadata.hasMatch)
    }

    func testHasMatch_NameMatched_ReturnsTrue() {
        // Arrange
        let metadata = SearchMatchMetadata(
            matchedName: true,
            matchedBrand: false,
            matchedNotes: false,
            matchedCategory: false,
            matchedRoom: false,
            matchedTags: false
        )

        // Assert
        XCTAssertTrue(metadata.hasMatch)
    }

    func testHasMatch_MultipleMatches_ReturnsTrue() {
        // Arrange
        let metadata = SearchMatchMetadata(
            matchedName: true,
            matchedBrand: true,
            matchedNotes: false,
            matchedCategory: true,
            matchedRoom: false,
            matchedTags: true
        )

        // Assert
        XCTAssertTrue(metadata.hasMatch)
    }

    // MARK: - matchSummary Tests

    func testMatchSummary_NoMatches_ReturnsEmptyString() {
        // Arrange
        let metadata = SearchMatchMetadata.noMatch

        // Assert
        XCTAssertEqual(metadata.matchSummary, "")
    }

    func testMatchSummary_SingleMatch_ReturnsSingleField() {
        // Arrange
        let metadata = SearchMatchMetadata(
            matchedName: true,
            matchedBrand: false,
            matchedNotes: false,
            matchedCategory: false,
            matchedRoom: false,
            matchedTags: false
        )

        // Assert
        XCTAssertEqual(metadata.matchSummary, "name")
    }

    func testMatchSummary_MultipleMatches_ReturnsCommaSeparated() {
        // Arrange
        let metadata = SearchMatchMetadata(
            matchedName: true,
            matchedBrand: true,
            matchedNotes: false,
            matchedCategory: false,
            matchedRoom: true,
            matchedTags: false
        )

        // Assert
        XCTAssertEqual(metadata.matchSummary, "name, brand, room")
    }

    func testMatchSummary_AllMatches_ReturnsAllFields() {
        // Arrange
        let metadata = SearchMatchMetadata(
            matchedName: true,
            matchedBrand: true,
            matchedNotes: true,
            matchedCategory: true,
            matchedRoom: true,
            matchedTags: true
        )

        // Assert
        XCTAssertEqual(metadata.matchSummary, "name, brand, notes, category, room, tags")
    }

    // MARK: - Static noMatch Tests

    func testNoMatch_AllFieldsFalse() {
        // Arrange
        let metadata = SearchMatchMetadata.noMatch

        // Assert
        XCTAssertFalse(metadata.matchedName)
        XCTAssertFalse(metadata.matchedBrand)
        XCTAssertFalse(metadata.matchedNotes)
        XCTAssertFalse(metadata.matchedCategory)
        XCTAssertFalse(metadata.matchedRoom)
        XCTAssertFalse(metadata.matchedTags)
    }
}

// MARK: - InventorySection Tests

@MainActor
final class InventorySectionTests: XCTestCase {

    // MARK: - ID Tests

    func testId_All_ReturnsAll() {
        // Arrange
        let section = InventorySection.all

        // Assert
        XCTAssertEqual(section.id, "all")
    }

    func testId_Room_ReturnsRoomPrefix() {
        // Arrange
        let section = InventorySection.room("Living Room")

        // Assert
        XCTAssertEqual(section.id, "room-Living Room")
    }

    func testId_Category_ReturnsCategoryPrefix() {
        // Arrange
        let section = InventorySection.category("Electronics")

        // Assert
        XCTAssertEqual(section.id, "category-Electronics")
    }

    func testId_Container_ReturnsContainerPrefix() {
        // Arrange
        let section = InventorySection.container("Storage Box")

        // Assert
        XCTAssertEqual(section.id, "container-Storage Box")
    }

    func testId_Uncategorized_ReturnsUncategorized() {
        // Arrange
        let section = InventorySection.uncategorized

        // Assert
        XCTAssertEqual(section.id, "uncategorized")
    }

    // MARK: - Display Name Tests

    func testDisplayName_All_ReturnsAllItems() {
        // Arrange
        let section = InventorySection.all

        // Assert
        XCTAssertEqual(section.displayName, "All Items")
    }

    func testDisplayName_Uncategorized_ReturnsUncategorized() {
        // Arrange
        let section = InventorySection.uncategorized

        // Assert
        XCTAssertEqual(section.displayName, "Uncategorized")
    }

    func testDisplayName_Room_ReturnsRoomName() {
        // Arrange
        let section = InventorySection.room("Kitchen")

        // Assert
        XCTAssertEqual(section.displayName, "Kitchen")
    }

    // MARK: - Hashable Tests

    func testHashable_SameValues_AreEqual() {
        // Arrange
        let section1 = InventorySection.room("Bedroom")
        let section2 = InventorySection.room("Bedroom")

        // Assert
        XCTAssertEqual(section1, section2)
        XCTAssertEqual(section1.hashValue, section2.hashValue)
    }

    func testHashable_DifferentValues_AreNotEqual() {
        // Arrange
        let section1 = InventorySection.room("Bedroom")
        let section2 = InventorySection.room("Kitchen")

        // Assert
        XCTAssertNotEqual(section1, section2)
    }

    func testHashable_DifferentTypes_AreNotEqual() {
        // Arrange
        let roomSection = InventorySection.room("Electronics")
        let categorySection = InventorySection.category("Electronics")

        // Assert
        XCTAssertNotEqual(roomSection, categorySection)
    }
}

// MARK: - AddItemField Tests

@MainActor
final class AddItemFieldTests: XCTestCase {

    // MARK: - isRequired Tests

    func testIsRequired_Name_ReturnsTrue() {
        // Arrange & Assert
        XCTAssertTrue(AddItemField.name.isRequired)
    }

    func testIsRequired_OtherFields_ReturnFalse() {
        // Arrange
        let optionalFields: [AddItemField] = [
            .brand, .modelNumber, .serialNumber, .purchasePrice,
            .purchaseDate, .category, .room, .condition, .warranty
        ]

        // Assert
        for field in optionalFields {
            XCTAssertFalse(field.isRequired, "\(field) should not be required")
        }
    }

    // MARK: - displayName Tests

    func testDisplayName_AllFields_ReturnCorrectNames() {
        // Assert
        XCTAssertEqual(AddItemField.name.displayName, "Name")
        XCTAssertEqual(AddItemField.brand.displayName, "Brand")
        XCTAssertEqual(AddItemField.modelNumber.displayName, "Model Number")
        XCTAssertEqual(AddItemField.serialNumber.displayName, "Serial Number")
        XCTAssertEqual(AddItemField.purchasePrice.displayName, "Purchase Price")
        XCTAssertEqual(AddItemField.purchaseDate.displayName, "Purchase Date")
        XCTAssertEqual(AddItemField.category.displayName, "Category")
        XCTAssertEqual(AddItemField.room.displayName, "Room")
        XCTAssertEqual(AddItemField.condition.displayName, "Condition")
        XCTAssertEqual(AddItemField.warranty.displayName, "Warranty")
    }

    // MARK: - iconName Tests

    func testIconName_AllFields_ReturnSFSymbols() {
        // Assert - Verify each field has a non-empty icon name
        for field in AddItemField.allCases {
            XCTAssertFalse(field.iconName.isEmpty, "\(field) should have an icon")
        }
    }

    func testIconName_SpecificFields_ReturnCorrectIcons() {
        // Assert
        XCTAssertEqual(AddItemField.name.iconName, "textformat")
        XCTAssertEqual(AddItemField.purchasePrice.iconName, "dollarsign.circle.fill")
        XCTAssertEqual(AddItemField.category.iconName, "folder.fill")
        XCTAssertEqual(AddItemField.room.iconName, "door.left.hand.closed")
    }

    // MARK: - placeholder Tests

    func testPlaceholder_Name_IndicatesRequired() {
        // Arrange & Assert
        XCTAssertTrue(AddItemField.name.placeholder.contains("required"))
    }

    func testPlaceholder_OptionalFields_DoNotIndicateRequired() {
        // Arrange
        let optionalFields: [AddItemField] = [
            .brand, .modelNumber, .serialNumber, .purchasePrice,
            .purchaseDate, .category, .room, .condition, .warranty
        ]

        // Assert
        for field in optionalFields {
            XCTAssertFalse(
                field.placeholder.lowercased().contains("required"),
                "\(field) placeholder should not mention 'required'"
            )
        }
    }

    // MARK: - CaseIterable Tests

    func testCaseIterable_Returns10Cases() {
        // Assert
        XCTAssertEqual(AddItemField.allCases.count, 10)
    }

    // MARK: - Identifiable Tests

    func testIdentifiable_IdMatchesRawValue() {
        // Assert
        for field in AddItemField.allCases {
            XCTAssertEqual(field.id, field.rawValue)
        }
    }
}

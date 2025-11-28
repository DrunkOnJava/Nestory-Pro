//
//  CategoryTests.swift
//  Nestory-ProTests
//
//  Unit tests for Category model
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class CategoryTests: XCTestCase {

    // MARK: - Initialization Tests

    @MainActor
    func testCategory_InitWithAllFields_SetsCorrectly() {
        // Arrange & Act
        let category = Nestory_Pro.Category(
            name: "Electronics",
            iconName: "tv",
            colorHex: "#007AFF",
            isCustom: false,
            sortOrder: 0
        )

        // Assert
        XCTAssertEqual(category.name, "Electronics")
        XCTAssertEqual(category.iconName, "tv")
        XCTAssertEqual(category.colorHex, "#007AFF")
        XCTAssertFalse(category.isCustom)
        XCTAssertEqual(category.sortOrder, 0)
        XCTAssertNotNil(category.id)
        XCTAssertTrue(category.items.isEmpty)
    }

    @MainActor
    func testCategory_CustomCategory_IsMarkedCorrectly() {
        // Arrange & Act
        let customCategory = Nestory_Pro.Category(
            name: "My Custom Category",
            iconName: "star.fill",
            colorHex: "#FF0000",
            isCustom: true,
            sortOrder: 100
        )

        // Assert
        XCTAssertTrue(customCategory.isCustom)
    }

    // MARK: - Default Categories Tests

    @MainActor
    func testCategory_DefaultCategories_ExistAndAreValid() {
        // Arrange & Act
        let defaults = Nestory_Pro.Category.defaultCategories

        // Assert
        XCTAssertGreaterThan(defaults.count, 0, "Should have default categories")

        for defaultCat in defaults {
            XCTAssertFalse(defaultCat.name.isEmpty, "Category name should not be empty")
            XCTAssertFalse(defaultCat.icon.isEmpty, "Category icon should not be empty")
            XCTAssertTrue(defaultCat.color.hasPrefix("#"), "Color should be hex format")
        }
    }

    @MainActor
    func testCategory_DefaultCategories_HaveUniqueNames() {
        // Arrange
        let defaults = Nestory_Pro.Category.defaultCategories
        let names = defaults.map { $0.name }

        // Act
        let uniqueNames = Set(names)

        // Assert
        XCTAssertEqual(names.count, uniqueNames.count, "Default category names should be unique")
    }

    // MARK: - Color Hex Tests

    @MainActor
    func testCategory_ValidHexColors_AreAccepted() {
        // Arrange
        let validColors = ["#007AFF", "#FF9500", "#34C759", "#000000", "#FFFFFF", "#abc123"]

        for color in validColors {
            // Act
            let category = Nestory_Pro.Category(
                name: "Color Test",
                iconName: "circle.fill",
                colorHex: color,
                isCustom: true,
                sortOrder: 0
            )

            // Assert
            XCTAssertEqual(category.colorHex, color)
        }
    }

    @MainActor
    func testCategory_InvalidHexColor_IsNotValidated() {
        // Arrange & Act - Model doesn't validate hex format
        let category = Nestory_Pro.Category(
            name: "Invalid Color",
            iconName: "circle",
            colorHex: "not-a-color",
            isCustom: true,
            sortOrder: 0
        )

        // Assert - Model accepts it (validation is elsewhere)
        XCTAssertEqual(category.colorHex, "not-a-color")
    }

    // MARK: - Icon Name Tests

    @MainActor
    func testCategory_SFSymbolIconNames_AreAccepted() {
        // Arrange
        let iconNames = ["tv", "iphone", "laptopcomputer", "headphones", "gamecontroller.fill"]

        for iconName in iconNames {
            // Act
            let category = Nestory_Pro.Category(
                name: "Icon Test",
                iconName: iconName,
                colorHex: "#000000",
                isCustom: true,
                sortOrder: 0
            )

            // Assert
            XCTAssertEqual(category.iconName, iconName)
        }
    }

    // MARK: - Relationship Tests

    @MainActor
    func testCategory_ItemsRelationship_IsInitiallyEmpty() {
        // Arrange & Act
        let category = TestFixtures.testCategory()

        // Assert
        XCTAssertTrue(category.items.isEmpty)
    }

    @MainActor
    func testCategory_AddItem_UpdatesItemsArray() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let category = TestFixtures.testCategory()
        context.insert(category)

        let item = TestFixtures.testItem(category: category)
        context.insert(item)

        try context.save()

        // Assert
        XCTAssertEqual(category.items.count, 1)
        XCTAssertTrue(category.items.contains(item))
    }

    @MainActor
    func testCategory_MultipleItems_AllLinked() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext

        let category = TestFixtures.testCategory()
        context.insert(category)

        let items = (0..<5).map { i in
            TestFixtures.testItem(name: "Item \(i)", category: category)
        }
        items.forEach { context.insert($0) }

        try context.save()

        // Assert
        XCTAssertEqual(category.items.count, 5)
        for item in items {
            XCTAssertTrue(category.items.contains(item))
        }
    }

    // MARK: - Sort Order Tests

    @MainActor
    func testCategory_SortOrder_CanBeNegative() {
        // Arrange & Act
        let category = Nestory_Pro.Category(
            name: "Negative Sort",
            iconName: "circle",
            colorHex: "#000000",
            isCustom: true,
            sortOrder: -10
        )

        // Assert
        XCTAssertEqual(category.sortOrder, -10)
    }

    @MainActor
    func testCategory_SortOrder_CanBeVeryLarge() {
        // Arrange & Act
        let category = Nestory_Pro.Category(
            name: "Large Sort",
            iconName: "circle",
            colorHex: "#000000",
            isCustom: true,
            sortOrder: Int.max
        )

        // Assert
        XCTAssertEqual(category.sortOrder, Int.max)
    }

    // MARK: - Edge Cases

    @MainActor
    func testCategory_EmptyName_IsAllowed() {
        // Arrange & Act
        let category = Nestory_Pro.Category(
            name: "",
            iconName: "circle",
            colorHex: "#000000",
            isCustom: true,
            sortOrder: 0
        )

        // Assert
        XCTAssertEqual(category.name, "")
    }

    @MainActor
    func testCategory_UnicodeInName_IsPreserved() {
        // Arrange
        let unicodeName = "家具 🪑"

        // Act
        let category = Nestory_Pro.Category(
            name: unicodeName,
            iconName: "chair",
            colorHex: "#000000",
            isCustom: true,
            sortOrder: 0
        )

        // Assert
        XCTAssertEqual(category.name, unicodeName)
    }

    // MARK: - UUID Tests

    @MainActor
    func testCategory_HasUniqueUUID_OnCreation() {
        // Arrange & Act
        let cat1 = TestFixtures.testCategory(name: "Category 1")
        let cat2 = TestFixtures.testCategory(name: "Category 2")

        // Assert
        XCTAssertNotEqual(cat1.id, cat2.id)
    }
}

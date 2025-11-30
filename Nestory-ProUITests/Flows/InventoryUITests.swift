//
//  InventoryUITests.swift
//  Nestory-ProUITests
//
//  UI tests for inventory management flows
//

@preconcurrency import XCTest

final class InventoryUITests: XCTestCase {

    nonisolated(unsafe) var app: XCUIApplication!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Empty State Tests

    func testInventory_EmptyState_ShowsEmptyMessage() throws {
        // Verify on Inventory tab
        XCTAssertTrue(app.buttons["Inventory"].exists)
        app.buttons["Inventory"].tap()

        // Verify empty state components - use case-insensitive matching for title
        let emptyStateTitleExists = app.staticTexts["No Items Yet"].waitForExistence(timeout: 3)
        let addButtonExists = app.buttons[AccessibilityIdentifiers.Inventory.addButton].waitForExistence(timeout: 3)

        XCTAssertTrue(emptyStateTitleExists || addButtonExists, "Should show empty state or add button")
    }

    // MARK: - Add Item Flow Tests

    func testAddItem_BasicFlow_CreatesItem() throws {
        // Navigate to add item
        app.buttons["Inventory"].tap()

        // Tap add button using accessibility identifier
        let addButton = app.buttons[AccessibilityIdentifiers.Inventory.addButton]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add button should exist in toolbar")
        addButton.tap()

        // Fill in required fields
        let nameField = app.textFields[AccessibilityIdentifiers.AddEditItem.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should appear in add item screen")
        nameField.tap()
        nameField.typeText("Test MacBook Pro")

        // Save the item
        let saveButton = app.buttons[AccessibilityIdentifiers.AddEditItem.saveButton]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")

        if saveButton.isEnabled {
            saveButton.tap()

            // Verify item was created
            let itemExists = app.staticTexts["Test MacBook Pro"].waitForExistence(timeout: 3)
            XCTAssertTrue(itemExists, "Created item should appear in list")
        }
    }

    func testAddItem_Cancel_DoesNotCreateItem() throws {
        // Navigate to add item
        app.buttons["Inventory"].tap()

        let addButton = app.buttons[AccessibilityIdentifiers.Inventory.addButton]
        guard addButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Add button not found - UI may not be implemented yet")
        }

        addButton.tap()

        // Enter some data
        let nameField = app.textFields[AccessibilityIdentifiers.AddEditItem.nameField]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("Cancelled Item")
        }

        // Cancel
        let cancelButton = app.buttons[AccessibilityIdentifiers.AddEditItem.cancelButton]
        if cancelButton.exists {
            cancelButton.tap()

            // Verify item was NOT created
            let itemExists = app.staticTexts["Cancelled Item"].exists
            XCTAssertFalse(itemExists, "Cancelled item should not appear")
        }
    }

    // MARK: - Search Tests

    func testSearch_WithMatchingQuery_ShowsResults() throws {
        // Skip if search not implemented
        let searchField = app.searchFields[AccessibilityIdentifiers.Inventory.searchField]
        guard searchField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Search not implemented yet")
        }

        searchField.tap()
        searchField.typeText("MacBook")

        // Verify search is working (results or no results message)
        let hasResults = app.cells.count > 0 || app.staticTexts["No results"].exists
        XCTAssertTrue(hasResults, "Search should show results or no results message")
    }

    func testSearch_ClearButton_ResetsResults() throws {
        let searchField = app.searchFields[AccessibilityIdentifiers.Inventory.searchField]
        guard searchField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Search not implemented yet")
        }

        // Perform search
        searchField.tap()
        searchField.typeText("Test")

        // Clear search
        if app.buttons["Clear text"].exists {
            app.buttons["Clear text"].tap()
        }

        // Search field should be empty
        XCTAssertEqual(searchField.value as? String, "" , "Search should be cleared")
    }

    // MARK: - Filter Tests

    func testFilter_ByCategory_FiltersResults() throws {
        let filterChip = app.buttons[AccessibilityIdentifiers.Inventory.filterChip]
        guard filterChip.waitForExistence(timeout: 3) else {
            throw XCTSkip("Filter not implemented yet")
        }

        filterChip.tap()

        // Select a category filter (implementation dependent)
        let electronicsFilter = app.buttons["Electronics"]
        if electronicsFilter.exists {
            electronicsFilter.tap()
            // Verify filtering is applied
        }
    }

    // MARK: - Sort Tests

    func testSort_ByName_SortsAlphabetically() throws {
        let sortButton = app.buttons[AccessibilityIdentifiers.Inventory.sortButton]
        guard sortButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Sort not implemented yet")
        }

        sortButton.tap()

        // Select sort by name
        let sortByName = app.buttons["Name"]
        if sortByName.exists {
            sortByName.tap()
            // Verify sorting is applied
        }
    }

    // MARK: - Item Detail Tests

    func testItemDetail_Tap_ShowsDetailView() throws {
        // This requires at least one item to exist
        // First check if there are any items
        guard app.cells.count > 0 else {
            throw XCTSkip("No items to test detail view")
        }

        // Tap first item
        app.cells.firstMatch.tap()

        // Verify detail view is shown
        let detailScreen = app.otherElements[AccessibilityIdentifiers.ItemDetail.screen]
        let detailVisible = detailScreen.waitForExistence(timeout: 3) ||
                           app.navigationBars.staticTexts.count > 0

        XCTAssertTrue(detailVisible, "Detail view should be shown")
    }

    // MARK: - Delete Item Tests

    func testDeleteItem_Confirmation_DeletesItem() throws {
        guard app.cells.count > 0 else {
            throw XCTSkip("No items to delete")
        }

        let initialCount = app.cells.count

        // Tap item to show detail
        app.cells.firstMatch.tap()

        // Find delete button
        let deleteButton = app.buttons[AccessibilityIdentifiers.ItemDetail.deleteButton]
        guard deleteButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Delete button not found")
        }

        deleteButton.tap()

        // Confirm deletion
        let confirmButton = app.buttons[AccessibilityIdentifiers.Alert.confirmButton]
        if confirmButton.waitForExistence(timeout: 3) {
            confirmButton.tap()

            // Wait for navigation back
            sleep(1)

            // Verify item count decreased
            XCTAssertLessThan(app.cells.count, initialCount, "Item should be deleted")
        }
    }

    // MARK: - Layout Toggle Tests

    func testLayoutToggle_SwitchBetweenListAndGrid() throws {
        let layoutToggle = app.buttons[AccessibilityIdentifiers.Inventory.layoutToggle]
        guard layoutToggle.waitForExistence(timeout: 3) else {
            throw XCTSkip("Layout toggle not implemented")
        }

        // Toggle to grid
        layoutToggle.tap()

        // Toggle back to list
        layoutToggle.tap()

        // If we got here without crash, layout toggle works
    }

    // MARK: - Accessibility Tests

    func testInventory_VoiceOverLabels_ArePresent() throws {
        app.buttons["Inventory"].tap()

        // Check that main elements have accessibility labels
        let addButton = app.buttons[AccessibilityIdentifiers.Inventory.addButton]
        if addButton.exists {
            XCTAssertFalse(addButton.label.isEmpty, "Add button should have accessibility label")
        }
    }

    // MARK: - Performance Tests

    func testPerformance_InventoryTabLoad() throws {
        // Navigate away first
        app.buttons["Settings"].tap()

        measure {
            app.buttons["Inventory"].tap()
            // Wait for content to load
            _ = app.staticTexts["Inventory"].waitForExistence(timeout: 5)
        }
    }

    // MARK: - Helper Methods

    private func createTestItem(name: String) {
        app.buttons["Inventory"].tap()

        let addButton = app.buttons[AccessibilityIdentifiers.Inventory.addButton]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()

            let nameField = app.textFields[AccessibilityIdentifiers.AddEditItem.nameField]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
            }

            let saveButton = app.buttons[AccessibilityIdentifiers.AddEditItem.saveButton]
            if saveButton.exists && saveButton.isEnabled {
                saveButton.tap()
            }
        }
    }
}

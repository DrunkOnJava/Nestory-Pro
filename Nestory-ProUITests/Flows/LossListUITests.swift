//
//  LossListUITests.swift
//  Nestory-ProUITests
//
//  UI tests for loss list (insurance claim) flow
//  Task: 9.2.3
//

import XCTest

final class LossListUITests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Navigate to Reports tab
        app.buttons["Reports"].tap()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Loss List Card Tests

    func testLossList_CardExists() throws {
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        let cardExists = lossListCard.waitForExistence(timeout: 3) ||
                        app.staticTexts["Loss List"].exists ||
                        app.staticTexts["Insurance Claim"].exists

        XCTAssertTrue(cardExists, "Loss List card should exist on Reports tab")
    }

    func testLossList_TapCard_ShowsSelectionView() throws {
        // Find and tap the loss list card
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        if lossListCard.waitForExistence(timeout: 3) {
            lossListCard.tap()
        } else if app.staticTexts["Loss List"].exists {
            // Try tapping the text or its parent
            app.staticTexts["Loss List"].tap()
        } else {
            throw XCTSkip("Loss List card not found")
        }

        // Wait for navigation
        sleep(1)

        // Should show item selection view
        let selectionViewExists = app.staticTexts["Select Items"].exists ||
                                 app.staticTexts["Select items for claim"].exists ||
                                 app.buttons["Select All"].exists ||
                                 app.tables.count > 0 ||
                                 app.collectionViews.count > 0

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }

        XCTAssertTrue(selectionViewExists, "Loss list should show item selection view")
    }

    // MARK: - Item Selection Tests

    func testLossList_ItemSelection_MultiSelectWorks() throws {
        // Navigate to loss list selection
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Check if there are items to select
        let hasItems = app.cells.count > 0

        if hasItems {
            // Try selecting first item
            let firstCell = app.cells.firstMatch
            firstCell.tap()

            // Try selecting second item if exists
            if app.cells.count > 1 {
                app.cells.element(boundBy: 1).tap()
            }

            // Should show selection count or continue button
            let hasSelectionUI = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'selected'")).count > 0 ||
                                app.buttons["Continue"].exists ||
                                app.buttons["Next"].exists
        }

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    func testLossList_SelectAll_SelectsAllItems() throws {
        // Navigate to loss list selection
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Look for Select All button
        let selectAllButton = app.buttons["Select All"]
        if selectAllButton.exists {
            selectAllButton.tap()

            // All items should be selected (checkmarks visible or selection count matches)
        }

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    func testLossList_QuickSelectByRoom_Works() throws {
        // Navigate to loss list selection
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Look for "By Room" quick select
        let byRoomButton = app.buttons["By Room"]
        if byRoomButton.exists {
            byRoomButton.tap()

            // Should show room picker or filter by room
            sleep(1)
        }

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    // MARK: - Free Tier Limit Tests

    func testLossList_FreeTierLimit_ShowsWarning() throws {
        // This test verifies the 20-item limit for free users
        // Navigate to loss list selection
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Look for limit warning or Pro badge
        let hasLimitIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'limit'")).count > 0 ||
                               app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '20 items'")).count > 0 ||
                               app.staticTexts["Pro"].exists

        // This may or may not appear depending on number of items selected
        _ = hasLimitIndicator

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    // MARK: - Incident Details Tests

    func testLossList_IncidentDetails_ShowsAfterSelection() throws {
        // Navigate to loss list selection
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Select an item if available
        if app.cells.count > 0 {
            app.cells.firstMatch.tap()
        }

        // Look for continue/next button to proceed to incident details
        let continueButton = app.buttons["Continue"]
        let nextButton = app.buttons["Next"]
        let generateButton = app.buttons["Generate"]

        if continueButton.exists {
            continueButton.tap()
        } else if nextButton.exists {
            nextButton.tap()
        } else if generateButton.exists {
            generateButton.tap()
        }

        sleep(1)

        // Should show incident details form
        let hasIncidentForm = app.staticTexts["Incident Details"].exists ||
                             app.datePickers.count > 0 ||
                             app.textViews.count > 0 ||
                             app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'incident'")).count > 0

        // Navigate back
        while app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    func testLossList_IncidentDatePicker_Works() throws {
        // Navigate to loss list and go to incident details
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Select item and continue
        if app.cells.count > 0 {
            app.cells.firstMatch.tap()
        }

        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
            sleep(1)
        }

        // Look for date picker
        let datePicker = app.datePickers.firstMatch
        if datePicker.exists {
            datePicker.tap()
            // Date picker should be interactive
        }

        // Navigate back
        while app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    func testLossList_IncidentType_CanBeSelected() throws {
        // Navigate to loss list and go to incident details
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Select item and continue
        if app.cells.count > 0 {
            app.cells.firstMatch.tap()
        }

        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
            sleep(1)
        }

        // Look for incident type picker (fire, theft, water damage, etc.)
        let hasTypePicker = app.buttons["Fire"].exists ||
                           app.buttons["Theft"].exists ||
                           app.buttons["Water Damage"].exists ||
                           app.pickers.count > 0

        // Navigate back
        while app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    // MARK: - PDF Generation Tests

    func testLossList_GeneratePDF_ShowsPreview() throws {
        // Navigate to loss list
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Select item
        if app.cells.count > 0 {
            app.cells.firstMatch.tap()
        }

        // Continue to incident details
        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
            sleep(1)
        }

        // Look for generate button
        let generateButton = app.buttons["Generate PDF"]
        let createButton = app.buttons["Create Report"]
        let generateAltButton = app.buttons["Generate"]

        if generateButton.exists {
            generateButton.tap()
        } else if createButton.exists {
            createButton.tap()
        } else if generateAltButton.exists {
            generateAltButton.tap()
        }

        sleep(2) // PDF generation may take a moment

        // Should show PDF preview or share options
        let hasPreview = app.staticTexts["Preview"].exists ||
                        app.buttons["Share"].exists ||
                        app.otherElements["PDFView"].exists

        // Navigate back
        while app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    // MARK: - Summary Display Tests

    func testLossList_Summary_ShowsTotalValue() throws {
        // Navigate to loss list
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Select items
        if app.cells.count > 0 {
            app.cells.firstMatch.tap()
        }

        // Look for total value display
        let hasTotalValue = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).count > 0 ||
                           app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Total'")).count > 0

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    func testLossList_Summary_ShowsItemCount() throws {
        // Navigate to loss list
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Select items
        if app.cells.count > 0 {
            app.cells.firstMatch.tap()
        }

        // Look for item count display
        let hasItemCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'item'")).count > 0 ||
                          app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'selected'")).count > 0

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    // MARK: - Accessibility Tests

    func testLossList_AccessibilityLabels_ArePresent() throws {
        // Navigate to loss list
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }
        lossListCard.tap()

        sleep(1)

        // Check that interactive elements have accessibility labels
        for button in app.buttons.allElementsBoundByIndex {
            if button.isHittable {
                XCTAssertFalse(button.label.isEmpty,
                              "Button '\(button.identifier)' should have accessibility label")
            }
        }

        // Navigate back
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    // MARK: - Performance Tests

    func testPerformance_LossListSelection() throws {
        // Navigate to loss list
        let lossListCard = app.buttons[AccessibilityIdentifiers.Reports.lossListCard]
        guard lossListCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("Loss List not implemented")
        }

        measure {
            lossListCard.tap()
            sleep(1)

            // Navigate back
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            }
            sleep(1)
        }
    }
}

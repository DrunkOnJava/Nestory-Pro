//
//  TabNavigationUITests.swift
//  Nestory-ProUITests
//
//  UI tests for tab navigation and main user flows
//

import XCTest

@MainActor
final class TabNavigationUITests: XCTestCase {

    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabNavigation_AllTabsAccessible() throws {
        // Verify all tab buttons exist
        let inventoryTab = app.buttons["Inventory"]
        let captureTab = app.buttons["Capture"]
        let reportsTab = app.buttons["Reports"]
        let settingsTab = app.buttons["Settings"]
        
        XCTAssertTrue(inventoryTab.exists, "Inventory tab should exist")
        XCTAssertTrue(captureTab.exists, "Capture tab should exist")
        XCTAssertTrue(reportsTab.exists, "Reports tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    }
    
    func testTabNavigation_SwitchBetweenTabs() throws {
        // Start on Inventory tab (default)
        XCTAssertTrue(app.staticTexts["Inventory"].exists)
        
        // Navigate to Capture tab
        app.buttons["Capture"].tap()
        XCTAssertTrue(app.staticTexts["Capture"].exists)
        
        // Navigate to Reports tab
        app.buttons["Reports"].tap()
        XCTAssertTrue(app.staticTexts["Reports"].exists)
        
        // Navigate to Settings tab
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        
        // Navigate back to Inventory
        app.buttons["Inventory"].tap()
        XCTAssertTrue(app.staticTexts["Inventory"].exists)
    }
    
    func testTabNavigation_StatePreserved_WhenSwitchingTabs() throws {
        // Navigate to Capture tab
        app.buttons["Capture"].tap()
        XCTAssertTrue(app.staticTexts["Capture"].exists)
        
        // Switch to Reports and back
        app.buttons["Reports"].tap()
        app.buttons["Capture"].tap()
        
        // Verify still on Capture tab
        XCTAssertTrue(app.staticTexts["Capture"].exists)
    }
    
    // MARK: - Inventory Tab Tests
    
    func testInventoryTab_DisplaysDefaultState() throws {
        // Verify on Inventory tab
        XCTAssertTrue(app.staticTexts["Inventory"].exists)
        
        // Check for key UI elements (these would need to exist in your actual UI)
        // Uncomment as features are implemented
        // XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Inventory.addButton].exists)
        // XCTAssertTrue(app.searchFields[AccessibilityIdentifiers.Inventory.searchField].exists)
    }
    
    // MARK: - Capture Tab Tests
    
    func testCaptureTab_AccessibleFromMainTab() throws {
        // Navigate to Capture tab
        app.buttons["Capture"].tap()
        
        // Verify navigation succeeded
        XCTAssertTrue(app.staticTexts["Capture"].exists)
    }
    
    // MARK: - Reports Tab Tests
    
    func testReportsTab_AccessibleFromMainTab() throws {
        // Navigate to Reports tab
        app.buttons["Reports"].tap()
        
        // Verify navigation succeeded
        XCTAssertTrue(app.staticTexts["Reports"].exists)
    }
    
    // MARK: - Settings Tab Tests
    
    func testSettingsTab_AccessibleFromMainTab() throws {
        // Navigate to Settings tab
        app.buttons["Settings"].tap()
        
        // Verify navigation succeeded
        XCTAssertTrue(app.staticTexts["Settings"].exists)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibility_AllTabsHaveLabels() throws {
        let tabs = [
            app.buttons["Inventory"],
            app.buttons["Capture"],
            app.buttons["Reports"],
            app.buttons["Settings"]
        ]
        
        for tab in tabs {
            XCTAssertTrue(tab.exists, "Tab should exist")
            XCTAssertFalse(tab.label.isEmpty, "Tab should have a label")
        }
    }
    
    func testAccessibility_TabsAreEnabled() throws {
        let tabs = [
            app.buttons["Inventory"],
            app.buttons["Capture"],
            app.buttons["Reports"],
            app.buttons["Settings"]
        ]
        
        for tab in tabs {
            XCTAssertTrue(tab.isEnabled, "Tab should be enabled")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_TabSwitching() throws {
        measure {
            // Measure time to switch between tabs
            app.buttons["Capture"].tap()
            app.buttons["Reports"].tap()
            app.buttons["Settings"].tap()
            app.buttons["Inventory"].tap()
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    private func tapTab(_ tabName: String) {
        app.buttons[tabName].tap()
    }
    
    private func verifyTabIsActive(_ tabName: String) -> Bool {
        return app.staticTexts[tabName].exists
    }
}

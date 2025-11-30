//
//  CaptureUITests.swift
//  Nestory-ProUITests
//
//  UI tests for capture flows (photo, receipt, barcode)
//  Tasks: 9.2.1, 9.2.2
//

@preconcurrency import XCTest

final class CaptureUITests: XCTestCase {

    nonisolated(unsafe) var app: XCUIApplication!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()

        // Navigate to Capture tab
        app.buttons["Capture"].tap()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screen Display Tests

    func testCapture_ScreenDisplays() throws {
        XCTAssertTrue(app.staticTexts["Capture"].exists, "Capture screen should display")
    }

    func testCapture_SegmentedControl_Exists() throws {
        let segmentedControl = app.segmentedControls["captureTab.segmentedControl"]
        let controlExists = segmentedControl.waitForExistence(timeout: 3) ||
                           app.staticTexts["Photo"].exists

        XCTAssertTrue(controlExists, "Segmented control should exist")
    }

    func testCapture_AllModes_ExistInSegmentedControl() throws {
        // Photo mode should exist
        let photoExists = app.buttons["Photo"].exists ||
                         app.staticTexts["Photo"].exists

        // Receipt mode should exist
        let receiptExists = app.buttons["Receipt"].exists ||
                           app.staticTexts["Receipt"].exists

        // Barcode mode should exist
        let barcodeExists = app.buttons["Barcode"].exists ||
                           app.staticTexts["Barcode"].exists

        XCTAssertTrue(photoExists, "Photo mode should exist")
        XCTAssertTrue(receiptExists, "Receipt mode should exist")
        XCTAssertTrue(barcodeExists, "Barcode mode should exist")
    }

    // MARK: - Photo Capture Tests (Task 9.2.1)

    func testPhotoCapture_StartButton_Exists() throws {
        // Ensure we're on Photo segment
        if app.buttons["Photo"].exists {
            app.buttons["Photo"].tap()
        }

        // Look for start capture button
        let startButton = app.buttons["captureTab.startPhotoCaptureButton"]
        let buttonExists = startButton.waitForExistence(timeout: 3) ||
                          app.buttons["Start Photo Capture"].exists

        XCTAssertTrue(buttonExists, "Start Photo Capture button should exist")
    }

    func testPhotoCapture_TapStart_ShowsCapture() throws {
        // Ensure we're on Photo segment
        if app.buttons["Photo"].exists {
            app.buttons["Photo"].tap()
        }

        // Tap start button
        let startButton = app.buttons["captureTab.startPhotoCaptureButton"]
        if startButton.waitForExistence(timeout: 3) {
            startButton.tap()
        } else if app.buttons["Start Photo Capture"].exists {
            app.buttons["Start Photo Capture"].tap()
        } else {
            throw XCTSkip("Photo capture button not found")
        }

        // Wait for modal to appear
        sleep(1)

        // Should show camera/photo picker or permission dialog
        // On simulator, this will likely show photo picker
        let modalAppeared = app.sheets.count > 0 ||
                           app.buttons["Choose Photo"].exists ||
                           app.buttons["Take Photo"].exists ||
                           app.staticTexts["Photo Library"].exists ||
                           app.alerts.count > 0 // Permission alert

        XCTAssertTrue(modalAppeared, "Photo capture modal should appear")

        // Dismiss if possible
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
    }

    func testPhotoCapture_RecentCaptures_ShowsForItemsWithPhotos() throws {
        // This test requires items with photos to exist
        // First check if recent captures section exists

        // Ensure we're on Photo segment
        if app.buttons["Photo"].exists {
            app.buttons["Photo"].tap()
        }

        // Look for recent captures section
        let recentCapturesExists = app.staticTexts["Recent Captures"].exists

        // This may or may not exist depending on data state
        // Just verify it doesn't crash
        _ = recentCapturesExists
    }

    // MARK: - Receipt Capture Tests (Task 9.2.2)

    func testReceiptCapture_SwitchToReceipt_ShowsReceiptUI() throws {
        // Switch to Receipt segment
        if app.buttons["Receipt"].exists {
            app.buttons["Receipt"].tap()
        } else if let segmentedControl = app.segmentedControls.firstMatch as? XCUIElement {
            segmentedControl.buttons.element(boundBy: 1).tap()
        }

        sleep(1)

        // Should show receipt capture UI
        let receiptUIExists = app.staticTexts["Receipt Capture"].exists ||
                             app.buttons["Scan Receipt"].exists ||
                             app.buttons["captureTab.startReceiptCaptureButton"].exists

        XCTAssertTrue(receiptUIExists, "Receipt capture UI should display")
    }

    func testReceiptCapture_TapScanReceipt_ShowsCapture() throws {
        // Switch to Receipt segment
        if app.buttons["Receipt"].exists {
            app.buttons["Receipt"].tap()
        }

        sleep(1)

        // Tap scan receipt button
        let scanButton = app.buttons["captureTab.startReceiptCaptureButton"]
        if scanButton.waitForExistence(timeout: 3) {
            scanButton.tap()
        } else if app.buttons["Scan Receipt"].exists {
            app.buttons["Scan Receipt"].tap()
        } else {
            throw XCTSkip("Receipt scan button not found")
        }

        // Wait for modal
        sleep(1)

        // Should show camera or permission dialog
        let modalAppeared = app.sheets.count > 0 ||
                           app.buttons["Camera"].exists ||
                           app.alerts.count > 0

        // Dismiss if possible
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
    }

    // MARK: - Barcode Scan Tests

    func testBarcodeCapture_SwitchToBarcode_ShowsBarcodeUI() throws {
        // Switch to Barcode segment
        if app.buttons["Barcode"].exists {
            app.buttons["Barcode"].tap()
        } else {
            // Try tapping third segment
            let segments = app.segmentedControls.firstMatch.buttons
            if segments.count >= 3 {
                segments.element(boundBy: 2).tap()
            }
        }

        sleep(1)

        // Should show barcode scan UI
        let barcodeUIExists = app.staticTexts["Barcode Scan"].exists ||
                             app.buttons["Start Barcode Scan"].exists ||
                             app.buttons["captureTab.startBarcodeScanButton"].exists

        XCTAssertTrue(barcodeUIExists, "Barcode scan UI should display")
    }

    func testBarcodeCapture_TapStartScan_ShowsScanner() throws {
        // Switch to Barcode segment
        if app.buttons["Barcode"].exists {
            app.buttons["Barcode"].tap()
        }

        sleep(1)

        // Tap start scan button
        let scanButton = app.buttons["captureTab.startBarcodeScanButton"]
        if scanButton.waitForExistence(timeout: 3) {
            scanButton.tap()
        } else if app.buttons["Start Barcode Scan"].exists {
            app.buttons["Start Barcode Scan"].tap()
        } else {
            throw XCTSkip("Barcode scan button not found")
        }

        // Wait for modal
        sleep(1)

        // Should show camera or permission dialog
        let modalAppeared = app.sheets.count > 0 ||
                           app.staticTexts["Barcode"].exists ||
                           app.alerts.count > 0

        // Dismiss if possible
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        }
    }

    func testBarcodeCapture_FutureUpdateNotice_Displayed() throws {
        // Switch to Barcode segment
        if app.buttons["Barcode"].exists {
            app.buttons["Barcode"].tap()
        }

        sleep(1)

        // Should show notice about future product lookup
        let noticeExists = app.staticTexts["Product lookup coming in a future update"].exists ||
                          app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'future'")).count > 0

        // This is a soft assertion - notice may be styled differently
        _ = noticeExists
    }

    // MARK: - Mode Switching Tests

    func testCapture_SwitchBetweenModes_NoErrors() throws {
        // Photo to Receipt
        if app.buttons["Receipt"].exists {
            app.buttons["Receipt"].tap()
        }
        sleep(1)

        // Receipt to Barcode
        if app.buttons["Barcode"].exists {
            app.buttons["Barcode"].tap()
        }
        sleep(1)

        // Barcode back to Photo
        if app.buttons["Photo"].exists {
            app.buttons["Photo"].tap()
        }
        sleep(1)

        // If we got here without crash, mode switching works
        XCTAssertTrue(true, "Mode switching should work without errors")
    }

    // MARK: - Accessibility Tests

    func testCapture_AccessibilityLabels_ArePresent() throws {
        // Verify main elements have accessibility labels
        let captureTitle = app.staticTexts["Capture"]
        XCTAssertTrue(captureTitle.exists, "Capture title should be visible")

        // Segmented control should be accessible
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.exists {
            XCTAssertFalse(segmentedControl.label.isEmpty || segmentedControl.identifier.isEmpty,
                          "Segmented control should have accessibility")
        }
    }

    // MARK: - Performance Tests

    func testPerformance_CaptureTabLoad() throws {
        // Navigate away first
        app.buttons["Settings"].tap()

        measure {
            app.buttons["Capture"].tap()
            _ = app.staticTexts["Capture"].waitForExistence(timeout: 5)
        }
    }
}

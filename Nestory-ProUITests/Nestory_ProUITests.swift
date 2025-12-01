//
//  Nestory_ProUITests.swift
//  Nestory-ProUITests
//
//  Created by Griffin on 11/28/25.
//

import XCTest

@MainActor
final class Nestory_ProUITests: XCTestCase {

    nonisolated override func setUpWithError() throws {
        MainActor.assumeIsolated {
            // In UI tests it is usually best to stop immediately when a failure occurs.
            continueAfterFailure = false
        }
    }

    nonisolated override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

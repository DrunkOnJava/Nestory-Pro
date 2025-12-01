//
//  Nestory_ProTests.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/28/25.
//

import XCTest
@testable import Nestory_Pro

@MainActor
final class OnboardingSheetControllerTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    func testInitialStateShowsWhenOnboardingNotCompleted() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        let settings = SettingsManager()
        settings.hasCompletedOnboarding = false

        let controller = OnboardingSheetController(settings: settings)

        XCTAssertTrue(controller.isShowing)
    }

    func testMarkCompleteSetsFlagAndHidesSheet() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        let settings = SettingsManager()
        settings.hasCompletedOnboarding = false
        let controller = OnboardingSheetController(settings: settings)

        controller.markComplete()

        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertFalse(controller.isShowing)
    }

    func testRefreshFromSettingsReflectsReset() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        let settings = SettingsManager()
        settings.hasCompletedOnboarding = true
        let controller = OnboardingSheetController(settings: settings)

        controller.refreshFromSettings()
        XCTAssertFalse(controller.isShowing)

        settings.hasCompletedOnboarding = false
        controller.refreshFromSettings()

        XCTAssertTrue(controller.isShowing)
    }
}

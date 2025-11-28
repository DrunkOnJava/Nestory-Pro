//
//  MockSettingsManager.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/28/25.
//

import Foundation
@testable import Nestory_Pro

/// Mock implementation of SettingsProviding for testing
@MainActor
final class MockSettingsManager: SettingsProviding {
    // MARK: - Pro Status
    var isProUnlocked: Bool = false

    // MARK: - Data & Sync
    var useICloudSync: Bool = true

    // MARK: - Appearance
    var themePreference: ThemePreference = .system
    var preferredCurrencyCode: String = "USD"

    // MARK: - Security
    var requiresBiometrics: Bool = false
    var lockAfterInactivity: Bool = false

    // MARK: - Notifications
    var enableDocumentationReminders: Bool = false
    var weeklyReminderEnabled: Bool = false

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool = false
    var hasSeenCaptureTip: Bool = false
    var hasSeenReportsTip: Bool = false

    // MARK: - Free Tier Limits
    let maxFreeItems: Int = 100
    let maxFreeLossListItems: Int = 20

    // MARK: - Currency Support
    var currencySymbol: String {
        ["USD": "$", "EUR": "€", "GBP": "£", "CAD": "CA$", "AUD": "A$"][preferredCurrencyCode] ?? "$"
    }

    var formatCurrencyCallCount = 0
    var invalidateFormatterCacheCallCount = 0

    func formatCurrency(_ value: Decimal) -> String {
        formatCurrencyCallCount += 1
        return "\(currencySymbol)\(value)"
    }

    func invalidateFormatterCache() {
        invalidateFormatterCacheCallCount += 1
    }

    // MARK: - Test Helpers
    func reset() {
        isProUnlocked = false
        useICloudSync = true
        themePreference = .system
        preferredCurrencyCode = "USD"
        requiresBiometrics = false
        lockAfterInactivity = false
        enableDocumentationReminders = false
        weeklyReminderEnabled = false
        hasCompletedOnboarding = false
        hasSeenCaptureTip = false
        hasSeenReportsTip = false
        formatCurrencyCallCount = 0
        invalidateFormatterCacheCallCount = 0
    }
}

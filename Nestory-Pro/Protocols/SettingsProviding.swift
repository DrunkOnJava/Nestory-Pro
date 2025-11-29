//
//  SettingsProviding.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation

/// Protocol for providing settings management capabilities
@MainActor
protocol SettingsProviding {
    // MARK: - Pro Status
    var isProUnlocked: Bool { get set }

    // MARK: - Data & Sync
    var useICloudSync: Bool { get set }

    // MARK: - Appearance
    var themePreference: ThemePreference { get set }
    var preferredCurrencyCode: String { get set }

    // MARK: - Security
    var requiresBiometrics: Bool { get set }
    var lockAfterInactivity: Bool { get set }

    // MARK: - Default Room
    var defaultRoomId: String? { get set }

    // MARK: - Notifications
    var enableDocumentationReminders: Bool { get set }
    var weeklyReminderEnabled: Bool { get set }

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool { get set }
    var hasSeenCaptureTip: Bool { get set }
    var hasSeenReportsTip: Bool { get set }

    // MARK: - Free Tier Limits
    var maxFreeItems: Int { get }
    var maxFreeLossListItems: Int { get }

    // MARK: - Currency Support
    var currencySymbol: String { get }
    func formatCurrency(_ value: Decimal) -> String
    func invalidateFormatterCache()
}

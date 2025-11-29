//
//  SettingsManager.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftUI

/// Manages user preferences using AppStorage and Keychain
/// Uses dependency injection via AppEnvironment (Task 5.2.2 complete)
@Observable
@MainActor
final class SettingsManager: SettingsProviding {

    // MARK: - Pro Status (stored securely in Keychain)
    var isProUnlocked: Bool {
        get { KeychainManager.isProUnlocked() }
        set { try? KeychainManager.setProUnlocked(newValue) }
    }
    
    // MARK: - Data & Sync
    @ObservationIgnored
    @AppStorage("useICloudSync") var useICloudSync: Bool = true
    
    // MARK: - Appearance
    @ObservationIgnored
    @AppStorage("themePreference") var themePreference: ThemePreference = .system
    
    @ObservationIgnored
    @AppStorage("preferredCurrencyCode") var preferredCurrencyCode: String = "USD"
    
    // MARK: - Inventory
    @ObservationIgnored
    @AppStorage("defaultRoomId") var defaultRoomId: String?
    
    // MARK: - Security
    @ObservationIgnored
    @AppStorage("requiresBiometrics") var requiresBiometrics: Bool = false
    
    @ObservationIgnored
    @AppStorage("lockAfterInactivity") var lockAfterInactivity: Bool = false
    
    // MARK: - Notifications
    @ObservationIgnored
    @AppStorage("enableDocumentationReminders") var enableDocumentationReminders: Bool = false
    
    @ObservationIgnored
    @AppStorage("weeklyReminderEnabled") var weeklyReminderEnabled: Bool = false
    
    // MARK: - Onboarding
    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    @ObservationIgnored
    @AppStorage("hasSeenCaptureTip") var hasSeenCaptureTip: Bool = false
    
    @ObservationIgnored
    @AppStorage("hasSeenReportsTip") var hasSeenReportsTip: Bool = false
    
    // MARK: - Free Tier Limits
    let maxFreeItems: Int = 100
    let maxFreeLossListItems: Int = 20
    
    // Public initializer for dependency injection
    init() {}
}

// MARK: - Theme Preference
enum ThemePreference: String, CaseIterable, Codable, Sendable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var displayName: String {
        switch self {
        case .system:
            return String(localized: "System", comment: "Theme preference: follow system settings")
        case .light:
            return String(localized: "Light", comment: "Theme preference: light mode")
        case .dark:
            return String(localized: "Dark", comment: "Theme preference: dark mode")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Currency Support
extension SettingsManager {
    static let supportedCurrencies: [(code: String, name: String, symbol: String)] = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("CAD", "Canadian Dollar", "CA$"),
        ("AUD", "Australian Dollar", "A$"),
        ("JPY", "Japanese Yen", "¥"),
        ("CNY", "Chinese Yuan", "¥"),
        ("INR", "Indian Rupee", "₹"),
        ("MXN", "Mexican Peso", "MX$"),
        ("BRL", "Brazilian Real", "R$")
    ]

    /// Cached NumberFormatter instances by currency code
    private static var formatterCache: [String: NumberFormatter] = [:]

    var currencySymbol: String {
        Self.supportedCurrencies.first { $0.code == preferredCurrencyCode }?.symbol ?? "$"
    }

    /// Returns a cached NumberFormatter for the given currency code
    private func getCachedFormatter(for currencyCode: String) -> NumberFormatter {
        if let cachedFormatter = Self.formatterCache[currencyCode] {
            return cachedFormatter
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        Self.formatterCache[currencyCode] = formatter
        return formatter
    }

    /// Clears the formatter cache (call when currency settings change)
    func invalidateFormatterCache() {
        Self.formatterCache.removeAll()
    }

    func formatCurrency(_ value: Decimal) -> String {
        let formatter = getCachedFormatter(for: preferredCurrencyCode)
        return formatter.string(from: value as NSDecimalNumber) ?? "\(currencySymbol)\(value)"
    }
}

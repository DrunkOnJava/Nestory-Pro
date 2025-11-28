//
//  SettingsManager.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftUI

/// Manages user preferences using AppStorage
@Observable
final class SettingsManager {
    static let shared = SettingsManager()
    
    // MARK: - Pro Status
    @ObservationIgnored
    @AppStorage("isProUnlocked") var isProUnlocked: Bool = false
    
    // MARK: - Data & Sync
    @ObservationIgnored
    @AppStorage("useICloudSync") var useICloudSync: Bool = true
    
    // MARK: - Appearance
    @ObservationIgnored
    @AppStorage("themePreference") var themePreference: ThemePreference = .system
    
    @ObservationIgnored
    @AppStorage("preferredCurrencyCode") var preferredCurrencyCode: String = "USD"
    
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
    
    private init() {}
}

// MARK: - Theme Preference
enum ThemePreference: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
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
    
    var currencySymbol: String {
        Self.supportedCurrencies.first { $0.code == preferredCurrencyCode }?.symbol ?? "$"
    }
    
    func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = preferredCurrencyCode
        return formatter.string(from: value as NSDecimalNumber) ?? "\(currencySymbol)\(value)"
    }
}

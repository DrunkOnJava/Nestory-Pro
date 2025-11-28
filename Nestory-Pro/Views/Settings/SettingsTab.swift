//
//  SettingsTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI

struct SettingsTab: View {
    @State private var settings = SettingsManager.shared
    @State private var showingProPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account & Pro
                Section {
                    if settings.isProUnlocked {
                        HStack {
                            Label("Nestory Pro", systemImage: "star.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Text("Active")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button(action: { showingProPaywall = true }) {
                            HStack {
                                Label("Nestory Pro", systemImage: "star.fill")
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text("Upgrade")
                                    .font(.subheadline)
                                    .foregroundColor(Color.accentColor)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Account")
                }
                
                // Data & Sync
                Section {
                    Toggle("Use iCloud Sync", isOn: $settings.useICloudSync)
                    
                    Button("Export Data") {
                        // TODO: Export data
                    }
                    
                    Button("Import Data") {
                        // TODO: Import data
                    }
                } header: {
                    Text("Data & Sync")
                } footer: {
                    Text("iCloud keeps your inventory synced across your devices. Export creates a backup of all items and photos.")
                }
                
                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $settings.themePreference) {
                        ForEach(ThemePreference.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    
                    Picker("Currency", selection: $settings.preferredCurrencyCode) {
                        ForEach(SettingsManager.supportedCurrencies, id: \.code) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency.code)
                        }
                    }
                }
                
                // Security & Privacy
                Section {
                    Toggle("Require Face ID / Touch ID", isOn: $settings.requiresBiometrics)
                    
                    if settings.requiresBiometrics {
                        Toggle("Lock After Inactivity", isOn: $settings.lockAfterInactivity)
                    }
                } header: {
                    Text("Security & Privacy")
                } footer: {
                    Text("Protect your inventory with biometric authentication.")
                }
                
                // Notifications
                Section {
                    Toggle("Documentation Reminders", isOn: $settings.enableDocumentationReminders)
                    
                    if settings.enableDocumentationReminders {
                        Toggle("Weekly Summary", isOn: $settings.weeklyReminderEnabled)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get reminded to keep your inventory up to date.")
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://nestory.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://nestory.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:support@nestory.app")!) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProPaywall) {
                ProPaywallView()
            }
        }
    }
}

// MARK: - Pro Paywall
struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text("Nestory Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("One-time purchase. No subscriptions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Items",
                            description: "Document everything you own without limits"
                        )
                        
                        FeatureRow(
                            icon: "photo.fill",
                            title: "Photos in Reports",
                            description: "Include item photos in PDF inventory reports"
                        )
                        
                        FeatureRow(
                            icon: "doc.text.fill",
                            title: "Advanced Exports",
                            description: "Export data in CSV and JSON formats"
                        )
                        
                        FeatureRow(
                            icon: "list.bullet.rectangle.fill",
                            title: "Unlimited Loss Lists",
                            description: "Create reports for any number of items"
                        )
                        
                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Extended Analytics",
                            description: "More detailed breakdowns and visualizations"
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Price
                    VStack(spacing: 8) {
                        Text("$19.99")
                            .font(.system(size: 48, weight: .bold))
                        
                        Text("One-time payment")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Purchase Button
                    Button(action: {
                        // TODO: Implement StoreKit 2 purchase
                    }) {
                        Text("Unlock Nestory Pro")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    
                    Button("Restore Purchases") {
                        // TODO: Restore purchases
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Text("Free tier includes up to 100 items with all core features.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsTab()
}

#Preview("Pro Paywall") {
    ProPaywallView()
}

//
//  SettingsTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// P2-13-1: Settings Tab Card-Based Sections Retrofit
// ============================================================================
// Updates:
// - Added SettingsRowView component for consistent row styling
// - Organized sections with NestoryTheme styling
// - Added inline state indicators (iCloud sync, backup status)
// - Added version number in footer
// - Progress indicators for export/import operations
// ============================================================================

import SwiftUI
import StoreKit
import SwiftData
import UniformTypeIdentifiers
import TipKit

struct SettingsTab: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    @State private var showingProPaywall = false

    // Export state - Task 3.4.2: Wire up BackupService export
    @State private var isExportingJSON = false
    @State private var isExportingCSV = false
    @State private var exportError: Error?
    @State private var showingExportError = false
    @State private var exportedFileURL: URL?

    // Import state - Task 6.3.1/6.3.2: Restore from backup
    @State private var showingImportPicker = false
    @State private var showingImportConfirmation = false
    @State private var showingImportResult = false
    @State private var isImporting = false
    @State private var importError: Error?
    @State private var showingImportError = false
    @State private var restoreResult: RestoreResult?
    @State private var pendingImportURL: URL?
    @State private var restoreStrategy: RestoreStrategy = .merge

    // F6: CSV Import state
    @State private var showingCSVImportSheet = false

    // Feedback state (Task P4-07)
    @State private var showingFeedbackSheet = false
    private let feedbackService = FeedbackService()

    @State private var showingEmailError = false
    @State private var emailErrorMessage = ""

    // SwiftData queries for export
    @Query private var allItems: [Item]
    @Query private var allCategories: [Category]
    @Query private var allRooms: [Room]
    @Query private var allReceipts: [Receipt]

    var body: some View {
        @Bindable var settings = env.settings
        NavigationStack {
            List {
                // Account & Pro (P2-13-1)
                Section {
                    if env.settings.isProUnlocked {
                        SettingsRowView(
                            icon: "star.fill",
                            iconColor: .orange,
                            title: "Nestory Pro",
                            subtitle: "Active"
                        )
                    } else {
                        Button(action: { showingProPaywall = true }) {
                            SettingsRowView(
                                icon: "star.fill",
                                iconColor: .orange,
                                title: "Nestory Pro",
                                subtitle: "Upgrade",
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.proUpgradeCell)
                    }
                } header: {
                    settingsSectionHeader("Account", icon: "person.circle.fill")
                }
                
                // Data & Sync (P2-13-1)
                Section {
                    // iCloud Sync Toggle with inline indicator
                    HStack {
                        Image(systemName: "icloud.fill")
                            .font(.title3)
                            .foregroundStyle(settings.useICloudSync ? NestoryTheme.Colors.accent : NestoryTheme.Colors.muted)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(settings.useICloudSync ? NestoryTheme.Colors.accent.opacity(0.15) : Color.secondary.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                            Text("iCloud Sync")
                                .font(NestoryTheme.Typography.body)
                            if settings.useICloudSync {
                                Text("Syncing across devices")
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.success)
                            }
                        }

                        Spacer()

                        Toggle("", isOn: $settings.useICloudSync)
                            .labelsHidden()
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.iCloudSyncToggle)
                    .accessibilityLabel("iCloud Sync")
                    .accessibilityValue(settings.useICloudSync ? "Enabled" : "Disabled")
                    .accessibilityHint("Double tap to toggle iCloud synchronization")
                    .onChange(of: settings.useICloudSync) { _, newValue in
                        // Show iCloud tip when enabled (Task 8.3.2)
                        if newValue {
                            iCloudSyncTip.iCloudSyncJustEnabled = true
                            Task {
                                try? await Task.sleep(for: .seconds(5))
                                iCloudSyncTip.iCloudSyncJustEnabled = false
                            }
                        }
                    }

                    // iCloud Sync Tip (Task 8.3.2)
                    TipView(iCloudSyncTip())
                        .tipBackground(Color(.secondarySystemGroupedBackground))
                } header: {
                    settingsSectionHeader("Data & Sync", icon: "arrow.triangle.2.circlepath.circle.fill")
                } footer: {
                    Text("iCloud keeps your inventory synced across your devices.")
                        .font(NestoryTheme.Typography.caption)
                }

                // Cloud Sync Status (F7-04)
                if settings.useICloudSync {
                    Section {
                        // Sync status row with indicator
                        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                            // Status indicator dot/spinner
                            syncStatusIndicator
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                                Text("Sync Status")
                                    .font(NestoryTheme.Typography.body)
                                Text(CloudKitSyncMonitor.shared.statusText)
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(syncStatusColor)
                            }

                            Spacer()

                            // Sync Now button
                            Button {
                                triggerManualSync()
                            } label: {
                                if CloudKitSyncMonitor.shared.isSyncing {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sync Now")
                                        .font(NestoryTheme.Typography.caption)
                                        .foregroundStyle(NestoryTheme.Colors.accent)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(CloudKitSyncMonitor.shared.isSyncing)
                            .accessibilityIdentifier("syncNowButton")
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Sync Status: \(CloudKitSyncMonitor.shared.statusText)")

                        // iCloud Settings link if account issue
                        if case .notAvailable = CloudKitSyncMonitor.shared.syncStatus {
                            Button {
                                openICloudSettings()
                            } label: {
                                SettingsRowView(
                                    icon: "gear",
                                    iconColor: NestoryTheme.Colors.accent,
                                    title: "Open iCloud Settings",
                                    subtitle: "Sign in to enable sync",
                                    showChevron: false,
                                    trailing: {
                                        Image(systemName: "arrow.up.right")
                                            .font(NestoryTheme.Typography.caption)
                                            .foregroundStyle(NestoryTheme.Colors.muted)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        settingsSectionHeader("Cloud Sync Status", icon: "icloud.fill")
                    }
                }

                // Backup & Restore (P2-13-1)
                Section {
                    // JSON Export (Free tier)
                    Button {
                        Task {
                            await exportToJSON()
                        }
                    } label: {
                        SettingsRowView(
                            icon: "square.and.arrow.up",
                            iconColor: NestoryTheme.Colors.accent,
                            title: "Export to JSON",
                            subtitle: "Backup all inventory data",
                            showChevron: false,
                            trailing: {
                                if isExportingJSON {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isExportingJSON || isExportingCSV)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.exportDataButton)
                    .accessibilityLabel("Export to JSON")
                    .accessibilityHint("Double tap to export all inventory data to JSON format")

                    // CSV Export (Pro only) - Task 4.3.2
                    Button {
                        if env.settings.isProUnlocked {
                            Task {
                                await exportToCSV()
                            }
                        } else {
                            showingProPaywall = true
                        }
                    } label: {
                        SettingsRowView(
                            icon: "tablecells",
                            iconColor: env.settings.isProUnlocked ? NestoryTheme.Colors.success : NestoryTheme.Colors.muted,
                            title: "Export to CSV",
                            subtitle: env.settings.isProUnlocked ? "Spreadsheet format" : nil,
                            showChevron: false,
                            trailing: {
                                if isExportingCSV {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else if !env.settings.isProUnlocked {
                                    ProBadge()
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isExportingCSV || isExportingJSON && env.settings.isProUnlocked)

                    // Import Data
                    Button {
                        showingImportPicker = true
                    } label: {
                        SettingsRowView(
                            icon: "square.and.arrow.down",
                            iconColor: NestoryTheme.Colors.accent,
                            title: "Import Data",
                            subtitle: "Restore from backup",
                            showChevron: false,
                            trailing: {
                                if isImporting {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isImporting)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.importDataButton)
                    .accessibilityLabel("Import Data")
                    .accessibilityHint("Double tap to restore inventory from a JSON backup")

                    // F6: Import from CSV/Spreadsheet (Pro only)
                    Button {
                        if env.settings.isProUnlocked {
                            showingCSVImportSheet = true
                        } else {
                            showingProPaywall = true
                        }
                    } label: {
                        SettingsRowView(
                            icon: "tablecells.badge.ellipsis",
                            iconColor: env.settings.isProUnlocked ? NestoryTheme.Colors.success : NestoryTheme.Colors.muted,
                            title: "Import from CSV",
                            subtitle: env.settings.isProUnlocked ? "Batch import from spreadsheet" : nil,
                            showChevron: false,
                            trailing: {
                                if !env.settings.isProUnlocked {
                                    ProBadge()
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Import from CSV")
                    .accessibilityHint("Double tap to batch import items from a CSV spreadsheet file")
                } header: {
                    settingsSectionHeader("Backup & Restore", icon: "externaldrive.fill")
                } footer: {
                    Text("Export creates a backup of all items and photos.")
                        .font(NestoryTheme.Typography.caption)
                }
                
                // Appearance (P2-13-1)
                Section {
                    Picker("Theme", selection: $settings.themePreference) {
                        ForEach(ThemePreference.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.themeSelector)

                    Picker("Currency", selection: $settings.preferredCurrencyCode) {
                        ForEach(SettingsManager.supportedCurrencies, id: \.code) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency.code)
                        }
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.currencySelector)
                } header: {
                    settingsSectionHeader("Appearance", icon: "paintbrush.fill")
                }

                // Security & Privacy (P2-13-1)
                Section {
                    // Biometric toggle with icon
                    HStack {
                        Image(systemName: "faceid")
                            .font(.title3)
                            .foregroundStyle(settings.requiresBiometrics ? NestoryTheme.Colors.success : NestoryTheme.Colors.muted)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(settings.requiresBiometrics ? NestoryTheme.Colors.success.opacity(0.15) : Color.secondary.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                            Text("Face ID / Touch ID")
                                .font(NestoryTheme.Typography.body)
                            if settings.requiresBiometrics {
                                Text("App is protected")
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.success)
                            }
                        }

                        Spacer()

                        Toggle("", isOn: $settings.requiresBiometrics)
                            .labelsHidden()
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.appLockToggle)
                    .accessibilityLabel("Biometric Authentication")
                    .accessibilityValue(settings.requiresBiometrics ? "Required" : "Not required")
                    .accessibilityHint("Double tap to toggle biometric lock")

                    if env.settings.requiresBiometrics {
                        Toggle("Lock After Inactivity", isOn: $settings.lockAfterInactivity)
                            .accessibilityLabel("Lock After Inactivity")
                            .accessibilityValue(settings.lockAfterInactivity ? "Enabled" : "Disabled")
                            .accessibilityHint("Double tap to toggle auto-lock after 1 minute of inactivity")
                    }
                } header: {
                    settingsSectionHeader("Security & Privacy", icon: "lock.shield.fill")
                } footer: {
                    Text("Protect your inventory with biometric authentication.")
                        .font(NestoryTheme.Typography.caption)
                }

                // Notifications (P2-13-1)
                Section {
                    Toggle("Documentation Reminders", isOn: $settings.enableDocumentationReminders)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.notificationsToggle)
                        .accessibilityLabel("Documentation Reminders")
                        .accessibilityValue(settings.enableDocumentationReminders ? "Enabled" : "Disabled")
                        .accessibilityHint("Double tap to toggle reminders to document items")

                    if env.settings.enableDocumentationReminders {
                        Toggle("Weekly Summary", isOn: $settings.weeklyReminderEnabled)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.weeklyReminderToggle)
                            .accessibilityLabel("Weekly Summary")
                            .accessibilityValue(settings.weeklyReminderEnabled ? "Enabled" : "Disabled")
                            .accessibilityHint("Double tap to toggle weekly inventory summary notifications")
                    }
                } header: {
                    settingsSectionHeader("Notifications", icon: "bell.fill")
                } footer: {
                    Text("Get reminded to keep your inventory up to date.")
                        .font(NestoryTheme.Typography.caption)
                }

                // Support & Feedback (P2-13-1)
                Section {
                    Button {
                        showingFeedbackSheet = true
                    } label: {
                        SettingsRowView(
                            icon: "bubble.left.and.bubble.right.fill",
                            iconColor: NestoryTheme.Colors.accent,
                            title: "Send Feedback",
                            subtitle: "Share your thoughts",
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.feedbackButton)

                    Button {
                        sendSupportEmail(category: .bug)
                    } label: {
                        SettingsRowView(
                            icon: "ladybug.fill",
                            iconColor: NestoryTheme.Colors.warning,
                            title: "Report a Problem",
                            subtitle: "Let us know what's wrong",
                            showChevron: false,
                            trailing: {
                                Image(systemName: "arrow.up.right")
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.muted)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.reportProblemButton)
                } header: {
                    settingsSectionHeader("Support", icon: "questionmark.circle.fill")
                } footer: {
                    Text("Your feedback helps us improve Nestory.")
                        .font(NestoryTheme.Typography.caption)
                }

                // About (P2-13-1)
                Section {
                    Link(destination: URL(string: "https://nestory-support.netlify.app/terms")!) {
                        SettingsRowView(
                            icon: "doc.text.fill",
                            iconColor: NestoryTheme.Colors.muted,
                            title: "Terms of Service",
                            showChevron: false,
                            trailing: {
                                Image(systemName: "arrow.up.right")
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.muted)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.aboutCell)

                    Link(destination: URL(string: "https://nestory-support.netlify.app/privacy")!) {
                        SettingsRowView(
                            icon: "hand.raised.fill",
                            iconColor: NestoryTheme.Colors.muted,
                            title: "Privacy Policy",
                            showChevron: false,
                            trailing: {
                                Image(systemName: "arrow.up.right")
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.muted)
                            }
                        )
                    }
                    .buttonStyle(.plain)

                    #if DEBUG
                    // Reset Onboarding (Debug only - Task P2-01)
                    Button {
                        settings.hasCompletedOnboarding = false
                    } label: {
                        SettingsRowView(
                            icon: "arrow.counterclockwise",
                            iconColor: .orange,
                            title: "Reset Onboarding",
                            subtitle: "Debug only"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.resetOnboardingButton)
                    #endif
                } header: {
                    settingsSectionHeader("About", icon: "info.circle.fill")
                } footer: {
                    // Version number in footer (P2-13-1)
                    VStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                        Text("Nestory Pro")
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                            .font(NestoryTheme.Typography.caption2)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, NestoryTheme.Metrics.spacingMedium)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProPaywall) {
                ProPaywallView()
            }
            .fileExporter(
                isPresented: Binding(
                    get: { exportedFileURL != nil },
                    set: { if !$0 { exportedFileURL = nil } }
                ),
                document: exportedFileURL.map { ExportedFile(fileURL: $0) },
                contentType: exportedFileURL?.pathExtension == "csv" ? .commaSeparatedText : .json,
                defaultFilename: exportedFileURL?.lastPathComponent ?? "nestory-backup.json"
            ) { result in
                handleExportResult(result)
            }
            .alert("Export Failed", isPresented: $showingExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                } else {
                    Text("An unknown error occurred during export.")
                }
            }
            // Import file picker
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportFileSelection(result)
            }
            // Import confirmation dialog
            .confirmationDialog(
                "Restore Backup",
                isPresented: $showingImportConfirmation,
                titleVisibility: .visible
            ) {
                Button("Merge with Existing") {
                    restoreStrategy = .merge
                    performImport()
                }
                Button("Replace All Data", role: .destructive) {
                    restoreStrategy = .replace
                    performImport()
                }
                Button("Cancel", role: .cancel) {
                    pendingImportURL = nil
                }
            } message: {
                Text("Merge adds backup data to existing inventory. Replace clears existing data first.")
            }
            // Import result alert
            .alert("Restore Complete", isPresented: $showingImportResult) {
                Button("OK", role: .cancel) { }
            } message: {
                if let result = restoreResult {
                    Text(result.summaryText)
                }
            }
            // Import error alert
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = importError {
                    Text(error.localizedDescription)
                } else {
                    Text("An unknown error occurred during import.")
                }
            }
            // Feedback sheet (Task P4-07)
            .sheet(isPresented: $showingFeedbackSheet) {
                FeedbackSheet(feedbackService: feedbackService)
            }
            // F6: CSV Import sheet
            .sheet(isPresented: $showingCSVImportSheet) {
                ImportPreviewView()
            }
            .alert("Email Not Available", isPresented: $showingEmailError) {
                Button("OK", role: .cancel) { }
                Button("Copy Email Address") {
                    UIPasteboard.general.string = FeedbackService.supportEmail
                }
            } message: {
                Text(emailErrorMessage)
            }
        }
    }
    
    // MARK: - Feedback Actions (Task P4-07)

    private func sendSupportEmail(category: FeedbackCategory) {
        feedbackService.openFeedbackEmail(category: category) { success, errorMessage in
            if !success, let error = errorMessage {
                emailErrorMessage = error
                showingEmailError = true
            }
        }
    }

    // MARK: - Export Actions

    /// Export all data to JSON format
    @MainActor
    private func exportToJSON() async {
        isExportingJSON = true
        defer { isExportingJSON = false }

        do {
            // Convert SwiftData models to Sendable export types on MainActor
            let itemExports = allItems.map { ItemExport.from($0) }
            let categoryExports = allCategories.map { CategoryExport.from($0) }
            let roomExports = allRooms.map { RoomExport.from($0) }
            let receiptExports = allReceipts.map { ReceiptExport.from($0) }

            let fileURL = try await env.backupService.exportToJSON(
                itemExports: itemExports,
                categoryExports: categoryExports,
                roomExports: roomExports,
                receiptExports: receiptExports
            )
            exportedFileURL = fileURL
        } catch {
            exportError = error
            showingExportError = true
        }
    }

    /// Export items to CSV format (Pro only)
    @MainActor
    private func exportToCSV() async {
        guard env.settings.isProUnlocked else {
            exportError = NSError(
                domain: "com.drunkonjava.nestory",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "CSV export requires Nestory Pro"]
            )
            showingExportError = true
            return
        }

        isExportingCSV = true
        defer { isExportingCSV = false }

        do {
            // Convert SwiftData models to Sendable export types on MainActor
            let itemExports = allItems.map { ItemExport.from($0) }
            let fileURL = try await env.backupService.exportToCSV(itemExports: itemExports)
            exportedFileURL = fileURL
        } catch {
            exportError = error
            showingExportError = true
        }
    }

    /// Handle export file sharing result
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            // File saved successfully - cleanup temp file if needed
            if let url = exportedFileURL {
                try? FileManager.default.removeItem(at: url)
            }
        case .failure(let error):
            exportError = error
            showingExportError = true
        }
        exportedFileURL = nil
    }
    
    // MARK: - Import Actions (Task 6.3.1/6.3.2)
    
    /// Handle file selection from document picker
    private func handleImportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            pendingImportURL = url
            showingImportConfirmation = true
        case .failure(let error):
            importError = error
            showingImportError = true
        }
    }
    
    /// Perform the actual import with selected strategy
    private func performImport() {
        guard let url = pendingImportURL else { return }

        isImporting = true

        Task {
            do {
                // Need to start security-scoped access for the picked file
                guard url.startAccessingSecurityScopedResource() else {
                    throw BackupError.readFailed(NSError(
                        domain: "com.drunkonjava.nestory",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Cannot access the selected file"]
                    ))
                }
                defer { url.stopAccessingSecurityScopedResource() }

                // Perform restore using BackupService
                let result = try await env.backupService.performRestore(
                    from: url,
                    context: modelContext,
                    strategy: restoreStrategy
                )

                restoreResult = result
                showingImportResult = true
            } catch {
                importError = error
                showingImportError = true
            }

            isImporting = false
            pendingImportURL = nil
        }
    }
}

// MARK: - Exported File Document

/// File document wrapper for exported files
struct ExportedFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }

    var fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // Create temp file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL)
        self.fileURL = tempURL
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: fileURL, options: .immediate)
    }
}

// MARK: - Pro Paywall
struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @State private var product: Product?
    @State private var isLoadingProduct = true
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
                    // Header
                    VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                        Image(systemName: "star.fill")
                            .font(.system(size: NestoryTheme.Metrics.iconHero))
                            .foregroundStyle(.orange)

                        Text("Nestory Pro")
                            .font(NestoryTheme.Typography.largeTitle)

                        Text("One-time purchase. No subscriptions.")
                            .font(NestoryTheme.Typography.subheadline)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                    .padding(.top, NestoryTheme.Metrics.spacingXXLarge)
                    
                    // Features
                    VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingLarge) {
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
                    .padding(.horizontal, NestoryTheme.Metrics.spacingXLarge)
                    
                    // Price
                    VStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                        if isLoadingProduct {
                            ProgressView()
                                .frame(height: 60)
                        } else if let product = product {
                            Text(product.displayPrice)
                                .font(.system(size: 48, weight: .bold))

                            Text("One-time payment")
                                .font(NestoryTheme.Typography.subheadline)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                        } else {
                            Text("$19.99")
                                .font(.system(size: 48, weight: .bold))

                            Text("One-time payment")
                                .font(NestoryTheme.Typography.subheadline)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                        }
                    }
                    .padding(.top, NestoryTheme.Metrics.spacingLarge)
                    
                    // Purchase Button
                    Button(action: {
                        Task {
                            await purchasePro()
                        }
                    }) {
                        if env.iapValidator.isPurchasing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(NestoryTheme.Metrics.paddingMedium)
                        } else {
                            Text("Unlock Nestory Pro")
                                .font(NestoryTheme.Typography.headline)
                                .frame(maxWidth: .infinity)
                                .padding(NestoryTheme.Metrics.paddingMedium)
                        }
                    }
                    .background(NestoryTheme.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
                    .disabled(env.iapValidator.isPurchasing || isLoadingProduct)
                    .padding(.horizontal, NestoryTheme.Metrics.spacingXLarge)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Pro.purchaseButton)

                    Button("Restore Purchases") {
                        Task {
                            await restorePurchases()
                        }
                    }
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .disabled(env.iapValidator.isPurchasing)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Pro.restorePurchasesButton)

                    Text("Free tier includes up to 100 items with all core features.")
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
                        .padding(.bottom, NestoryTheme.Metrics.spacingXXLarge)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier(AccessibilityIdentifiers.Pro.closeButton)
                }
            }
            .task {
                await loadProduct()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: env.iapValidator.isProUnlocked) { _, isUnlocked in
                if isUnlocked {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Actions

    private func loadProduct() async {
        isLoadingProduct = true

        do {
            product = try await env.iapValidator.fetchProduct()
        } catch {
            errorMessage = "Failed to load product: \(error.localizedDescription)"
            showingError = true
        }

        isLoadingProduct = false
    }

    private func purchasePro() async {
        do {
            try await env.iapValidator.purchase()
            // Success - dismiss handled by onChange
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func restorePurchases() async {
        do {
            try await env.iapValidator.restorePurchases()
            // Success - dismiss handled by onChange
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: NestoryTheme.Metrics.spacingMedium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(NestoryTheme.Colors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text(title)
                    .font(NestoryTheme.Typography.headline)

                Text(description)
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
        }
    }
}

// MARK: - Settings Row View (P2-13-1)

/// Reusable row component for settings with icon, title, subtitle, and optional trailing content
struct SettingsRowView<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String?
    var showChevron: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = false,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Icon with colored circle background
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )

            // Title and subtitle
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text(title)
                    .font(NestoryTheme.Typography.body)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }

            Spacer()

            // Trailing content
            trailing()

            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
        }
    }
}

// MARK: - Pro Badge (P2-13-1)

/// Small badge indicating Pro-only feature
struct ProBadge: View {
    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("Pro")
                .font(NestoryTheme.Typography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, NestoryTheme.Metrics.spacingSmall)
        .padding(.vertical, NestoryTheme.Metrics.spacingXSmall)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Section Header Helper

extension SettingsTab {
    /// Creates a styled section header with icon (P2-13-1)
    func settingsSectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(NestoryTheme.Typography.caption)
            .foregroundStyle(NestoryTheme.Colors.muted)
    }

    // MARK: - Sync Status Helpers (F7-04)

    /// Visual indicator for current sync status
    @ViewBuilder
    var syncStatusIndicator: some View {
        switch CloudKitSyncMonitor.shared.syncStatus {
        case .idle:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(NestoryTheme.Colors.success)
                .background(
                    Circle()
                        .fill(NestoryTheme.Colors.success.opacity(0.15))
                )
        case .syncing:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(NestoryTheme.Colors.warning)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(NestoryTheme.Colors.error)
                .background(
                    Circle()
                        .fill(NestoryTheme.Colors.error.opacity(0.15))
                )
        case .disabled, .notAvailable:
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .background(
                    Circle()
                        .fill(NestoryTheme.Colors.muted.opacity(0.15))
                )
        }
    }

    /// Color for sync status text
    var syncStatusColor: Color {
        switch CloudKitSyncMonitor.shared.syncStatus {
        case .idle:
            return NestoryTheme.Colors.success
        case .syncing:
            return NestoryTheme.Colors.warning
        case .error:
            return NestoryTheme.Colors.error
        case .disabled, .notAvailable:
            return NestoryTheme.Colors.muted
        }
    }

    /// Trigger a manual sync by saving context
    func triggerManualSync() {
        // Saving the context triggers CloudKit to sync changes
        try? modelContext.save()
        // Mark as syncing briefly to provide feedback
        CloudKitSyncMonitor.shared.syncStatus = .syncing
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if CloudKitSyncMonitor.shared.syncStatus == .syncing {
                CloudKitSyncMonitor.shared.syncStatus = .idle
                CloudKitSyncMonitor.shared.lastSyncDate = Date()
            }
        }
    }

    /// Open iOS Settings app to iCloud settings
    func openICloudSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsTab()
}

#Preview("Pro Paywall") {
    ProPaywallView()
}

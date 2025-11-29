//
//  SettingsTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import StoreKit
import SwiftData
import UniformTypeIdentifiers

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

    // SwiftData queries for export
    @Query private var allItems: [Item]
    @Query private var allCategories: [Category]
    @Query private var allRooms: [Room]
    @Query private var allReceipts: [Receipt]

    var body: some View {
        @Bindable var settings = env.settings
        NavigationStack {
            List {
                // Account & Pro
                Section {
                    if env.settings.isProUnlocked {
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
                        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.proUpgradeCell)
                    }
                } header: {
                    Text("Account")
                }
                
                // Data & Sync
                Section {
                    Toggle("Use iCloud Sync", isOn: $settings.useICloudSync)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.iCloudSyncToggle)

                    // JSON Export (Free tier)
                    Button {
                        Task {
                            await exportToJSON()
                        }
                    } label: {
                        HStack {
                            Text("Export to JSON")
                            Spacer()
                            if isExportingJSON {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isExportingJSON || isExportingCSV)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.exportDataButton)

                    // CSV Export (Pro only) - Task 4.3.2: Gate CSV export to Pro
                    Button {
                        if env.settings.isProUnlocked {
                            Task {
                                await exportToCSV()
                            }
                        } else {
                            showingProPaywall = true
                        }
                    } label: {
                        HStack {
                            Text("Export to CSV")

                            if !env.settings.isProUnlocked {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("Pro")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            Spacer()
                            if isExportingCSV {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isExportingCSV || isExportingJSON && env.settings.isProUnlocked)

                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Text("Import Data")
                            Spacer()
                            if isImporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isImporting)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.importDataButton)
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
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.themeSelector)

                    Picker("Currency", selection: $settings.preferredCurrencyCode) {
                        ForEach(SettingsManager.supportedCurrencies, id: \.code) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency.code)
                        }
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.currencySelector)
                }
                
                // Security & Privacy
                Section {
                    Toggle("Require Face ID / Touch ID", isOn: $settings.requiresBiometrics)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.appLockToggle)

                    if env.settings.requiresBiometrics {
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
                        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.notificationsToggle)

                    if env.settings.enableDocumentationReminders {
                        Toggle("Weekly Summary", isOn: $settings.weeklyReminderEnabled)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.weeklyReminderToggle)
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
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.aboutCell)

                    Link(destination: URL(string: "https://nestory.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.aboutCell)

                    Link(destination: URL(string: "mailto:support@nestory.app")!) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.aboutCell)
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
        }
    }

    // MARK: - Export Actions

    /// Export all data to JSON format
    @MainActor
    private func exportToJSON() async {
        isExportingJSON = true
        defer { isExportingJSON = false }

        do {
            let fileURL = try await env.backupService.exportToJSON(
                items: allItems,
                categories: allCategories,
                rooms: allRooms,
                receipts: allReceipts
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
            let fileURL = try await env.backupService.exportToCSV(items: allItems)
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
                        if isLoadingProduct {
                            ProgressView()
                                .frame(height: 60)
                        } else if let product = product {
                            Text(product.displayPrice)
                                .font(.system(size: 48, weight: .bold))

                            Text("One-time payment")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("$19.99")
                                .font(.system(size: 48, weight: .bold))

                            Text("One-time payment")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
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
                                .padding()
                        } else {
                            Text("Unlock Nestory Pro")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(env.iapValidator.isPurchasing || isLoadingProduct)
                    .padding(.horizontal, 24)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Pro.purchaseButton)

                    Button("Restore Purchases") {
                        Task {
                            await restorePurchases()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .disabled(env.iapValidator.isPurchasing)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Pro.restorePurchasesButton)
                    
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

//
//  FullInventoryReportView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: FULL INVENTORY REPORT VIEW
// ============================================================================
// Task 3.2.1: SwiftUI view for generating full inventory PDF reports
//
// PURPOSE:
// - Generate comprehensive PDF reports of entire inventory
// - Support flexible grouping: By Room, By Category, Alphabetical
// - Pro tier: include item photos in PDF
// - Free tier: basic text-only PDF
//
// DESIGN FEATURES:
// - Report grouping picker (uses ReportGrouping enum)
// - Include Photos toggle (Pro-gated)
// - Stats preview: total items count, total value
// - Generate button with async PDF generation
// - Loading state with progress indicator
// - PDF preview using QuickLook
// - Share button to export via ShareLink
//
// ARCHITECTURE:
// - Pure SwiftUI view with @Query for all items
// - Uses ReportGeneratorService.shared for PDF generation
// - Uses SettingsManager.shared.isProUnlocked for feature gating
// - QuickLook integration for PDF preview
// - ShareLink for native iOS share sheet
//
// ERROR HANDLING:
// - Empty inventory state (no items to report)
// - PDF generation failures with retry option
// - File system errors during save
//
// NAVIGATION:
// - Presented as full screen or navigation destination from Reports tab
// - Dismisses after sharing or user cancellation
//
// SEE: TODO.md Task 3.2.1 | ReportGeneratorService.swift | SettingsManager.swift
// ============================================================================

import SwiftUI
import SwiftData
import QuickLook

struct FullInventoryReportView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries

    @Query(sort: \Item.name) private var allItems: [Item]

    // MARK: - Dependencies

    private let reportService = ReportGeneratorService.shared
    private let settings = SettingsManager.shared

    // MARK: - State

    @State private var selectedGrouping: ReportGrouping = .byRoom
    @State private var includePhotos: Bool = false
    @State private var includeReceipts: Bool = false
    @State private var isGenerating: Bool = false
    @State private var generatedPDFURL: URL?
    @State private var showingPDFPreview: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String?

    // MARK: - Computed Properties

    private var totalValue: Decimal {
        allItems.reduce(Decimal(0)) { total, item in
            total + (item.purchasePrice ?? 0)
        }
    }

    private var canGenerate: Bool {
        !allItems.isEmpty && !isGenerating
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if allItems.isEmpty {
                    emptyState
                } else {
                    reportConfigurationForm
                }
            }
            .navigationTitle("Full Inventory Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }
            }
            .alert("Generation Failed", isPresented: $showingError) {
                Button("Try Again") {
                    generateReport()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Failed to generate PDF report. Please try again.")
            }
            .quickLookPreview($generatedPDFURL)
        }
    }

    // MARK: - View Components

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Items in Inventory")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add items to your inventory to generate a full inventory report.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reportConfigurationForm: some View {
        Form {
            // Stats Preview Section
            Section {
                statsPreviewRow
            } header: {
                Text("Inventory Summary")
            }

            // Report Options Section
            Section {
                groupingPicker
                includePhotosToggle
                includeReceiptsToggle
            } header: {
                Text("Report Options")
            } footer: {
                if !settings.isProUnlocked && includePhotos {
                    Label(
                        "Photo inclusion requires Pro. Upgrade in Settings.",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            // Generate Button Section
            Section {
                generateButton
            }
        }
    }

    private var statsPreviewRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    // Total Items
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(allItems.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Divider()
                        .frame(height: 40)

                    // Total Value
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(settings.formatCurrency(totalValue))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    private var groupingPicker: some View {
        Picker("Group By", selection: $selectedGrouping) {
            ForEach([ReportGrouping.byRoom, .byCategory, .alphabetical], id: \.self) { grouping in
                Text(grouping.displayName)
                    .tag(grouping)
            }
        }
        .pickerStyle(.segmented)
    }

    private var includePhotosToggle: some View {
        HStack {
            Toggle("Include Photos", isOn: $includePhotos)
                .disabled(!settings.isProUnlocked)

            if !settings.isProUnlocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: includePhotos) { _, newValue in
            if newValue && !settings.isProUnlocked {
                includePhotos = false
            }
        }
    }

    private var includeReceiptsToggle: some View {
        Toggle("Include Receipt Info", isOn: $includeReceipts)
    }

    private var generateButton: some View {
        Button {
            generateReport()
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Generating...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "doc.text.fill")
                    Text("Generate Report")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canGenerate ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canGenerate)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .padding(.horizontal)
    }

    // MARK: - Actions

    @MainActor
    private func generateReport() {
        guard canGenerate else { return }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let options = ReportOptions(
                    grouping: selectedGrouping,
                    includePhotos: settings.isProUnlocked && includePhotos,
                    includeReceipts: includeReceipts
                )

                let pdfURL = try await reportService.generateFullInventoryPDF(
                    items: allItems,
                    options: options
                )

                await MainActor.run {
                    isGenerating = false
                    generatedPDFURL = pdfURL
                    showingPDFPreview = true
                }

            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "Failed to generate report: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Full Inventory Report - Empty") {
    FullInventoryReportView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview("Full Inventory Report - With Items") {
    @Previewable @State var container = makePreviewContainerWithItems()
    FullInventoryReportView()
        .modelContainer(container)
}

// MARK: - Preview Helpers

private func makePreviewContainerWithItems() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Item.self, Room.self, Category.self,
        configurations: config
    )

    let context = container.mainContext

    // Seed rooms
    let livingRoom = Room(name: "Living Room", iconName: "sofa", sortOrder: 0)
    let bedroom = Room(name: "Bedroom", iconName: "bed.double", sortOrder: 1)
    let kitchen = Room(name: "Kitchen", iconName: "fork.knife", sortOrder: 2)
    context.insert(livingRoom)
    context.insert(bedroom)
    context.insert(kitchen)

    // Seed categories
    let electronics = Category(name: "Electronics", iconName: "tv", sortOrder: 0)
    let furniture = Category(name: "Furniture", iconName: "cabinet", sortOrder: 1)
    let appliances = Category(name: "Appliances", iconName: "washer", sortOrder: 2)
    context.insert(electronics)
    context.insert(furniture)
    context.insert(appliances)

    // Seed items with varying properties
    let items: [(String, Decimal, Room, Category)] = [
        ("Smart TV", 1299.99, livingRoom, electronics),
        ("Sectional Sofa", 2499.99, livingRoom, furniture),
        ("Coffee Table", 349.99, livingRoom, furniture),
        ("Queen Bed Frame", 899.99, bedroom, furniture),
        ("Nightstand", 179.99, bedroom, furniture),
        ("Reading Lamp", 89.99, bedroom, electronics),
        ("Refrigerator", 1899.99, kitchen, appliances),
        ("Dishwasher", 799.99, kitchen, appliances),
        ("Microwave", 249.99, kitchen, appliances),
        ("Dining Table", 649.99, kitchen, furniture),
    ]

    for (name, price, room, category) in items {
        let item = Item(
            name: name,
            purchasePrice: price,
            category: category,
            room: room,
            condition: .good
        )
        context.insert(item)
    }

    return container
}

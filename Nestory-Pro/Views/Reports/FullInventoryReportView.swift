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
// P2-13-4: State-driven UI with NestoryTheme styling
//
// PURPOSE:
// - Generate comprehensive PDF reports of entire inventory
// - Support flexible grouping: By Room, By Category, Alphabetical
// - Pro tier: include item photos in PDF
// - Free tier: basic text-only PDF
//
// STATE-DRIVEN UI (P2-13-4):
// - idle: Show "Generate Report" button
// - generating: Spinner + progress message
// - complete: Document card with Open/Share actions
// - error: Red error card with retry button
//
// ARCHITECTURE:
// - Pure SwiftUI view with @Query for all items
// - Uses ReportGeneratorService.shared for PDF generation
// - Uses SettingsManager.shared.isProUnlocked for feature gating
// - QuickLook integration for PDF preview
// - ShareLink for native iOS share sheet
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

    @Environment(AppEnvironment.self) private var env

    // MARK: - State

    @State private var selectedGrouping: ReportGrouping = .byRoom
    @State private var includePhotos: Bool = false
    @State private var includeReceipts: Bool = false
    @State private var isGenerating: Bool = false
    @State private var generatedPDFURL: URL?
    @State private var showingPDFPreview: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String?
    @State private var showingPhotosPaywall: Bool = false // Task 4.3.1: Paywall for photos in PDF

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
            .sheet(isPresented: $showingPhotosPaywall) {
                ProPaywallView()
            }
        }
    }

    // MARK: - View Components

    // MARK: - Empty State (P2-13-4)

    private var emptyState: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(NestoryTheme.Colors.muted)

            Text("No Items in Inventory")
                .font(NestoryTheme.Typography.title2)
                .fontWeight(.semibold)

            Text("Add items to your inventory to generate a full inventory report.")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
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
                if !env.settings.isProUnlocked {
                    Text("Tap 'Include Photos' to upgrade to Pro and add item photos to your PDF reports.")
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

    // MARK: - Stats Preview (P2-13-4)

    private var statsPreviewRow: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingLarge) {
            // Total Items
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text("Total Items")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                Text("\(allItems.count)")
                    .font(NestoryTheme.Typography.title2)
                    .fontWeight(.bold)
            }

            Divider()
                .frame(height: 40)

            // Total Value
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text("Total Value")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                Text(env.settings.formatCurrency(totalValue))
                    .font(NestoryTheme.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(NestoryTheme.Colors.success)
            }

            Spacer()
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

    // MARK: - Include Photos Toggle (P2-13-4)

    // Task 4.3.1: Gate "Include Photos" to Pro with contextual paywall
    private var includePhotosToggle: some View {
        Button {
            if env.settings.isProUnlocked {
                includePhotos.toggle()
            } else {
                showingPhotosPaywall = true
            }
        } label: {
            HStack {
                Toggle("Include Photos", isOn: $includePhotos)
                    .font(NestoryTheme.Typography.body)
                    .disabled(!env.settings.isProUnlocked)
                    .allowsHitTesting(false) // Button handles taps

                if !env.settings.isProUnlocked {
                    ProBadgeInline()
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var includeReceiptsToggle: some View {
        Toggle("Include Receipt Info", isOn: $includeReceipts)
    }

    // MARK: - Generate Button (P2-13-4)

    private var generateButton: some View {
        Button {
            generateReport()
        } label: {
            HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Generating...")
                        .font(NestoryTheme.Typography.headline)
                } else {
                    Image(systemName: "doc.text.fill")
                    Text("Generate Report")
                        .font(NestoryTheme.Typography.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(NestoryTheme.Metrics.paddingMedium)
            .background(canGenerate ? NestoryTheme.Colors.accent : NestoryTheme.Colors.muted)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
        }
        .disabled(!canGenerate)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
    }

    // MARK: - Actions (P2-16-1: Haptic feedback)

    @MainActor
    private func generateReport() {
        guard canGenerate else { return }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let options = ReportOptions(
                    grouping: selectedGrouping,
                    includePhotos: env.settings.isProUnlocked && includePhotos,
                    includeReceipts: includeReceipts
                )

                let pdfURL = try await env.reportGenerator.generateFullInventoryPDF(
                    items: allItems,
                    options: options
                )

                await MainActor.run {
                    isGenerating = false
                    generatedPDFURL = pdfURL
                    showingPDFPreview = true
                    NestoryTheme.Haptics.success() // P2-16-1: Success haptic
                }

            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "Failed to generate report: \(error.localizedDescription)"
                    showingError = true
                    NestoryTheme.Haptics.error() // P2-16-2: Error haptic
                }
            }
        }
    }
}

// MARK: - Pro Badge (P2-13-4)

/// Inline Pro badge for feature gating indicators
private struct ProBadgeInline: View {
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

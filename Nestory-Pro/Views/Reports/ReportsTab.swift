//
//  ReportsTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: Task 3.5.1 - Reports Tab Interface ✓ COMPLETED
// P2-13-3: Summary Dashboard Retrofit
// ============================================================================
// Provides main navigation hub for PDF report generation.
//
// COMPLETED:
// - Task 3.5.1: Report cards UI with navigation to report views ✓
// - Task 3.2.1: FullInventoryReportView integration ✓
// - Task 3.3.1: LossListSelectionView integration ✓
// - P2-13-3: Summary dashboard with 2x2 grid stats from InventorySummary ✓
// - P2-13-3: Card groups: "Inventory Reports", "Loss Documentation" ✓
//
// AVAILABLE REPORTS:
// 1. Full Inventory Report - Comprehensive PDF of all items (FullInventoryReportView)
// 2. Insurance Loss List - Claim-ready report for selected items (LossListSelectionView)
//
// SEE: TODO.md Phase 3 | FullInventoryReportView.swift | LossListSelectionView.swift
// ============================================================================

import SwiftUI
import SwiftData

struct ReportsTab: View {
    // MARK: - Queries

    @Query private var allItems: [Item]

    // MARK: - Dependencies

    @Environment(AppEnvironment.self) private var env
    
    // ViewModel handles report generation and statistics
    private var viewModel: ReportsTabViewModel {
        env.reportsViewModel
    }

    @State private var showingLabelGenerator = false

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel

        return NavigationStack {
            ScrollView {
                VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                    // Quick Stats Section
                    if !allItems.isEmpty {
                        quickStatsSection
                    }

                    // Report Cards - Grouped by type (P2-13-3)
                    VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingLarge) {
                        // Inventory Reports Group
                        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                            reportSectionHeader("Inventory Reports", icon: "doc.text.fill")

                            ReportCard(
                                icon: "doc.text.fill",
                                iconColor: NestoryTheme.Colors.accent,
                                title: "Full Inventory Report",
                                description: "Generate a comprehensive PDF of all your items"
                            ) {
                                viewModel.showFullInventoryReport()
                            }
                        }

                        // Loss Documentation Group
                        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                            reportSectionHeader("Loss Documentation", icon: "exclamationmark.triangle.fill")

                            ReportCard(
                                icon: "exclamationmark.triangle.fill",
                                iconColor: NestoryTheme.Colors.warning,
                                title: "Insurance Loss List",
                                description: "Create a claim-ready report for lost or damaged items"
                            ) {
                                viewModel.showLossListSelection()
                            }
                        }

                        // QR Labels Group (F2)
                        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                            reportSectionHeader("QR Code Labels", icon: "qrcode")

                            ReportCard(
                                icon: "qrcode",
                                iconColor: .purple,
                                title: "Generate Labels",
                                description: "Create printable QR code labels for your items"
                            ) {
                                showingLabelGenerator = true
                            }
                        }
                    }
                    .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
                    .padding(.bottom, NestoryTheme.Metrics.spacingLarge)
                }
                .padding(.top, NestoryTheme.Metrics.spacingLarge)
            }
            .background(NestoryTheme.Colors.background)
            .navigationTitle("Reports")
            .sheet(isPresented: $vm.showingLossListSelection) {
                LossListSelectionView()
            }
            .sheet(isPresented: $vm.showingFullInventoryReport) {
                FullInventoryReportView()
            }
            .sheet(isPresented: $showingLabelGenerator) {
                LabelGeneratorView()
            }
        }
    }

    // MARK: - View Components

    /// Summary dashboard with 2x2 grid stats (P2-13-3)
    private var quickStatsSection: some View {
        let summary = viewModel.generateInventorySummary(allItems)

        return VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Row 1: Total Items & Total Value
            HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                StatCard(
                    title: "Total Items",
                    value: "\(summary.totalItems)",
                    icon: "square.stack.3d.up.fill",
                    color: NestoryTheme.Colors.accent
                )

                StatCard(
                    title: "Total Value",
                    value: env.settings.formatCurrency(summary.totalValue),
                    icon: "dollarsign.circle.fill",
                    color: NestoryTheme.Colors.success
                )
            }

            // Row 2: Categories & Rooms (P2-13-3)
            HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                StatCard(
                    title: "Categories",
                    value: "\(summary.uniqueCategoryCount)",
                    icon: "tag.fill",
                    color: NestoryTheme.Colors.warning
                )

                StatCard(
                    title: "Rooms",
                    value: "\(summary.uniqueRoomCount)",
                    icon: "house.fill",
                    color: .purple
                )
            }
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
    }

    // MARK: - Section Header Helper (P2-13-3)

    /// Styled section header with icon for report groups
    private func reportSectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(NestoryTheme.Typography.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(NestoryTheme.Colors.muted)
            .padding(.leading, NestoryTheme.Metrics.spacingSmall)
    }
}

// MARK: - Supporting Views

/// Reusable report card component with icon, title, description, and tap action
/// P2-14-1: VoiceOver accessibility, P2-15-2: Press feedback, P2-16-1: Haptics
private struct ReportCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            NestoryTheme.Haptics.selection() // P2-16-1: Haptic feedback
            action()
        } label: {
            HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))

                // Content
                VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                    Text(title)
                        .font(NestoryTheme.Typography.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
            .padding(NestoryTheme.Metrics.paddingMedium)
            .background(NestoryTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .scaleEffect(isPressed ? 0.98 : 1.0) // P2-15-2: Press feedback
            .animation(NestoryTheme.Animation.quick, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        // P2-14-1: VoiceOver accessibility
        .accessibilityLabel(title)
        .accessibilityHint("Double-tap to generate \(title.lowercased())")
    }
}

/// Quick stats card for overview metrics (P2-14-1: VoiceOver accessible)
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingSmall) {
            HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(NestoryTheme.Typography.title2)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(NestoryTheme.Metrics.paddingMedium)
        .background(NestoryTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        // P2-14-1: VoiceOver - combine title and value for screen reader
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Previews

#Preview("Reports Tab - Empty") {
    ReportsTab()
        .modelContainer(for: [Item.self], inMemory: true)
}

#Preview("Reports Tab - With Data") {
    @Previewable @State var container = makePreviewContainer()
    ReportsTab()
        .modelContainer(container)
}

// MARK: - Preview Helpers

private func makePreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Item.self, Room.self, Category.self,
        configurations: config
    )

    let context = container.mainContext

    // Seed items with various values
    for i in 1...25 {
        let item = Item(
            name: "Preview Item \(i)",
            purchasePrice: Decimal(Double.random(in: 100...2000))
        )
        context.insert(item)
    }

    return container
}

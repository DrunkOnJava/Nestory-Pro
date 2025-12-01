//
//  ReportsTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: Task 3.5.1 - Reports Tab Interface ✓ COMPLETED
// ============================================================================
// Provides main navigation hub for PDF report generation.
//
// COMPLETED:
// - Task 3.5.1: Report cards UI with navigation to report views ✓
// - Task 3.2.1: FullInventoryReportView integration ✓
// - Task 3.3.1: LossListSelectionView integration ✓
// - Quick stats section showing total items and inventory value
// - Consistent card-based design with other tabs
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

                    // Report Cards
                    VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                        // Full Inventory Report Card
                        ReportCard(
                            icon: "doc.text.fill",
                            iconColor: NestoryTheme.Colors.accent,
                            title: "Full Inventory Report",
                            description: "Generate a comprehensive PDF of all your items"
                        ) {
                            viewModel.showFullInventoryReport()
                        }

                        // Loss List Report Card
                        ReportCard(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: NestoryTheme.Colors.warning,
                            title: "Insurance Loss List",
                            description: "Create a claim-ready report for lost or damaged items"
                        ) {
                            viewModel.showLossListSelection()
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
        }
    }

    // MARK: - View Components

    private var quickStatsSection: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                // Total Items Stat
                StatCard(
                    title: "Total Items",
                    value: "\(allItems.count)",
                    icon: "square.stack.3d.up.fill",
                    color: NestoryTheme.Colors.accent
                )

                // Total Value Stat
                StatCard(
                    title: "Total Value",
                    value: env.settings.formatCurrency(viewModel.calculateTotalInventoryValue(allItems)),
                    icon: "dollarsign.circle.fill",
                    color: NestoryTheme.Colors.success
                )
            }
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
    }
}

// MARK: - Supporting Views

/// Reusable report card component with icon, title, description, and tap action
private struct ReportCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        }
        .buttonStyle(.plain)
    }
}

/// Quick stats card for overview metrics
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

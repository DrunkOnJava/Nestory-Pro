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
                VStack(spacing: 20) {
                    // Quick Stats Section
                    if !allItems.isEmpty {
                        quickStatsSection
                    }

                    // Report Cards
                    VStack(spacing: 16) {
                        // Full Inventory Report Card
                        ReportCard(
                            icon: "doc.text.fill",
                            iconColor: .blue,
                            title: "Full Inventory Report",
                            description: "Generate a comprehensive PDF of all your items"
                        ) {
                            viewModel.showFullInventoryReport()
                        }

                        // Loss List Report Card
                        ReportCard(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange,
                            title: "Insurance Loss List",
                            description: "Create a claim-ready report for lost or damaged items"
                        ) {
                            viewModel.showLossListSelection()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
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
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Total Items Stat
                StatCard(
                    title: "Total Items",
                    value: "\(allItems.count)",
                    icon: "square.stack.3d.up.fill",
                    color: .blue
                )

                // Total Value Stat
                StatCard(
                    title: "Total Value",
                    value: env.settings.formatCurrency(viewModel.calculateTotalInventoryValue(allItems)),
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
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
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

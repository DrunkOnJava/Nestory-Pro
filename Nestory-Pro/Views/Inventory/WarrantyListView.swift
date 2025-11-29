//
//  WarrantyListView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// CLAUDE CODE AGENT: WARRANTY LIST VIEW
// ============================================================================
// Task 10.2.1: Warranty list with expiry filters
// - Shows items with warranty expiry dates
// - Filter by: Expired, Expiring Soon (30 days), Active, All
// - Sort by expiry date
// - Quick actions for warranty renewal reminders
//
// SEE: TODO.md Phase 10 | Item.warrantyExpiryDate
// ============================================================================

import SwiftUI
import SwiftData

/// Filter options for warranty list
enum WarrantyFilter: String, CaseIterable {
    case all = "All Warranties"
    case expiringSoon = "Expiring Soon"
    case active = "Active"
    case expired = "Expired"

    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .expiringSoon: return "exclamationmark.triangle"
        case .active: return "checkmark.shield"
        case .expired: return "xmark.shield"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .expiringSoon: return .orange
        case .active: return .green
        case .expired: return .red
        }
    }
}

/// View displaying items with warranty information and expiry filters
struct WarrantyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Item> { $0.warrantyExpiryDate != nil },
        sort: \Item.warrantyExpiryDate
    ) private var itemsWithWarranty: [Item]

    @State private var selectedFilter: WarrantyFilter = .all
    @State private var showingFilterSheet = false

    // Days threshold for "expiring soon"
    private let expiringThresholdDays = 30

    private var filteredItems: [Item] {
        let now = Date()
        let expiringThreshold = Calendar.current.date(byAdding: .day, value: expiringThresholdDays, to: now) ?? now

        switch selectedFilter {
        case .all:
            return itemsWithWarranty
        case .expiringSoon:
            return itemsWithWarranty.filter { item in
                guard let expiry = item.warrantyExpiryDate else { return false }
                return expiry > now && expiry <= expiringThreshold
            }
        case .active:
            return itemsWithWarranty.filter { item in
                guard let expiry = item.warrantyExpiryDate else { return false }
                return expiry > now
            }
        case .expired:
            return itemsWithWarranty.filter { item in
                guard let expiry = item.warrantyExpiryDate else { return false }
                return expiry <= now
            }
        }
    }

    // MARK: - Statistics

    private var expiredCount: Int {
        itemsWithWarranty.filter { ($0.warrantyExpiryDate ?? .distantFuture) <= Date() }.count
    }

    private var expiringSoonCount: Int {
        let now = Date()
        let threshold = Calendar.current.date(byAdding: .day, value: expiringThresholdDays, to: now) ?? now
        return itemsWithWarranty.filter { item in
            guard let expiry = item.warrantyExpiryDate else { return false }
            return expiry > now && expiry <= threshold
        }.count
    }

    private var activeCount: Int {
        itemsWithWarranty.filter { ($0.warrantyExpiryDate ?? .distantPast) > Date() }.count
    }

    var body: some View {
        List {
            // Summary Section
            Section {
                HStack(spacing: 16) {
                    WarrantyStatCard(
                        title: "Active",
                        count: activeCount,
                        color: .green,
                        iconName: "checkmark.shield"
                    )
                    WarrantyStatCard(
                        title: "Expiring",
                        count: expiringSoonCount,
                        color: .orange,
                        iconName: "exclamationmark.triangle"
                    )
                    WarrantyStatCard(
                        title: "Expired",
                        count: expiredCount,
                        color: .red,
                        iconName: "xmark.shield"
                    )
                }
                .padding(.vertical, 8)
            }

            // Filter Chips
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WarrantyFilter.allCases, id: \.self) { filter in
                            WarrantyFilterChip(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                count: countForFilter(filter)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Items List
            if filteredItems.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label(emptyStateTitle, systemImage: emptyStateIcon)
                    } description: {
                        Text(emptyStateMessage)
                    }
                }
            } else {
                Section("Items (\(filteredItems.count))") {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            WarrantyItemRow(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Warranties")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Helper Methods

    private func countForFilter(_ filter: WarrantyFilter) -> Int {
        switch filter {
        case .all: return itemsWithWarranty.count
        case .expiringSoon: return expiringSoonCount
        case .active: return activeCount
        case .expired: return expiredCount
        }
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Warranties"
        case .expiringSoon: return "No Expiring Warranties"
        case .active: return "No Active Warranties"
        case .expired: return "No Expired Warranties"
        }
    }

    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "shield"
        case .expiringSoon: return "exclamationmark.triangle"
        case .active: return "checkmark.shield"
        case .expired: return "xmark.shield"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "Add warranty expiry dates to your items to track them here."
        case .expiringSoon:
            return "No warranties expiring in the next 30 days."
        case .active:
            return "No items with active warranties."
        case .expired:
            return "No items with expired warranties."
        }
    }
}

// MARK: - Supporting Views

struct WarrantyStatCard: View {
    let title: String
    let count: Int
    let color: Color
    let iconName: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(count)")
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WarrantyFilterChip: View {
    let filter: WarrantyFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? filter.color : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct WarrantyItemRow: View {
    let item: Item

    private var warrantyStatus: WarrantyStatus {
        guard let expiry = item.warrantyExpiryDate else { return .none }
        let now = Date()
        let threshold = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now

        if expiry <= now {
            return .expired
        } else if expiry <= threshold {
            return .expiringSoon
        } else {
            return .active
        }
    }

    private var daysUntilExpiry: Int? {
        guard let expiry = item.warrantyExpiryDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiry)
        return components.day
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: warrantyStatus.iconName)
                .font(.title2)
                .foregroundStyle(warrantyStatus.color)
                .frame(width: 32)

            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                if let brand = item.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Expiry info
                if let expiry = item.warrantyExpiryDate {
                    HStack(spacing: 4) {
                        Text(expiry, style: .date)
                            .font(.caption)
                            .foregroundStyle(warrantyStatus.color)

                        if let days = daysUntilExpiry {
                            Text("(\(daysText(days)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func daysText(_ days: Int) -> String {
        if days < 0 {
            return "\(abs(days)) days ago"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }
}

enum WarrantyStatus {
    case none
    case active
    case expiringSoon
    case expired

    var iconName: String {
        switch self {
        case .none: return "shield"
        case .active: return "checkmark.shield.fill"
        case .expiringSoon: return "exclamationmark.shield.fill"
        case .expired: return "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .none: return .gray
        case .active: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        }
    }
}

#Preview {
    NavigationStack {
        WarrantyListView()
    }
    .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
}

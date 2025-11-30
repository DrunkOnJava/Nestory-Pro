//
//  RemindersView.swift
//  Nestory-Pro
//
//  Created for v1.2 - P5-03
//

// ============================================================================
// REMINDERS VIEW - Task P5-03
// ============================================================================
// "Things to review this month" - surfaces items needing attention
// - Warranty expiring soon
// - Items not updated in 6+ months
// - Items missing documentation
//
// SEE: TODO.md P5-03 | ReminderService.swift | WarrantyListView.swift
// ============================================================================

import SwiftUI
import SwiftData

/// Categories of items needing attention
enum ReminderCategory: String, CaseIterable, Identifiable {
    case warrantyExpiring = "Warranty Expiring"
    case needsReview = "Needs Review"
    case missingInfo = "Missing Info"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .warrantyExpiring: return "exclamationmark.shield"
        case .needsReview: return "clock.arrow.circlepath"
        case .missingInfo: return "doc.badge.plus"
        }
    }
    
    var color: Color {
        switch self {
        case .warrantyExpiring: return .orange
        case .needsReview: return .blue
        case .missingInfo: return .purple
        }
    }
    
    var description: String {
        switch self {
        case .warrantyExpiring: return "Warranties expiring in 30 days"
        case .needsReview: return "Not updated in 6+ months"
        case .missingInfo: return "Documentation below 50%"
        }
    }
}

/// Main reminders view showing items needing attention
struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var appEnv
    
    @Query private var allItems: [Item]
    
    @State private var selectedCategory: ReminderCategory? = nil
    @State private var showingNotificationSettings = false
    
    private var warrantyExpiringItems: [Item] {
        let now = Date()
        let threshold = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        return allItems.filter { item in
            guard let expiry = item.warrantyExpiryDate else { return false }
            return expiry > now && expiry <= threshold
        }.sorted { ($0.warrantyExpiryDate ?? .distantFuture) < ($1.warrantyExpiryDate ?? .distantFuture) }
    }
    
    private var needsReviewItems: [Item] {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return allItems.filter { $0.updatedAt < sixMonthsAgo }
            .sorted { $0.updatedAt < $1.updatedAt }
    }
    
    private var missingInfoItems: [Item] {
        allItems.filter { $0.documentationScore < 0.5 }
            .sorted { $0.documentationScore < $1.documentationScore }
    }
    
    private var totalReminderCount: Int {
        warrantyExpiringItems.count + needsReviewItems.count + missingInfoItems.count
    }
    
    var body: some View {
        List {
            // Summary Header
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("Things to Review")
                            .font(.headline)
                        Spacer()
                        Text("\(totalReminderCount)")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Items that need your attention this month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Category Cards
            Section {
                ForEach(ReminderCategory.allCases) { category in
                    ReminderCategoryCard(
                        category: category,
                        count: countForCategory(category),
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
            
            // Selected Category Items
            if let category = selectedCategory {
                Section(category.rawValue) {
                    let items = itemsForCategory(category)
                    if items.isEmpty {
                        ContentUnavailableView {
                            Label("All Clear", systemImage: "checkmark.circle")
                        } description: {
                            Text("No items in this category")
                        }
                    } else {
                        ForEach(items) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ReminderItemRow(item: item, category: category)
                            }
                        }
                    }
                }
            }
            
            // Notification Settings
            Section {
                Button {
                    showingNotificationSettings = true
                } label: {
                    HStack {
                        Label("Notification Settings", systemImage: "bell")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Get notified before warranties expire")
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsSheet()
        }
    }
    
    private func countForCategory(_ category: ReminderCategory) -> Int {
        switch category {
        case .warrantyExpiring: return warrantyExpiringItems.count
        case .needsReview: return needsReviewItems.count
        case .missingInfo: return missingInfoItems.count
        }
    }
    
    private func itemsForCategory(_ category: ReminderCategory) -> [Item] {
        switch category {
        case .warrantyExpiring: return warrantyExpiringItems
        case .needsReview: return needsReviewItems
        case .missingInfo: return missingInfoItems
        }
    }
}

// MARK: - Category Card

private struct ReminderCategoryCard: View {
    let category: ReminderCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 32)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Count badge
                Text("\(count)")
                    .font(.headline)
                    .foregroundStyle(count > 0 ? category.color : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(count > 0 ? category.color.opacity(0.15) : Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                
                // Chevron
                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? category.color.opacity(0.05) : nil)
    }
}

// MARK: - Item Row

private struct ReminderItemRow: View {
    let item: Item
    let category: ReminderCategory
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(category.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private var detailText: String {
        switch category {
        case .warrantyExpiring:
            if let expiry = item.warrantyExpiryDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
                return "Expires in \(days) days"
            }
            return "Warranty expiring"
        case .needsReview:
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Updated \(formatter.localizedString(for: item.updatedAt, relativeTo: Date()))"
        case .missingInfo:
            return "Documentation: \(Int(item.documentationScore * 100))%"
        }
    }
}

// MARK: - Notification Settings Sheet

struct NotificationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var appEnv
    
    @State private var reminderService: ReminderService?
    @State private var isAuthorized = false
    @State private var pendingCount = 0
    @State private var isScheduling = false
    
    var body: some View {
        NavigationStack {
            List {
                // Status Section
                Section {
                    HStack {
                        Label("Notifications", systemImage: "bell")
                        Spacer()
                        if isAuthorized {
                            Label("Enabled", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else {
                            Label("Disabled", systemImage: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    if isAuthorized {
                        HStack {
                            Text("Pending Reminders")
                            Spacer()
                            Text("\(pendingCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    if !isAuthorized {
                        Text("Enable notifications to receive warranty expiry reminders")
                    }
                }
                
                // Actions Section
                Section {
                    if !isAuthorized {
                        Button {
                            Task {
                                await reminderService?.requestAuthorization()
                                await refreshStatus()
                            }
                        } label: {
                            Label("Enable Notifications", systemImage: "bell.badge")
                        }
                    } else {
                        Button {
                            Task {
                                isScheduling = true
                                // Would need model context here
                                isScheduling = false
                            }
                        } label: {
                            HStack {
                                Label("Schedule All Reminders", systemImage: "calendar.badge.clock")
                                if isScheduling {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isScheduling)
                        
                        Button(role: .destructive) {
                            reminderService?.clearAllReminders()
                            Task { await refreshStatus() }
                        } label: {
                            Label("Clear All Reminders", systemImage: "trash")
                        }
                    }
                }
                
                // Info Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Warranty Reminders", systemImage: "shield")
                            .font(.headline)
                        Text("You'll receive a notification 7 days before each warranty expires.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                reminderService = ReminderService()
                await refreshStatus()
            }
        }
    }
    
    private func refreshStatus() async {
        await reminderService?.checkAuthorizationStatus()
        isAuthorized = reminderService?.isAuthorized ?? false
        pendingCount = await reminderService?.getPendingRemindersCount() ?? 0
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Reminders View") {
    NavigationStack {
        RemindersView()
    }
    .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
    .environment(AppEnvironment())
}

#Preview("Notification Settings") {
    NotificationSettingsSheet()
        .environment(AppEnvironment())
}
#endif

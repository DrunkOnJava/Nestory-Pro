//
//  LossListSelectionView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: LOSS LIST SELECTION VIEW
// ============================================================================
// Task 3.3.1: Multi-select item list for loss report generation
//
// PURPOSE:
// - Allow users to select items for inclusion in loss report
// - Free tier: limited to 20 items max
// - Pro tier: unlimited item selection
// - Search and filter capabilities for large inventories
//
// DESIGN FEATURES:
// - Multi-select checkboxes with visual feedback
// - Search bar for filtering by item name
// - Quick select buttons: "All in Room", "All in Category"
// - Selection count display in toolbar
// - Pro upgrade prompt when free tier limit reached
//
// NAVIGATION FLOW:
// - User selects items from inventory
// - Taps "Continue" to proceed to IncidentDetailsSheet (Task 3.3.2)
// - Final step generates PDF via LossListPDFView (Task 3.3.3)
//
// FREE TIER ENFORCEMENT:
// - Non-Pro users capped at 20 items (SettingsManager.maxFreeLossListItems)
// - Warning badge appears when approaching limit (18+ items)
// - Upgrade prompt shown when attempting to exceed limit
//
// ARCHITECTURE:
// - Pure SwiftUI view with @Query for items
// - @State for selection tracking (Set<Item>)
// - Uses SettingsManager.shared.isProUnlocked for Pro status
// - Navigation handled via sheet presentation
//
// FUTURE ENHANCEMENTS:
// - Task 3.3.4: Save draft selections for later
// - Task 7.1.x: VoiceOver accessibility labels
// - Task 8.2.x: Analytics tracking for feature usage
//
// SEE: TODO.md Task 3.3.1 | IncidentDetailsSheet.swift | SettingsManager.swift
// ============================================================================

import SwiftUI
import SwiftData

struct LossListSelectionView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries

    @Query(sort: \Item.name) private var allItems: [Item]
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    // MARK: - Dependencies

    @Environment(AppEnvironment.self) private var env

    // MARK: - State

    @State private var selectedItems: Set<Item.ID> = []
    @State private var searchText: String = ""
    @State private var showingIncidentDetails: Bool = false
    @State private var showingProUpgrade: Bool = false
    @State private var quickSelectFilter: QuickSelectFilter = .none

    // MARK: - Computed Properties

    /// Items filtered by search text
    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    /// Number of currently selected items
    private var selectedCount: Int {
        selectedItems.count
    }

    /// Whether user can add more items to selection (based on Pro status)
    private var canSelectMore: Bool {
        if env.settings.isProUnlocked {
            return true
        } else {
            return selectedCount < env.settings.maxFreeLossListItems
        }
    }

    /// Whether to show warning about approaching limit
    private var shouldShowLimitWarning: Bool {
        !env.settings.isProUnlocked && selectedCount >= 18 && selectedCount < env.settings.maxFreeLossListItems
    }

    /// Whether "Continue" button should be enabled
    private var canContinue: Bool {
        !selectedItems.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Quick Select Buttons
                if !allItems.isEmpty {
                    quickSelectButtons
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

                // Limit Warning Banner
                if shouldShowLimitWarning {
                    limitWarningBanner
                }

                // Item List
                if filteredItems.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .navigationTitle("Select Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    selectionCounter
                }

                ToolbarItem(placement: .primaryAction) {
                    if selectedCount > 0 {
                        Button("Clear All") {
                            selectedItems.removeAll()
                        }
                        .font(.subheadline)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                continueButton
            }
            .sheet(isPresented: $showingIncidentDetails) {
                // Task 3.3.2: IncidentDetailsSheet integration ✓
                let selectedItemsList = allItems.filter { selectedItems.contains($0.id) }
                IncidentDetailsSheet(selectedItems: selectedItemsList)
            }
            .alert("Upgrade to Pro", isPresented: $showingProUpgrade) {
                Button("Upgrade", role: .none) {
                    // TODO: Task 4.2.x - Navigate to Pro purchase flow
                }
                Button("Not Now", role: .cancel) { }
            } message: {
                Text("Free accounts are limited to \(env.settings.maxFreeLossListItems) items per loss report. Upgrade to Pro for unlimited items.")
            }
        }
    }

    // MARK: - View Components

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search items", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var quickSelectButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Select by Room
                Menu {
                    ForEach(rooms) { room in
                        Button {
                            selectAllItems(in: room)
                        } label: {
                            Label(room.name, systemImage: room.iconName)
                        }
                    }
                } label: {
                    Label("By Room", systemImage: "house")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(8)
                }

                // Select by Category
                Menu {
                    ForEach(categories) { category in
                        Button {
                            selectAllItems(in: category)
                        } label: {
                            Label(category.name, systemImage: category.iconName)
                        }
                    }
                } label: {
                    Label("By Category", systemImage: "tag")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(8)
                }

                // Select All
                Button {
                    selectAllVisibleItems()
                } label: {
                    Label("Select All", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(8)
                }
            }
        }
    }

    private var limitWarningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Approaching limit: \(selectedCount) of \(env.settings.maxFreeLossListItems) items")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Upgrade") {
                showingProUpgrade = true
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
    }

    private var itemList: some View {
        List {
            ForEach(filteredItems) { item in
                ItemRow(
                    item: item,
                    isSelected: selectedItems.contains(item.id),
                    canSelect: canSelectMore || selectedItems.contains(item.id)
                ) {
                    toggleSelection(for: item)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            if searchText.isEmpty {
                Text("No Items")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Add items to your inventory to create a loss report.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("No Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("No items match \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectionCounter: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(selectedCount > 0 ? .blue : .secondary)
            Text("\(selectedCount)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(selectedCount > 0 ? .primary : .secondary)
            if !env.settings.isProUnlocked {
                Text("/ \(env.settings.maxFreeLossListItems)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var continueButton: some View {
        Button {
            showingIncidentDetails = true
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canContinue ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        .disabled(!canContinue)
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Actions

    /// Toggles selection for a single item
    private func toggleSelection(for item: Item) {
        if selectedItems.contains(item.id) {
            // Always allow deselection
            selectedItems.remove(item.id)
        } else {
            // Check limit before selection
            if canSelectMore {
                selectedItems.insert(item.id)
            } else {
                showingProUpgrade = true
            }
        }
    }

    /// Selects all items in a given room
    private func selectAllItems(in room: Room) {
        let roomItems = filteredItems.filter { $0.room?.id == room.id }
        selectItems(roomItems)
    }

    /// Selects all items in a given category
    private func selectAllItems(in category: Category) {
        let categoryItems = filteredItems.filter { $0.category?.id == category.id }
        selectItems(categoryItems)
    }

    /// Selects all currently visible items (respecting filters)
    private func selectAllVisibleItems() {
        selectItems(filteredItems)
    }

    /// Helper to select multiple items with limit enforcement
    private func selectItems(_ items: [Item]) {
        for item in items {
            // Stop if we hit the limit
            guard canSelectMore || selectedItems.contains(item.id) else {
                showingProUpgrade = true
                return
            }
            selectedItems.insert(item.id)
        }
    }
}

// MARK: - Supporting Types

private enum QuickSelectFilter {
    case none
    case room(Room)
    case category(Category)
}

// MARK: - Item Row Component

private struct ItemRow: View {
    let item: Item
    let isSelected: Bool
    let canSelect: Bool
    let onTap: () -> Void

    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                // Item Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        // Value
                        if let value = item.purchasePrice {
                            Text(env.settings.formatCurrency(value))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Room
                        if let room = item.room {
                            Label(room.name, systemImage: room.iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Category
                        if let category = item.category {
                            Label(category.name, systemImage: category.iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Disabled indicator (if limit reached)
                if !canSelect && !isSelected {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity((!canSelect && !isSelected) ? 0.5 : 1.0)
    }
}

// MARK: - Previews

#Preview("Loss List Selection - Empty") {
    LossListSelectionView()
        .modelContainer(for: [Item.self, Room.self, Category.self], inMemory: true)
}

#Preview("Loss List Selection - With Items") {
    @Previewable @State var container = makePreviewContainerWithItems()
    LossListSelectionView()
        .modelContainer(container)
}

#Preview("Loss List Selection - Free Tier Limit") {
    @Previewable @State var container = makePreviewContainerWithLimit()
    LossListSelectionView()
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
    context.insert(livingRoom)
    context.insert(bedroom)

    // Seed categories
    let electronics = Category(name: "Electronics", iconName: "tv", sortOrder: 0)
    let furniture = Category(name: "Furniture", iconName: "cabinet", sortOrder: 1)
    context.insert(electronics)
    context.insert(furniture)

    // Seed items
    for i in 1...25 {
        let item = Item(
            name: "Item \(i)",
            purchasePrice: Decimal(Double.random(in: 100...1000)),
            category: i % 2 == 0 ? electronics : furniture,
            room: i % 2 == 0 ? livingRoom : bedroom
        )
        context.insert(item)
    }

    return container
}

private func makePreviewContainerWithLimit() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Item.self, Room.self, Category.self,
        configurations: config
    )

    let context = container.mainContext

    // Seed with exactly 20 items (free tier limit)
    for i in 1...20 {
        let item = Item(
            name: "Limited Item \(i)",
            purchasePrice: Decimal(Double.random(in: 100...500))
        )
        context.insert(item)
    }

    return container
}

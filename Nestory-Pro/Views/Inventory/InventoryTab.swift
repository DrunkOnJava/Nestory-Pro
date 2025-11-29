//
//  InventoryTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import SwiftData

enum ItemFilter: String, CaseIterable {
    case all = "All Items"
    case needsPhoto = "Needs Photo"
    case needsReceipt = "Needs Receipt"
    case needsValue = "Needs Value"
    case highValue = "High Value"

    // MARK: - SwiftData Predicate Support

    /// Returns a SwiftData Predicate for database-level filtering.
    /// Note: Relationship-based predicates (needsPhoto, needsReceipt) are not
    /// supported by SwiftData's Predicate syntax for collection counts, so we
    /// return nil and fall back to Swift filtering for those cases.
    var swiftDataPredicate: Predicate<Item>? {
        switch self {
        case .all:
            // No filtering needed
            return nil

        case .needsValue:
            // Filter items where purchasePrice is nil
            return #Predicate<Item> { item in
                item.purchasePrice == nil
            }

        case .highValue:
            // Filter items with purchasePrice > 1000
            return #Predicate<Item> { item in
                (item.purchasePrice ?? 0) > 1000
            }

        case .needsPhoto, .needsReceipt:
            // SwiftData predicates cannot check relationship collection counts
            // Fall back to Swift filtering for these cases
            return nil
        }
    }

    /// Legacy Swift closure predicate for cases where SwiftData predicates
    /// are not supported (relationship counts). Used as fallback.
    var swiftPredicate: ((Item) -> Bool) {
        switch self {
        case .all: return { _ in true }
        case .needsPhoto: return { $0.photos.isEmpty }
        case .needsReceipt: return { $0.receipts.isEmpty }
        case .needsValue: return { $0.purchasePrice == nil }
        case .highValue: return { ($0.purchasePrice ?? 0) > 1000 }
        }
    }
}

enum ItemSort: String, CaseIterable {
    case nameAsc = "Name A–Z"
    case nameDesc = "Name Z–A"
    case valueHigh = "Value: High → Low"
    case valueLow = "Value: Low → High"
    case newest = "Newest Added"
    case oldest = "Oldest Added"
}

enum ViewMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"

    var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}

struct InventoryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var rooms: [Room]

    @Environment(AppEnvironment.self) private var env

    // ViewModel handles filtering, sorting, stats, and UI state
    private var viewModel: InventoryTabViewModel {
        env.inventoryViewModel
    }

    // MARK: - Dynamic Query with SwiftData Predicates

    /// Fetch items with database-level filtering when possible.
    /// Performance: Filters applied at database level reduce memory usage for large inventories.
    /// For filters that require relationship counts (needsPhoto, needsReceipt), we fetch all
    /// items and filter in Swift due to SwiftData predicate limitations.
    private var items: [Item] {
        let predicate = viewModel.selectedFilter.swiftDataPredicate
        let descriptor = FetchDescriptor<Item>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var filteredItems: [Item] {
        viewModel.processItems(items)
    }

    var body: some View {
        @Bindable var vm = viewModel
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Cards
                    summarySection

                    // Item Limit Warning Banner (Task 4.1.2)
                    if viewModel.shouldShowItemLimitWarning(itemCount: items.count) {
                        itemLimitWarningBanner
                    }

                    // Filter & Sort
                    filterSection

                    // Items List/Grid
                    itemsSection
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.addItem) {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.addButton)
                    .accessibilityLabel("Add Item")
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search items...")
            .onSubmit(of: .search) {
                // Search text binding is automatically updated
            }
            .sheet(isPresented: $vm.showingAddItem) {
                AddItemView()
            }
            .sheet(isPresented: $vm.showingDocumentationInfo) {
                DocumentationInfoSheet(
                    totalItems: items.count,
                    documentedCount: viewModel.calculateDocumentedCount(items)
                )
            }
            .sheet(isPresented: $vm.showingProPaywall) {
                ProPaywallView()
            }
        }
    }
    
    // MARK: - Item Limit Warning Banner (Task 4.1.2)

    private var itemLimitWarningBanner: some View {
        let warningLevel = viewModel.itemLimitWarningLevel(itemCount: items.count)
        
        return HStack(alignment: .top, spacing: 12) {
            // Warning icon
            Image(systemName: warningLevel == .limitReached ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.title3)
                .foregroundStyle(warningLevel == .limitReached ? .red : .orange)

            // Message
            VStack(alignment: .leading, spacing: 8) {
                Text(warningLevel == .limitReached ? "Item Limit Reached" : "Approaching Item Limit")
                    .font(.headline)
                    .foregroundStyle(warningLevel == .limitReached ? .red : .orange)

                Text(warningLevel == .limitReached
                     ? "You've reached the 100-item limit for free users. Upgrade to Pro for unlimited items."
                     : "You've used \(items.count) of 100 free items. Upgrade to Pro for unlimited storage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Upgrade button
                Button(action: viewModel.showProPaywall) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("Upgrade to Pro")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(warningLevel == .limitReached ? Color.red : Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 4)
            }

            Spacer()

            // Dismiss button
            Button(action: {
                withAnimation {
                    viewModel.dismissItemLimitWarning()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Dismiss warning")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(warningLevel == .limitReached
                      ? Color.red.opacity(0.1)
                      : Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(warningLevel == .limitReached ? Color.red : Color.orange, lineWidth: 1)
        )
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        let totalValue = viewModel.calculateTotalValue(items)
        let documentationScore = viewModel.calculateDocumentationScore(items)
        let documentedCount = viewModel.calculateDocumentedCount(items)
        let uniqueRoomCount = viewModel.calculateUniqueRoomCount(items)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Total Items",
                    value: "\(items.count)",
                    subtitle: "Across \(uniqueRoomCount) rooms",
                    iconName: "archivebox.fill",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Estimated Value",
                    value: env.settings.formatCurrency(totalValue),
                    subtitle: "Based on entered values",
                    iconName: "dollarsign.circle.fill",
                    color: .green
                )
                
                SummaryCard(
                    title: "Documentation",
                    value: "\(documentationScore)%",
                    subtitle: "\(documentedCount) items documented",
                    iconName: "checkmark.shield.fill",
                    color: documentationScore >= 80 ? .green : (documentationScore >= 50 ? .orange : .red)
                ) {
                    viewModel.showDocumentationInfo()
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        @Bindable var vm = viewModel
        
        return VStack(spacing: 12) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ItemFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            label: filter.rawValue,
                            isSelected: vm.selectedFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                vm.selectedFilter = filter
                            }
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.filterChip)
                    }
                }
            }
            
            // View mode and sort
            HStack {
                // View mode toggle
                Picker("View", selection: $vm.viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.iconName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.layoutToggle)
                
                Spacer()
                
                // Sort menu
                Menu {
                    ForEach(ItemSort.allCases, id: \.self) { sort in
                        Button(action: { vm.selectedSort = sort }) {
                            HStack {
                                Text(sort.rawValue)
                                if vm.selectedSort == sort {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Sort")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.sortButton)
            }
        }
    }
    
    // MARK: - Items Section
    @ViewBuilder
    private var itemsSection: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else if viewModel.viewMode == .list {
            LazyVStack(spacing: 8) {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemListCell(item: item, settings: env.settings)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        itemContextMenu(for: item)
                    }
                }
            }
        } else {
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemGridCell(item: item, settings: env.settings)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        itemContextMenu(for: item)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func itemContextMenu(for item: Item) -> some View {
        Button(action: {}) {
            Label("Edit", systemImage: "pencil")
        }
        Button(action: {}) {
            Label("Add Photo", systemImage: "camera")
        }
        Button(action: {}) {
            Label("Add Receipt", systemImage: "doc.text")
        }
        Divider()
        Button(role: .destructive, action: { deleteItem(item) }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if items.isEmpty {
            EmptyStateView(
                iconName: "archivebox",
                title: "No Items Yet",
                message: "Start by adding your first item. Tap the + button to begin documenting your belongings.",
                buttonTitle: "Add First Item",
                buttonAction: viewModel.addItem
            )
            .frame(minHeight: 300)
        } else {
            EmptyStateView(
                iconName: "magnifyingglass",
                title: "No Results",
                message: "No items match your current search or filter. Try adjusting your criteria."
            )
            .frame(minHeight: 200)
        }
    }
    
    private func deleteItem(_ item: Item) {
        modelContext.delete(item)
    }
}

// MARK: - Documentation Info Sheet
struct DocumentationInfoSheet: View {
    let totalItems: Int
    let documentedCount: Int
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Documentation Score")
                            .font(.headline)
                        
                        Text("This score shows how many of your items have enough information for an insurance claim.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("What counts as documented?") {
                    Label("At least one photo", systemImage: "camera.fill")
                    Label("Purchase value entered", systemImage: "dollarsign.circle.fill")
                    Label("Category assigned", systemImage: "folder.fill")
                    Label("Room/location set", systemImage: "door.left.hand.closed")
                }
                
                Section("Your Progress") {
                    HStack {
                        Text("Documented Items")
                        Spacer()
                        Text("\(documentedCount) of \(totalItems)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Text("Tip: Aim for 80%+ documentation. Focus on high-value items first — TVs, laptops, jewelry, and instruments.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Documentation Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    InventoryTab()
        .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
}

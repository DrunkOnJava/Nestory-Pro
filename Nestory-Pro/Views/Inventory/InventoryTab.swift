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
    
    var predicate: ((Item) -> Bool) {
        switch self {
        case .all: return { _ in true }
        case .needsPhoto: return { !$0.hasPhoto }
        case .needsReceipt: return { !$0.hasReceipt }
        case .needsValue: return { !$0.hasValue }
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
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @Query private var rooms: [Room]
    
    @State private var searchText = ""
    @State private var selectedFilter: ItemFilter = .all
    @State private var selectedSort: ItemSort = .newest
    @State private var viewMode: ViewMode = .list
    @State private var showingAddItem = false
    @State private var showingDocumentationInfo = false
    
    private let settings = SettingsManager.shared
    
    private var filteredItems: [Item] {
        var result = items
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.category?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.room?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply filter
        result = result.filter(selectedFilter.predicate)
        
        // Apply sort
        result = sortItems(result)
        
        return result
    }
    
    private func sortItems(_ items: [Item]) -> [Item] {
        switch selectedSort {
        case .nameAsc:
            return items.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .nameDesc:
            return items.sorted { $0.name.localizedCompare($1.name) == .orderedDescending }
        case .valueHigh:
            return items.sorted { ($0.purchasePrice ?? 0) > ($1.purchasePrice ?? 0) }
        case .valueLow:
            return items.sorted { ($0.purchasePrice ?? 0) < ($1.purchasePrice ?? 0) }
        case .newest:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return items.sorted { $0.createdAt < $1.createdAt }
        }
    }
    
    // MARK: - Computed Stats
    private var totalValue: Decimal {
        items.compactMap(\.purchasePrice).reduce(0, +)
    }
    
    private var documentedCount: Int {
        items.filter(\.isDocumented).count
    }
    
    private var documentationScore: Int {
        guard !items.isEmpty else { return 0 }
        return Int((Double(documentedCount) / Double(items.count)) * 100)
    }
    
    private var uniqueRoomCount: Int {
        Set(items.compactMap(\.room?.id)).count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Cards
                    summarySection
                    
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
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.addButton)
                    .accessibilityLabel("Add Item")
                }
            }
            .searchable(text: $searchText, prompt: "Search items...")
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
            .sheet(isPresented: $showingDocumentationInfo) {
                DocumentationInfoSheet(
                    totalItems: items.count,
                    documentedCount: documentedCount
                )
            }
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
                    value: settings.formatCurrency(totalValue),
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
                    showingDocumentationInfo = true
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ItemFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            label: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
            }
            
            // View mode and sort
            HStack {
                // View mode toggle
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.iconName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                
                Spacer()
                
                // Sort menu
                Menu {
                    ForEach(ItemSort.allCases, id: \.self) { sort in
                        Button(action: { selectedSort = sort }) {
                            HStack {
                                Text(sort.rawValue)
                                if selectedSort == sort {
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
            }
        }
    }
    
    // MARK: - Items Section
    @ViewBuilder
    private var itemsSection: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else if viewMode == .list {
            LazyVStack(spacing: 8) {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemListCell(item: item, settings: settings)
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
                        ItemGridCell(item: item, settings: settings)
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
                buttonAction: { showingAddItem = true }
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

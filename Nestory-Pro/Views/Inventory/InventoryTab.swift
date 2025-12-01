//
//  InventoryTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import SwiftData
import TipKit

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
    @Query private var allItems: [Item]  // For deep link lookup

    @Environment(AppEnvironment.self) private var env

    // F2: Deep link navigation from QR code scans
    @Binding var deepLinkItemID: UUID?

    // ViewModel handles filtering, sorting, stats, and UI state
    private var viewModel: InventoryTabViewModel {
        env.inventoryViewModel
    }

    init(deepLinkItemID: Binding<UUID?> = .constant(nil)) {
        self._deepLinkItemID = deepLinkItemID
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
        let documentationScoreTip = DocumentationScoreTip()
        
        NavigationStack {
            ScrollView {
                VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                    // Documentation score tip (Task 8.3.1)
                    TipView(documentationScoreTip) { action in
                        if action.id == "learn-more" {
                            viewModel.showDocumentationInfo()
                        }
                    }
                    .tipBackground(NestoryTheme.Colors.cardBackground)
                    
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
                .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
            }
            .background(NestoryTheme.Colors.background)
            .refreshable {
                // Pull-to-refresh (P2-09-3)
                // SwiftData auto-refreshes on model changes, but this provides
                // visual feedback and allows future CloudKit sync triggers
                await refreshInventory()
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.addItem) {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.addButton)
                    .accessibilityLabel("Add Item")
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                        Button(action: viewModel.showSearchHelp) {
                            Image(systemName: "questionmark.circle")
                        }
                        .accessibilityLabel("Search Help")
                        
                        NavigationLink(destination: RemindersView()) {
                            Image(systemName: "bell.badge")
                        }
                        .accessibilityLabel("Reminders")
                    }
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
            .sheet(isPresented: $vm.showingSearchHelp) {
                SearchHelpSheet()
            }
            // F2: Deep link navigation - show item detail when scanning QR code
            .sheet(item: deepLinkBinding) { item in
                NavigationStack {
                    ItemDetailView(item: item)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    deepLinkItemID = nil
                                }
                            }
                        }
                }
            }
            .onAppear {
                // Update tip parameter based on documentation score
                let score = viewModel.calculateDocumentationScore(items)
                DocumentationScoreTip.documentationScoreIsLow = score < 70
            }
        }
    }

    // MARK: - Deep Link Support (F2)

    /// Binding that looks up the item by ID for deep link navigation
    private var deepLinkBinding: Binding<Item?> {
        Binding<Item?>(
            get: {
                guard let id = deepLinkItemID else { return nil }
                return allItems.first { $0.id == id }
            },
            set: { newValue in
                deepLinkItemID = newValue?.id
            }
        )
    }
    
    // MARK: - Item Limit Warning Banner (Task 4.1.2)

    private var itemLimitWarningBanner: some View {
        let warningLevel = viewModel.itemLimitWarningLevel(itemCount: items.count)
        let warningColor = warningLevel == .limitReached ? NestoryTheme.Colors.error : NestoryTheme.Colors.warning

        return HStack(alignment: .top, spacing: NestoryTheme.Metrics.spacingMedium) {
            // Warning icon
            Image(systemName: warningLevel == .limitReached ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.title3)
                .foregroundStyle(warningColor)

            // Message
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                Text(warningLevel == .limitReached ? "Item Limit Reached" : "Approaching Item Limit")
                    .font(NestoryTheme.Typography.headline)
                    .foregroundStyle(warningColor)

                Text(warningLevel == .limitReached
                     ? "You've reached the 100-item limit for free users. Upgrade to Pro for unlimited items."
                     : "You've used \(items.count) of 100 free items. Upgrade to Pro for unlimited storage.")
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)

                // Upgrade button
                Button(action: viewModel.showProPaywall) {
                    HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                        Image(systemName: "star.fill")
                        Text("Upgrade to Pro")
                    }
                    .font(NestoryTheme.Typography.buttonLabel)
                    .foregroundStyle(.white)
                    .padding(.horizontal, NestoryTheme.Metrics.paddingLarge)
                    .padding(.vertical, NestoryTheme.Metrics.paddingSmall)
                    .background(warningColor)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
                }
                .padding(.top, NestoryTheme.Metrics.paddingXSmall)
            }

            Spacer()

            // Dismiss button
            Button(action: {
                withAnimation(NestoryTheme.Animation.quick) {
                    viewModel.dismissItemLimitWarning()
                }
            }) {
                Image(systemName: "xmark")
                    .font(NestoryTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
            .accessibilityLabel("Dismiss warning")
        }
        .padding(NestoryTheme.Metrics.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge)
                .fill(warningColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge)
                .stroke(warningColor, lineWidth: 1)
        )
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        let totalValue = viewModel.calculateTotalValue(items)
        let documentationScore = viewModel.calculateDocumentationScore(items)
        let documentedCount = viewModel.calculateDocumentedCount(items)
        let uniqueRoomCount = viewModel.calculateUniqueRoomCount(items)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
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
            .padding(.vertical, NestoryTheme.Metrics.paddingXSmall)
        }
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        @Bindable var vm = viewModel

        return VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                    ForEach(ItemFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            label: filter.rawValue,
                            isSelected: vm.selectedFilter == filter
                        ) {
                            withAnimation(NestoryTheme.Animation.quick) {
                                vm.selectedFilter = filter
                            }
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.filterChip)
                        .accessibilityLabel("Filter: \(filter.rawValue)")
                        .accessibilityAddTraits(vm.selectedFilter == filter ? .isSelected : [])
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
                .accessibilityLabel("View mode: \(vm.viewMode.rawValue)")
                .accessibilityHint("Double tap to switch between list and grid view")
                
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
                .accessibilityLabel("Sort items: \(vm.selectedSort.rawValue)")
                .accessibilityHint("Double tap to change sort order")
            }
        }
    }
    
    // MARK: - Items Section
    @ViewBuilder
    private var itemsSection: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else if viewModel.viewMode == .list {
            // Use grouped sections for better organization (P2-09-3)
            let sections = viewModel.groupedSections(items)

            LazyVStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                ForEach(sections) { sectionData in
                    VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                        // Section header (P2-09-3)
                        sectionHeader(sectionData)

                        // Item cards (P2-09-3: each item in .cardStyle())
                        ForEach(sectionData.items) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ItemListCell(item: item, settings: env.settings)
                                    .cardStyle()
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                itemContextMenu(for: item)
                            }
                        }
                    }
                }
            }
            // Performance: Force SwiftUI to refresh list on filter/sort changes for efficient diffing
            .id("\(viewModel.selectedFilter.rawValue)-\(viewModel.selectedSort.rawValue)")
        } else {
            let columns = [
                GridItem(.flexible(), spacing: NestoryTheme.Metrics.spacingMedium),
                GridItem(.flexible(), spacing: NestoryTheme.Metrics.spacingMedium)
            ]

            LazyVGrid(columns: columns, spacing: NestoryTheme.Metrics.spacingMedium) {
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
            // Performance: Force SwiftUI to refresh grid on filter/sort changes for efficient diffing
            .id("\(viewModel.selectedFilter.rawValue)-\(viewModel.selectedSort.rawValue)")
        }
    }

    // MARK: - Section Header (P2-09-3)
    @ViewBuilder
    private func sectionHeader(_ sectionData: InventorySectionData) -> some View {
        HStack {
            Image(systemName: sectionData.iconName)
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.accent)

            Text(sectionData.displayName)
                .font(NestoryTheme.Typography.headline)

            Spacer()

            Text("\(sectionData.itemCount) items")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sectionData.displayName) section, \(sectionData.itemCount) items")
    }

    // MARK: - Loading State (P2-09-3)
    @ViewBuilder
    private var loadingStateView: some View {
        LazyVStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonItemCard()
                    .cardStyle()
                    .loadingCard()
            }
        }
        .accessibilityLabel("Loading inventory items")
    }

    // MARK: - Error State (P2-09-3)
    @ViewBuilder
    private func errorStateView(message: String, retryAction: @escaping () -> Void) -> some View {
        VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: NestoryTheme.Metrics.iconHero))
                .foregroundStyle(NestoryTheme.Colors.error)
                .accessibilityHidden(true)

            Text("Something went wrong")
                .font(NestoryTheme.Typography.title2)

            Text(message)
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)

            Button(action: retryAction) {
                HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(NestoryTheme.Typography.buttonLabel)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, NestoryTheme.Metrics.paddingSmall)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(NestoryTheme.Metrics.paddingLarge)
        .errorCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message). Double tap Try Again button to retry.")
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

    // MARK: - Pull to Refresh (P2-09-3)

    /// Refresh inventory data - provides visual feedback for pull-to-refresh
    /// SwiftData automatically syncs with CloudKit, but this allows manual triggers
    private func refreshInventory() async {
        // Small delay to show refresh indicator
        try? await Task.sleep(for: .milliseconds(500))

        // SwiftData @Query automatically updates when model changes
        // In future, this could trigger CloudKit sync or remote refresh
        NestoryTheme.Haptics.success()
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

// MARK: - Search Help Sheet (Task 10.2.2)
struct SearchHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enhanced Search")
                            .font(.headline)

                        Text("Use special filters to narrow down your search results. Combine filters with regular text to find exactly what you need.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Location Filters") {
                    SearchHelpRow(syntax: "room:Kitchen", description: "Items in a specific room")
                    SearchHelpRow(syntax: "room:\"Living Room\"", description: "Use quotes for multi-word rooms")
                    SearchHelpRow(syntax: "category:Electronics", description: "Items in a category")
                    SearchHelpRow(syntax: "cat:Tools", description: "Shorthand for category")
                }

                Section("Value Filters") {
                    SearchHelpRow(syntax: "value>1000", description: "Items worth more than $1,000")
                    SearchHelpRow(syntax: "value<500", description: "Items worth less than $500")
                    SearchHelpRow(syntax: "value:500-1000", description: "Items between $500-$1,000")
                }

                Section("Documentation Filters") {
                    SearchHelpRow(syntax: "has:photo", description: "Items with photos")
                    SearchHelpRow(syntax: "no:photo", description: "Items without photos")
                    SearchHelpRow(syntax: "has:receipt", description: "Items with receipts")
                    SearchHelpRow(syntax: "no:receipt", description: "Items without receipts")
                }

                Section("Other Filters") {
                    SearchHelpRow(syntax: "tag:insured", description: "Items with a specific tag")
                }

                Section("Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("room:Kitchen value>100")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.blue)
                        Text("Kitchen items worth over $100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("cat:Electronics no:photo")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.blue)
                        Text("Electronics without photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Samsung room:Office")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.blue)
                        Text("Samsung items in Office")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Search Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct SearchHelpRow: View {
    let syntax: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(syntax)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.blue)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    InventoryTab()
        .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
        .environment(AppEnvironment())
}

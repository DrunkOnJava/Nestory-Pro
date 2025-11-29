//
//  InventoryTabViewModel.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import SwiftUI
import SwiftData
import Observation

/// ViewModel for InventoryTab that handles filtering, sorting, and statistics
/// calculation. Follows MVVM pattern with proper dependency injection.
@MainActor
@Observable
final class InventoryTabViewModel {
    
    // MARK: - Published State
    
    var searchText: String = ""
    var selectedFilter: ItemFilter = .all
    var selectedSort: ItemSort = .newest
    var viewMode: ViewMode {
        get { ViewMode(rawValue: settings.inventoryViewMode) ?? .list }
        set { settings.inventoryViewMode = newValue.rawValue }
    }
    var showingAddItem: Bool = false
    var showingDocumentationInfo: Bool = false
    var showingProPaywall: Bool = false
    var itemLimitBannerDismissed: Bool = false
    
    // MARK: - Dependencies
    
    private let settings: SettingsManager
    
    // MARK: - Initialization
    
    init(settings: SettingsManager) {
        self.settings = settings
    }
    
    // MARK: - Filtering & Sorting

    /// Apply search, filter, and sort to items array.
    /// Note: Some filters use SwiftData predicates (applied at query level),
    /// while others (relationship counts) must use Swift filtering here.
    func processItems(_ items: [Item]) -> [Item] {
        var result = items

        // Apply search (must be done in Swift due to multiple field OR logic)
        if !searchText.isEmpty {
            result = result.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.category?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.room?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply filter (only needed if SwiftData predicate wasn't available)
        // For needsPhoto and needsReceipt, we must filter in Swift
        if selectedFilter.swiftDataPredicate == nil && selectedFilter != .all {
            result = result.filter(selectedFilter.swiftPredicate)
        }

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
    
    // MARK: - Statistics Calculation
    
    /// Calculate total value of all items
    func calculateTotalValue(_ items: [Item]) -> Decimal {
        items.compactMap(\.purchasePrice).reduce(0, +)
    }
    
    /// Count documented items
    func calculateDocumentedCount(_ items: [Item]) -> Int {
        items.filter(\.isDocumented).count
    }
    
    /// Calculate documentation score percentage (0-100)
    func calculateDocumentationScore(_ items: [Item]) -> Int {
        guard !items.isEmpty else { return 0 }
        let documentedCount = calculateDocumentedCount(items)
        return Int((Double(documentedCount) / Double(items.count)) * 100)
    }
    
    /// Count unique rooms
    func calculateUniqueRoomCount(_ items: [Item]) -> Int {
        Set(items.compactMap(\.room?.id)).count
    }
    
    // MARK: - Item Limit Logic
    
    /// Determine if item limit warning should be shown
    func shouldShowItemLimitWarning(itemCount: Int) -> Bool {
        !settings.isProUnlocked && itemCount >= 80 && !itemLimitBannerDismissed
    }
    
    /// Calculate item limit warning level
    func itemLimitWarningLevel(itemCount: Int) -> ItemLimitWarningLevel {
        if itemCount >= 100 {
            return .limitReached
        } else if itemCount >= 80 {
            return .approaching
        } else {
            return .none
        }
    }
    
    // MARK: - Actions
    
    /// Dismiss item limit warning banner
    func dismissItemLimitWarning() {
        itemLimitBannerDismissed = true
    }
    
    /// Show add item sheet
    func addItem() {
        showingAddItem = true
    }
    
    /// Show documentation info sheet
    func showDocumentationInfo() {
        showingDocumentationInfo = true
    }
    
    /// Show Pro paywall
    func showProPaywall() {
        showingProPaywall = true
    }
}

// MARK: - Supporting Enums (kept with ViewModel for cohesion)

enum ItemLimitWarningLevel {
    case none
    case approaching
    case limitReached
}

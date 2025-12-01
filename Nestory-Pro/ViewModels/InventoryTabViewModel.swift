//
//  InventoryTabViewModel.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import SwiftUI
import SwiftData
import Observation

// MARK: - Enhanced Search Syntax Parser (Task 10.2.2)

/// Parses enhanced search syntax like `room:Kitchen`, `category:Electronics`, `value>1000`
struct SearchQuery {
    let plainText: String
    let roomFilter: String?
    let categoryFilter: String?
    let valueFilter: ValueFilter?
    let tagFilter: String?
    let hasPhoto: Bool?
    let hasReceipt: Bool?

    enum ValueFilter {
        case greaterThan(Decimal)
        case lessThan(Decimal)
        case equalTo(Decimal)
        case between(Decimal, Decimal)
    }

    /// Parses search text into structured query
    /// Syntax examples:
    /// - `room:Kitchen` - Filter by room name
    /// - `category:Electronics` - Filter by category name
    /// - `value>1000` - Items with value > $1000
    /// - `value<500` - Items with value < $500
    /// - `value:500-1000` - Items with value between $500-$1000
    /// - `tag:insured` - Filter by tag
    /// - `has:photo` - Items with photos
    /// - `has:receipt` - Items with receipts
    /// - Regular text searches across name, brand, notes
    static func parse(_ searchText: String) -> SearchQuery {
        var plainTextParts: [String] = []
        var roomFilter: String?
        var categoryFilter: String?
        var valueFilter: ValueFilter?
        var tagFilter: String?
        var hasPhoto: Bool?
        var hasReceipt: Bool?

        // Split by spaces, handling quoted strings
        let tokens = tokenize(searchText)

        for token in tokens {
            let lowercased = token.lowercased()

            // Room filter: room:Kitchen or room:"Living Room"
            if lowercased.hasPrefix("room:") {
                let value = String(token.dropFirst(5)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                if !value.isEmpty {
                    roomFilter = value
                }
            }
            // Category filter: category:Electronics or cat:Electronics
            else if lowercased.hasPrefix("category:") || lowercased.hasPrefix("cat:") {
                let prefixLength = lowercased.hasPrefix("category:") ? 9 : 4
                let value = String(token.dropFirst(prefixLength)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                if !value.isEmpty {
                    categoryFilter = value
                }
            }
            // Value filters: value>1000, value<500, value:500-1000
            else if lowercased.hasPrefix("value>") {
                if let amount = Decimal(string: String(token.dropFirst(6))) {
                    valueFilter = .greaterThan(amount)
                }
            }
            else if lowercased.hasPrefix("value<") {
                if let amount = Decimal(string: String(token.dropFirst(6))) {
                    valueFilter = .lessThan(amount)
                }
            }
            else if lowercased.hasPrefix("value=") {
                if let amount = Decimal(string: String(token.dropFirst(6))) {
                    valueFilter = .equalTo(amount)
                }
            }
            else if lowercased.hasPrefix("value:") {
                let rangeStr = String(token.dropFirst(6))
                if rangeStr.contains("-") {
                    let parts = rangeStr.split(separator: "-")
                    if parts.count == 2,
                       let min = Decimal(string: String(parts[0])),
                       let max = Decimal(string: String(parts[1])) {
                        valueFilter = .between(min, max)
                    }
                }
            }
            // Tag filter: tag:insured
            else if lowercased.hasPrefix("tag:") {
                let value = String(token.dropFirst(4)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                if !value.isEmpty {
                    tagFilter = value
                }
            }
            // Has filters: has:photo, has:receipt
            else if lowercased.hasPrefix("has:") {
                let value = String(token.dropFirst(4)).lowercased()
                switch value {
                case "photo", "photos":
                    hasPhoto = true
                case "receipt", "receipts":
                    hasReceipt = true
                case "nophoto":
                    hasPhoto = false
                case "noreceipt":
                    hasReceipt = false
                default:
                    break
                }
            }
            // No filter: no:photo, no:receipt
            else if lowercased.hasPrefix("no:") {
                let value = String(token.dropFirst(3)).lowercased()
                switch value {
                case "photo", "photos":
                    hasPhoto = false
                case "receipt", "receipts":
                    hasReceipt = false
                default:
                    break
                }
            }
            // Plain text (not a filter)
            else {
                plainTextParts.append(token)
            }
        }

        return SearchQuery(
            plainText: plainTextParts.joined(separator: " "),
            roomFilter: roomFilter,
            categoryFilter: categoryFilter,
            valueFilter: valueFilter,
            tagFilter: tagFilter,
            hasPhoto: hasPhoto,
            hasReceipt: hasReceipt
        )
    }

    /// Tokenizes search string, respecting quoted strings
    private static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuotes = false

        for char in text {
            if char == "\"" {
                inQuotes.toggle()
                current.append(char)
            } else if char == " " && !inQuotes {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }

    /// Returns true if this query uses any enhanced syntax
    var usesEnhancedSyntax: Bool {
        roomFilter != nil || categoryFilter != nil || valueFilter != nil ||
        tagFilter != nil || hasPhoto != nil || hasReceipt != nil
    }
}

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
    var showingSearchHelp: Bool = false
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
    ///
    /// Enhanced Search Syntax (Task 10.2.2):
    /// - `room:Kitchen` - Filter by room name
    /// - `category:Electronics` - Filter by category name
    /// - `value>1000` - Items with value > $1000
    /// - `value<500` - Items with value < $500
    /// - `value:500-1000` - Items with value between $500-$1000
    /// - `tag:insured` - Filter by tag
    /// - `has:photo` - Items with photos
    /// - `has:receipt` - Items with receipts
    /// - `no:photo` - Items without photos
    /// - `no:receipt` - Items without receipts
    func processItems(_ items: [Item]) -> [Item] {
        var result = items

        // Apply enhanced search syntax
        if !searchText.isEmpty {
            let query = SearchQuery.parse(searchText)
            result = applySearchQuery(query, to: result)
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

    /// Applies parsed search query to items
    private func applySearchQuery(_ query: SearchQuery, to items: [Item]) -> [Item] {
        var result = items

        // Apply room filter
        if let roomFilter = query.roomFilter {
            result = result.filter { item in
                item.room?.name.localizedCaseInsensitiveContains(roomFilter) ?? false
            }
        }

        // Apply category filter
        if let categoryFilter = query.categoryFilter {
            result = result.filter { item in
                item.category?.name.localizedCaseInsensitiveContains(categoryFilter) ?? false
            }
        }

        // Apply value filter
        if let valueFilter = query.valueFilter {
            result = result.filter { item in
                guard let price = item.purchasePrice else { return false }
                switch valueFilter {
                case .greaterThan(let amount):
                    return price > amount
                case .lessThan(let amount):
                    return price < amount
                case .equalTo(let amount):
                    return price == amount
                case .between(let min, let max):
                    return price >= min && price <= max
                }
            }
        }

        // Apply tag filter
        if let tagFilter = query.tagFilter {
            result = result.filter { item in
                item.tags.contains { $0.localizedCaseInsensitiveContains(tagFilter) }
            }
        }

        // Apply has:photo / no:photo filter
        if let hasPhoto = query.hasPhoto {
            result = result.filter { item in
                hasPhoto ? !item.photos.isEmpty : item.photos.isEmpty
            }
        }

        // Apply has:receipt / no:receipt filter
        if let hasReceipt = query.hasReceipt {
            result = result.filter { item in
                hasReceipt ? !item.receipts.isEmpty : item.receipts.isEmpty
            }
        }

        // Apply plain text search (across name, brand, notes, category, room)
        if !query.plainText.isEmpty {
            result = result.filter { item in
                item.name.localizedCaseInsensitiveContains(query.plainText) ||
                (item.brand?.localizedCaseInsensitiveContains(query.plainText) ?? false) ||
                (item.notes?.localizedCaseInsensitiveContains(query.plainText) ?? false) ||
                (item.category?.name.localizedCaseInsensitiveContains(query.plainText) ?? false) ||
                (item.room?.name.localizedCaseInsensitiveContains(query.plainText) ?? false)
            }
        }

        return result
    }

    /// Shows the search help sheet
    func showSearchHelp() {
        showingSearchHelp = true
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

// MARK: - Presentation Models (P2-07)

/// Represents a section in the inventory list for grouped display
enum InventorySection: Hashable, Identifiable {
    case all
    case room(String)
    case category(String)
    case container(String)
    case uncategorized

    var id: String {
        switch self {
        case .all: return "all"
        case .room(let name): return "room-\(name)"
        case .category(let name): return "category-\(name)"
        case .container(let name): return "container-\(name)"
        case .uncategorized: return "uncategorized"
        }
    }

    var displayName: String {
        switch self {
        case .all: return "All Items"
        case .room(let name): return name
        case .category(let name): return name
        case .container(let name): return name
        case .uncategorized: return "Uncategorized"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "archivebox.fill"
        case .room: return "door.left.hand.closed"
        case .category: return "folder.fill"
        case .container: return "shippingbox.fill"
        case .uncategorized: return "questionmark.folder.fill"
        }
    }
}

/// Metadata about which parts of an item matched a search query
struct SearchMatchMetadata: Equatable {
    let matchedName: Bool
    let matchedBrand: Bool
    let matchedNotes: Bool
    let matchedCategory: Bool
    let matchedRoom: Bool
    let matchedTags: Bool

    /// Returns a summary of where matches were found
    var matchSummary: String {
        var matches: [String] = []
        if matchedName { matches.append("name") }
        if matchedBrand { matches.append("brand") }
        if matchedNotes { matches.append("notes") }
        if matchedCategory { matches.append("category") }
        if matchedRoom { matches.append("room") }
        if matchedTags { matches.append("tags") }
        return matches.joined(separator: ", ")
    }

    /// Returns true if any field matched
    var hasMatch: Bool {
        matchedName || matchedBrand || matchedNotes || matchedCategory || matchedRoom || matchedTags
    }

    static let noMatch = SearchMatchMetadata(
        matchedName: false,
        matchedBrand: false,
        matchedNotes: false,
        matchedCategory: false,
        matchedRoom: false,
        matchedTags: false
    )
}

/// Display model for item limit warning banner
struct ItemLimitWarningDisplay {
    let level: ItemLimitWarningLevel
    let currentCount: Int
    let maxCount: Int

    var title: String {
        switch level {
        case .none:
            return ""
        case .approaching:
            return "Approaching Item Limit"
        case .limitReached:
            return "Item Limit Reached"
        }
    }

    var message: String {
        switch level {
        case .none:
            return ""
        case .approaching:
            return "You have \(currentCount) of \(maxCount) items. Upgrade to Pro for unlimited items."
        case .limitReached:
            return "Free tier limit of \(maxCount) items reached. Upgrade to Pro to add more."
        }
    }

    var iconName: String {
        switch level {
        case .none: return ""
        case .approaching: return "exclamationmark.triangle.fill"
        case .limitReached: return "xmark.circle.fill"
        }
    }

    var tintColor: String {
        switch level {
        case .none: return "clear"
        case .approaching: return "orange"
        case .limitReached: return "red"
        }
    }

    var shouldShow: Bool {
        level != .none
    }
}

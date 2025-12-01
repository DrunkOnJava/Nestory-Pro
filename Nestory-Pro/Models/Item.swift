//
//  Item.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: CORE MODEL - READ BEFORE MODIFYING
// ============================================================================
// This is the central data model. Changes here affect the entire app.
//
// COMPLETED MODEL UPDATES (TODO.md Phase 1):
// - Task 1.1.1: Added `notes: String?` property (distinct from conditionNotes) ✓
// - Task P2-02: Added `container: Container?` optional relationship ✓
//
// DOCUMENTATION SCORE (Lines ~195-215):
// - Task 1.4.1 DECIDED: 6-field weighted scoring (2025-11-28)
// - Photo: 30%, Value: 25%, Room: 15%, Category: 10%, Receipt: 10%, Serial: 10%
// - Total: 100% when all fields present
// - isDocumented: requires 4 core fields (Photo, Value, Room, Category)
//
// HIERARCHY (P2-02): Property → Room → Container → Item
//
// TESTING REQUIREMENTS:
// - All changes must update TestFixtures.swift
// - All changes must have corresponding ItemTests.swift updates
// - Run: xcodebuild test -only-testing:Nestory-ProTests/ItemTests
//
// RELATIONSHIP RULES (DO NOT CHANGE):
// - photos: cascade delete (delete item = delete photos)
// - receipts: nullify (delete item = unlink receipts, keep them)
// - container: nullify (delete container = unlink item, keep it in room)
// - category/room: optional (items can exist without)
//
// SEE: TODO.md Phase 1 | TestFixtures.swift | ItemTests.swift
// ============================================================================

import Foundation
import SwiftData

/// Condition scale for items
enum ItemCondition: String, Codable, CaseIterable, Sendable {
    case new = "New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var displayName: String {
        switch self {
        case .new:
            return String(localized: "New", comment: "Item condition: brand new")
        case .likeNew:
            return String(localized: "Like New", comment: "Item condition: barely used")
        case .good:
            return String(localized: "Good", comment: "Item condition: good quality")
        case .fair:
            return String(localized: "Fair", comment: "Item condition: fair quality")
        case .poor:
            return String(localized: "Poor", comment: "Item condition: poor quality")
        }
    }
}

@Model
final class Item {
    var id: UUID
    var name: String
    var brand: String?
    var modelNumber: String?
    var serialNumber: String?
    
    var purchasePrice: Decimal?
    var purchaseDate: Date?
    var currencyCode: String
    
    @Relationship(inverse: \Category.items)
    var category: Category?
    
    @Relationship(inverse: \Room.items)
    var room: Room?
    
    var condition: ItemCondition
    var conditionNotes: String?

    /// General notes about the item (distinct from conditionNotes which describes physical state)
    // NOTE: Task 1.1.1 - Added for user documentation of item details, warranty info, etc.
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.item)
    var photos: [ItemPhoto]
    
    @Relationship(deleteRule: .nullify, inverse: \Receipt.linkedItem)
    var receipts: [Receipt]
    
    var warrantyExpiryDate: Date?
    
    /// Legacy string-based tags (kept for backward compatibility)
    var tags: [String]
    
    /// Tag objects relationship (P2-05: Tags & quick categorization)
    @Relationship(deleteRule: .nullify)
    var tagObjects: [Tag]
    
    /// Product barcode (UPC, EAN, etc.) scanned from the item
    // NOTE: Task 2.7.2 - Stored for future product lookup (v1.1+)
    var barcode: String?

    // MARK: - Market Value Lookup (F4)

    /// Estimated replacement value from market lookup
    var estimatedReplacementValue: Decimal?

    /// Low end of estimated price range
    var estimatedValueLow: Decimal?

    /// High end of estimated price range
    var estimatedValueHigh: Decimal?

    /// Source of the value estimate (e.g., "eBay", "Amazon")
    var valueLookupSource: String?

    /// When the value was last checked
    var valueLookupDate: Date?

    /// Optional container within a room (P2-02: Information architecture)
    /// e.g., "TV Stand", "Dresser", "Storage Bin"
    @Relationship(inverse: \Container.items)
    var container: Container?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        brand: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        purchasePrice: Decimal? = nil,
        purchaseDate: Date? = nil,
        currencyCode: String = "USD",
        category: Category? = nil,
        room: Room? = nil,
        condition: ItemCondition = .good,
        conditionNotes: String? = nil,
        notes: String? = nil,
        warrantyExpiryDate: Date? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.currencyCode = currencyCode
        self.category = category
        self.room = room
        self.condition = condition
        self.conditionNotes = conditionNotes
        self.notes = notes
        self.photos = []
        self.receipts = []
        self.tagObjects = []
        self.warrantyExpiryDate = warrantyExpiryDate
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Validation
extension Item {
    enum ValidationError: LocalizedError, Sendable {
        case emptyName
        case negativePurchasePrice
        case invalidCurrencyCode

        var errorDescription: String? {
            switch self {
            case .emptyName:
                return String(localized: "Item name cannot be empty", comment: "Validation error: item name is empty")
            case .negativePurchasePrice:
                return String(localized: "Purchase price must be positive", comment: "Validation error: negative price")
            case .invalidCurrencyCode:
                return String(localized: "Invalid currency code", comment: "Validation error: currency code format is invalid")
            }
        }
    }

    /// Validates the item's data integrity
    func validate() throws {
        // Name must not be empty
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyName
        }

        // Purchase price must be positive if set
        if let price = purchasePrice, price < 0 {
            throw ValidationError.negativePurchasePrice
        }

        // Currency code must be 3 uppercase letters (ISO 4217)
        let currencyPattern = "^[A-Z]{3}$"
        if currencyCode.range(of: currencyPattern, options: .regularExpression) == nil {
            throw ValidationError.invalidCurrencyCode
        }
    }
}

// MARK: - Documentation Status
extension Item {
    var hasPhoto: Bool { !photos.isEmpty }
    var hasReceipt: Bool { !receipts.isEmpty }
    var hasValue: Bool { purchasePrice != nil }
    var hasSerial: Bool { serialNumber != nil && !serialNumber!.isEmpty }
    var hasLocation: Bool { room != nil }
    var hasCategory: Bool { category != nil }

    /// Item is "documented" if it has photo, value, category, and room
    var isDocumented: Bool {
        hasPhoto && hasValue && hasCategory && hasLocation
    }

    /// Documentation score using 6-field weighted calculation (Task 1.4.1)
    /// Weights: Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%
    var documentationScore: Double {
        var score = 0.0
        if hasPhoto { score += 0.30 }
        if hasValue { score += 0.25 }
        if hasLocation { score += 0.15 }
        if hasCategory { score += 0.10 }
        if hasReceipt { score += 0.10 }
        if hasSerial { score += 0.10 }
        return score
    }

    /// Returns documentation fields missing for insurance purposes.
    /// Aligned with `documentationScore` 6-field calculation (Task 1.4.3)
    /// Order matches weight priority: Photo, Value, Room, Category, Receipt, Serial
    var missingDocumentation: [String] {
        var missing: [String] = []
        if !hasPhoto { missing.append("Photo") }
        if !hasValue { missing.append("Value") }
        if !hasLocation { missing.append("Room") }
        if !hasCategory { missing.append("Category") }
        if !hasReceipt { missing.append("Receipt") }
        if !hasSerial { missing.append("Serial Number") }
        return missing
    }
    
    // MARK: - Market Value Status (F4)

    /// Whether the item has a recent market value estimate (within 30 days)
    var hasRecentValueEstimate: Bool {
        guard let lookupDate = valueLookupDate else { return false }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return lookupDate > thirtyDaysAgo
    }

    /// How many days since the value was last checked
    var daysSinceValueLookup: Int? {
        guard let lookupDate = valueLookupDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lookupDate, to: Date()).day
    }

    /// Full breadcrumb path for navigation (P2-02)
    /// Format: "Property > Room > Container > Item" (omitting nil levels)
    var breadcrumbPath: String {
        var components: [String] = []
        if let property = room?.property {
            components.append(property.name)
        }
        if let room = room {
            components.append(room.name)
        }
        if let container = container {
            components.append(container.name)
        }
        components.append(name)
        return components.joined(separator: " > ")
    }
}

// MARK: - Optimized Fetch Descriptors
extension Item {
    /// Optimized fetch descriptor for list views with prefetched relationships
    /// Loads category, room, and photos in a single query to avoid N+1 performance issues
    static var optimizedListFetch: FetchDescriptor<Item> {
        var descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        // Prefetch relationships to avoid lazy loading
        descriptor.relationshipKeyPathsForPrefetching = [
            \Item.category,
            \Item.room,
            \Item.photos
        ]

        return descriptor
    }

    /// Optimized fetch descriptor for detail views with all relationships prefetched
    /// Includes receipts in addition to basic relationships
    static var optimizedDetailFetch: FetchDescriptor<Item> {
        var descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        // Prefetch all relationships for detail view
        descriptor.relationshipKeyPathsForPrefetching = [
            \Item.category,
            \Item.room,
            \Item.photos,
            \Item.receipts
        ]

        return descriptor
    }

    /// Creates a fetch descriptor with custom sorting and relationship prefetching
    static func fetchDescriptor(
        sortBy: [SortDescriptor<Item>] = [SortDescriptor(\.updatedAt, order: .reverse)],
        predicate: Predicate<Item>? = nil,
        prefetchRelationships: Bool = true
    ) -> FetchDescriptor<Item> {
        var descriptor = FetchDescriptor<Item>(
            predicate: predicate,
            sortBy: sortBy
        )

        if prefetchRelationships {
            descriptor.relationshipKeyPathsForPrefetching = [
                \Item.category,
                \Item.room,
                \Item.photos
            ]
        }

        return descriptor
    }
}

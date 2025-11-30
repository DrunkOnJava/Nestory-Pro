//
//  Tag.swift
//  Nestory-Pro
//
//  Created for v1.2 - P2-05
//

// ============================================================================
// TAG MODEL - Task P2-05: Tags & quick categorization
// ============================================================================
// Flexible tagging system for items with predefined favorites and custom tags.
//
// RELATIONSHIP RULES:
// - Tag ↔ Item: many-to-many (items can have multiple tags, tags apply to many items)
// - Delete rule: nullify (deleting a tag removes it from items, items remain)
//
// PREDEFINED TAGS (favorites):
// - Essential, High Value, Electronics, Insurance-Critical
// - Users can create custom tags as needed
//
// SEE: TODO.md P2-05 | Item.swift | TagPillView.swift
// ============================================================================

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var isFavorite: Bool
    var createdAt: Date
    
    @Relationship(inverse: \Item.tagObjects)
    var items: [Item]
    
    init(
        name: String,
        colorHex: String = "#007AFF",
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.items = []
    }
}

// MARK: - Tag Color

extension Tag {
    /// Predefined tag colors for quick selection
    static let predefinedColors: [String] = [
        "#007AFF", // Blue (default)
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#AF52DE", // Purple
        "#5856D6", // Indigo
        "#00C7BE", // Teal
        "#FF2D55", // Pink
        "#8E8E93"  // Gray
    ]
}

// MARK: - Predefined Tags

extension Tag {
    /// Default favorite tags for new users
    static let defaultFavorites: [(name: String, colorHex: String)] = [
        ("Essential", "#34C759"),      // Green
        ("High Value", "#FF9500"),     // Orange
        ("Electronics", "#007AFF"),    // Blue
        ("Insurance-Critical", "#FF3B30") // Red
    ]
    
    /// Creates default favorite tags for a new user
    @MainActor
    static func createDefaultTags(in context: ModelContext) {
        for favorite in defaultFavorites {
            let tag = Tag(
                name: favorite.name,
                colorHex: favorite.colorHex,
                isFavorite: true
            )
            context.insert(tag)
        }
    }
}

// MARK: - Validation

extension Tag {
    enum ValidationError: LocalizedError, Sendable {
        case emptyName
        case duplicateName
        case invalidColorHex
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return String(localized: "Tag name cannot be empty", comment: "Validation error: tag name is empty")
            case .duplicateName:
                return String(localized: "A tag with this name already exists", comment: "Validation error: duplicate tag name")
            case .invalidColorHex:
                return String(localized: "Invalid color format", comment: "Validation error: color hex format is invalid")
            }
        }
    }
    
    /// Validates the tag's data integrity
    func validate() throws {
        // Name must not be empty
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyName
        }
        
        // Color hex must be valid format (#RRGGBB)
        let colorPattern = "^#[0-9A-Fa-f]{6}$"
        if colorHex.range(of: colorPattern, options: .regularExpression) == nil {
            throw ValidationError.invalidColorHex
        }
    }
}

// MARK: - Fetch Descriptors

extension Tag {
    /// Fetch all tags sorted by name
    static var allTagsFetch: FetchDescriptor<Tag> {
        FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
    }
    
    /// Fetch favorite tags only
    static var favoriteTagsFetch: FetchDescriptor<Tag> {
        var descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\Tag.items]
        return descriptor
    }
    
    /// Fetch tags for a specific item
    static func tagsForItem(_ itemId: UUID) -> FetchDescriptor<Tag> {
        FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.items.contains { $0.id == itemId }
            },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
    }
}

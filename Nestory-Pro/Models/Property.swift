//
//  Property.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// CLAUDE CODE AGENT: PROPERTY MODEL (P2-02)
// ============================================================================
// Task P2-02: Information architecture - Spaces, rooms, containers
//
// HIERARCHY:
// Property → Room → Container → Item
//
// RELATIONSHIP RULES:
// - rooms: cascade delete (delete property = delete rooms)
// - When property is deleted, all rooms and their items are deleted
//
// SEE: TODO.md P2-02 | Room.swift | Container.swift
// ============================================================================

import Foundation
import SwiftData

/// Represents a physical property/space (e.g., "Main House", "Vacation Home", "Storage Unit")
/// This is the top level of the inventory hierarchy.
@Model
final class Property {
    var id: UUID
    var name: String
    var address: String?
    var iconName: String
    var colorHex: String
    var sortOrder: Int
    
    /// Whether this is the default/primary property
    var isDefault: Bool
    
    /// Notes about the property (e.g., insurance policy number, contact info)
    var notes: String?
    
    @Relationship(deleteRule: .cascade)
    var rooms: [Room]
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        address: String? = nil,
        iconName: String = "house.fill",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        isDefault: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.notes = notes
        self.rooms = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Validation
extension Property {
    enum ValidationError: LocalizedError, Sendable {
        case emptyName
        case invalidColorHex
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return String(localized: "Property name cannot be empty", comment: "Validation error: property name is empty")
            case .invalidColorHex:
                return String(localized: "Invalid color format", comment: "Validation error: color hex format is invalid")
            }
        }
    }
    
    /// Validates the property's data integrity
    func validate() throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyName
        }
        
        // Color hex must be valid format (#RRGGBB or #RGB)
        let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        if colorHex.range(of: hexPattern, options: .regularExpression) == nil {
            throw ValidationError.invalidColorHex
        }
    }
}

// MARK: - Computed Properties
extension Property {
    /// Total number of items across all rooms in this property
    var totalItemCount: Int {
        rooms.reduce(0) { $0 + $1.items.count }
    }
    
    /// Total value of all items in this property
    var totalValue: Decimal {
        rooms.reduce(Decimal(0)) { propertyTotal, room in
            propertyTotal + room.items.reduce(Decimal(0)) { roomTotal, item in
                roomTotal + (item.purchasePrice ?? 0)
            }
        }
    }
    
    /// Average documentation score across all items
    var averageDocumentationScore: Double {
        let allItems = rooms.flatMap { $0.items }
        guard !allItems.isEmpty else { return 0 }
        let totalScore = allItems.reduce(0.0) { $0 + $1.documentationScore }
        return totalScore / Double(allItems.count)
    }
}

// MARK: - Default Properties
extension Property {
    /// Creates a default "My Home" property for new users
    static func createDefault(in context: ModelContext) -> Property {
        let property = Property(
            name: "My Home",
            iconName: "house.fill",
            colorHex: "#007AFF",
            sortOrder: 0,
            isDefault: true
        )
        context.insert(property)
        return property
    }
    
    /// Preset property icons for UI selection
    static let availableIcons: [String] = [
        "house.fill",
        "building.2.fill",
        "building.fill",
        "house.lodge.fill",
        "tent.fill",
        "shippingbox.fill",
        "car.garage.fill",
        "beach.umbrella.fill"
    ]
    
    /// Preset colors for properties
    static let availableColors: [String] = [
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#AF52DE", // Purple
        "#5856D6", // Indigo
        "#FF2D55", // Pink
        "#00C7BE"  // Teal
    ]
}

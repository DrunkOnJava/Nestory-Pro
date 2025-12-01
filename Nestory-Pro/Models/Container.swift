//
//  Container.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// CLAUDE CODE AGENT: CONTAINER MODEL (P2-02)
// ============================================================================
// Task P2-02: Information architecture - Spaces, rooms, containers
//
// HIERARCHY:
// Property → Room → Container → Item
//
// RELATIONSHIP RULES:
// - items: nullify (delete container = unlink items, keep them in room)
// - room: required parent relationship
//
// USE CASES:
// - Furniture: "TV Stand", "Dresser", "Bookshelf"
// - Storage: "Closet Bin #1", "Garage Shelf A"
// - Appliances: "Refrigerator", "Freezer"
//
// SEE: TODO.md P2-02 | Room.swift | Property.swift
// ============================================================================

import Foundation
import SwiftData

/// Represents a container within a room (e.g., "TV Stand", "Dresser", "Storage Box")
/// Optional level between Room and Item for detailed organization.
@Model
final class Container {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int
    
    /// Notes about the container (e.g., "IKEA KALLAX, purchased 2023")
    var notes: String?
    
    @Relationship(inverse: \Room.containers)
    var room: Room?
    
    @Relationship(deleteRule: .nullify)
    var items: [Item]
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        iconName: String = "shippingbox.fill",
        colorHex: String = "#8B5CF6",
        sortOrder: Int = 0,
        notes: String? = nil,
        room: Room? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.notes = notes
        self.room = room
        self.items = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Validation
extension Container {
    enum ValidationError: LocalizedError, Sendable {
        case emptyName
        case invalidColorHex
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return String(localized: "Container name cannot be empty", comment: "Validation error: container name is empty")
            case .invalidColorHex:
                return String(localized: "Invalid color format", comment: "Validation error: color hex format is invalid")
            }
        }
    }
    
    /// Validates the container's data integrity
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
extension Container {
    /// Total value of items in this container
    var totalValue: Decimal {
        items.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
    }
    
    /// Average documentation score for items in this container
    var averageDocumentationScore: Double {
        guard !items.isEmpty else { return 0 }
        let totalScore = items.reduce(0.0) { $0 + $1.documentationScore }
        return totalScore / Double(items.count)
    }
    
    /// Full path: "Property > Room > Container"
    var breadcrumbPath: String {
        var components: [String] = []
        if let room = room {
            if let property = room.property {
                components.append(property.name)
            }
            components.append(room.name)
        }
        components.append(name)
        return components.joined(separator: " > ")
    }
}

// MARK: - Default Containers
extension Container {
    /// Preset container icons for UI selection
    static let availableIcons: [String] = [
        "shippingbox.fill",
        "cabinet.fill",
        "tray.2.fill",
        "archivebox.fill",
        "bag.fill",
        "suitcase.fill",
        "tshirt.fill",
        "rectangle.3.group.fill"
    ]
    
    /// Preset colors for containers
    static let availableColors: [String] = [
        "#8B5CF6", // Purple (default)
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#5856D6", // Indigo
        "#FF2D55", // Pink
        "#64748B"  // Slate
    ]
    
    /// Common container templates
    static let templates: [(name: String, icon: String)] = [
        ("Dresser", "cabinet.fill"),
        ("TV Stand", "rectangle.3.group.fill"),
        ("Bookshelf", "books.vertical.fill"),
        ("Storage Bin", "shippingbox.fill"),
        ("Closet", "tshirt.fill"),
        ("Desk", "desktopcomputer"),
        ("Nightstand", "lamp.table.fill"),
        ("Cabinet", "cabinet.fill"),
        ("Shelf", "tray.2.fill"),
        ("Toolbox", "wrench.and.screwdriver.fill")
    ]
}

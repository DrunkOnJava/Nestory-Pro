//
//  Room.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftData

// ============================================================================
// CLAUDE CODE AGENT: ROOM MODEL
// ============================================================================
// Task 1.1.3: Added isDefault property for seeded rooms
// - isDefault: prevents deletion of system-provided rooms
//
// Task P2-02: Added property relationship and containers
// - property: optional parent (for backward compatibility)
// - containers: cascade delete (delete room = delete containers)
//
// HIERARCHY: Property → Room → Container → Item
//
// SEE: TODO.md Phase 1 | TODO.md P2-02 | TestFixtures.swift
// ============================================================================

@Model
final class Room {
    var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int

    /// Whether this is a default/system-provided room (cannot be deleted)
    // NOTE: Task 1.1.3 - Seeded rooms should have isDefault = true
    var isDefault: Bool
    
    /// Parent property (P2-02: Information architecture)
    /// Optional for backward compatibility with existing data
    @Relationship(inverse: \Property.rooms)
    var property: Property?
    
    /// Containers within this room (P2-02)
    @Relationship(deleteRule: .cascade)
    var containers: [Container]

    @Relationship
    var items: [Item]

    init(
        name: String,
        iconName: String = "door.left.hand.closed",
        sortOrder: Int = 0,
        isDefault: Bool = false,
        property: Property? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.property = property
        self.containers = []
        self.items = []
    }
}

// MARK: - Default Rooms
extension Room {
    static let defaultRooms: [(name: String, icon: String)] = [
        ("Living Room", "sofa.fill"),
        ("Kitchen", "refrigerator.fill"),
        ("Bedroom", "bed.double.fill"),
        ("Bathroom", "shower.fill"),
        ("Office", "desktopcomputer"),
        ("Garage", "car.fill"),
        ("Basement", "stairs"),
        ("Attic", "house.fill"),
        ("Dining Room", "fork.knife"),
        ("Closet", "tshirt.fill"),
        ("Outdoor", "tree.fill"),
        ("Other", "questionmark.folder.fill")
    ]
    
    /// Creates default rooms for a property (P2-02)
    static func createDefaultRooms(in context: ModelContext, for property: Property) -> [Room] {
        var rooms: [Room] = []
        for (index, roomData) in defaultRooms.enumerated() {
            let room = Room(
                name: roomData.name,
                iconName: roomData.icon,
                sortOrder: index,
                isDefault: true,
                property: property
            )
            context.insert(room)
            rooms.append(room)
        }
        return rooms
    }
}

// MARK: - Computed Properties (P2-02)
extension Room {
    /// Total value of items in this room
    var totalValue: Decimal {
        items.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
    }
    
    /// Average documentation score for items in this room
    var averageDocumentationScore: Double {
        guard !items.isEmpty else { return 0 }
        let totalScore = items.reduce(0.0) { $0 + $1.documentationScore }
        return totalScore / Double(items.count)
    }
    
    /// Full path: "Property > Room"
    var breadcrumbPath: String {
        var components: [String] = []
        if let property = property {
            components.append(property.name)
        }
        components.append(name)
        return components.joined(separator: " > ")
    }
}

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
// SEE: TODO.md Phase 1 | TestFixtures.swift
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

    @Relationship
    var items: [Item]

    init(
        name: String,
        iconName: String = "door.left.hand.closed",
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isDefault = isDefault
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
}

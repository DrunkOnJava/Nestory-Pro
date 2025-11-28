//
//  Room.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftData

@Model
final class Room {
    var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int
    
    @Relationship
    var items: [Item]
    
    init(name: String, iconName: String = "door.left.hand.closed", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
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

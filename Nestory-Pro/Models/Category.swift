//
//  Category.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var isCustom: Bool
    var sortOrder: Int
    
    @Relationship
    var items: [Item]
    
    init(
        name: String,
        iconName: String = "folder.fill",
        colorHex: String = "#007AFF",
        isCustom: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isCustom = isCustom
        self.sortOrder = sortOrder
        self.items = []
    }
}

// MARK: - Default Categories
extension Category {
    static let defaultCategories: [(name: String, icon: String, color: String)] = [
        ("Electronics", "desktopcomputer", "#007AFF"),
        ("Furniture", "sofa.fill", "#8B5CF6"),
        ("Appliances", "refrigerator.fill", "#10B981"),
        ("Clothing", "tshirt.fill", "#F59E0B"),
        ("Jewelry", "sparkles", "#EC4899"),
        ("Art & Decor", "photo.artframe", "#6366F1"),
        ("Sports & Outdoor", "sportscourt.fill", "#14B8A6"),
        ("Tools", "wrench.and.screwdriver.fill", "#64748B"),
        ("Musical Instruments", "guitars.fill", "#F97316"),
        ("Books & Media", "books.vertical.fill", "#84CC16"),
        ("Kitchenware", "fork.knife", "#EF4444"),
        ("Collectibles", "star.fill", "#A855F7"),
        ("Other", "questionmark.folder.fill", "#9CA3AF")
    ]
}

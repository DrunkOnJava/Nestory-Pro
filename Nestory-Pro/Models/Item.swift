//
//  Item.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftData

/// Condition scale for items
enum ItemCondition: String, Codable, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    
    var displayName: String { rawValue }
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
    
    @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.item)
    var photos: [ItemPhoto]
    
    @Relationship(deleteRule: .nullify, inverse: \Receipt.linkedItem)
    var receipts: [Receipt]
    
    var warrantyExpiryDate: Date?
    var tags: [String]
    
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
        self.photos = []
        self.receipts = []
        self.warrantyExpiryDate = warrantyExpiryDate
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
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
    
    var documentationScore: Double {
        var score = 0.0
        if hasPhoto { score += 0.25 }
        if hasValue { score += 0.25 }
        if hasCategory { score += 0.25 }
        if hasLocation { score += 0.25 }
        return score
    }
    
    var missingDocumentation: [String] {
        var missing: [String] = []
        if !hasPhoto { missing.append("Photo") }
        if !hasValue { missing.append("Value") }
        if !hasReceipt { missing.append("Receipt") }
        if !hasSerial { missing.append("Serial Number") }
        if !hasLocation { missing.append("Room") }
        if !hasCategory { missing.append("Category") }
        return missing
    }
}

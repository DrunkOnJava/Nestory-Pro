//
//  ItemPhoto.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftData

// ============================================================================
// CLAUDE CODE AGENT: ITEM PHOTO MODEL
// ============================================================================
// Task 1.1.2: Added sortOrder and isPrimary for photo ordering
// - sortOrder: manual ordering within an item's photo collection
// - isPrimary: marks the main display photo for list views
//
// SEE: TODO.md Phase 1 | TestFixtures.swift
// ============================================================================

@Model
final class ItemPhoto {
    var id: UUID
    /// Local filename or asset identifier for the photo
    var imageIdentifier: String
    var createdAt: Date

    /// Manual sort order within item's photos (lower = first)
    // NOTE: Task 1.1.2 - Enables drag-to-reorder in UI
    var sortOrder: Int

    /// Whether this is the primary/cover photo for the item
    // NOTE: Task 1.1.2 - Used for list view thumbnails
    var isPrimary: Bool

    @Relationship
    var item: Item?

    init(
        imageIdentifier: String,
        sortOrder: Int = 0,
        isPrimary: Bool = false
    ) {
        self.id = UUID()
        self.imageIdentifier = imageIdentifier
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.isPrimary = isPrimary
    }
}

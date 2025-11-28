//
//  ItemPhoto.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftData

@Model
final class ItemPhoto {
    var id: UUID
    /// Local filename or asset identifier for the photo
    var imageIdentifier: String
    var createdAt: Date
    
    @Relationship
    var item: Item?
    
    init(imageIdentifier: String) {
        self.id = UUID()
        self.imageIdentifier = imageIdentifier
        self.createdAt = Date()
    }
}

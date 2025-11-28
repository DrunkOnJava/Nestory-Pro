//
//  Receipt.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import SwiftData

@Model
final class Receipt {
    var id: UUID
    var vendor: String?
    var total: Decimal?
    var taxAmount: Decimal?
    var purchaseDate: Date?
    
    /// Local filename or asset identifier for the receipt image
    var imageIdentifier: String
    /// Raw OCR text extracted from receipt
    var rawText: String?
    /// Confidence score from OCR (0.0 - 1.0)
    var confidence: Double
    
    @Relationship
    var linkedItem: Item?
    
    var createdAt: Date
    
    init(
        imageIdentifier: String,
        vendor: String? = nil,
        total: Decimal? = nil,
        taxAmount: Decimal? = nil,
        purchaseDate: Date? = nil,
        rawText: String? = nil,
        confidence: Double = 0.0
    ) {
        self.id = UUID()
        self.imageIdentifier = imageIdentifier
        self.vendor = vendor
        self.total = total
        self.taxAmount = taxAmount
        self.purchaseDate = purchaseDate
        self.rawText = rawText
        self.confidence = confidence
        self.createdAt = Date()
    }
}

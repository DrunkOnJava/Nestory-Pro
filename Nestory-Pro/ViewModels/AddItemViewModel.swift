//
//  AddItemViewModel.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import SwiftUI
import SwiftData
import Observation

/// ViewModel for AddItemView that handles form state, validation, and save logic
/// Follows MVVM pattern with proper dependency injection.
@MainActor
@Observable
final class AddItemViewModel {
    
    // MARK: - Form State
    
    var name: String = ""
    var brand: String = ""
    var modelNumber: String = ""
    var serialNumber: String = ""
    var purchasePrice: String = ""
    var purchaseDate: Date = Date()
    var hasPurchaseDate: Bool = false
    var selectedCategory: Category?
    var selectedRoom: Room?
    var condition: ItemCondition = .good
    var conditionNotes: String = ""
    var warrantyExpiryDate: Date = Date()
    var hasWarranty: Bool = false
    var showingPaywall: Bool = false
    
    // MARK: - Private Dependencies
    
    private let settings: any SettingsProviding
    
    // MARK: - Initialization
    
    init(settings: any SettingsProviding) {
        self.settings = settings
    }
    
    // MARK: - Default Room
    
    /// Set the default room if configured and no room is already selected
    func setDefaultRoom(_ rooms: [Room]) {
        guard selectedRoom == nil,
              let defaultRoomId = settings.defaultRoomId,
              let defaultRoom = rooms.first(where: { $0.id.uuidString == defaultRoomId })
        else { return }
        selectedRoom = defaultRoom
    }
    
    // MARK: - Validation
    
    /// Check if form can be saved (name is not empty)
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Save Logic
    
    /// Save new item with free tier limit checking
    /// - Parameters:
    ///   - modelContext: SwiftData model context
    ///   - itemCount: Current item count for limit checking
    /// - Returns: The created Item if successful, nil if limit reached
    @discardableResult
    func saveItem(modelContext: ModelContext, itemCount: Int) -> Item? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        
        // Task 4.1.1: Enforce 100-item free tier limit
        if itemCount >= settings.maxFreeItems && !settings.isProUnlocked {
            showingPaywall = true
            return nil // Don't save until user upgrades or dismisses
        }
        
        let item = Item(
            name: trimmedName,
            brand: brand.isEmpty ? nil : brand,
            modelNumber: modelNumber.isEmpty ? nil : modelNumber,
            serialNumber: serialNumber.isEmpty ? nil : serialNumber,
            purchasePrice: Decimal(string: purchasePrice),
            purchaseDate: hasPurchaseDate ? purchaseDate : nil,
            currencyCode: settings.preferredCurrencyCode,
            category: selectedCategory,
            room: selectedRoom,
            condition: condition,
            conditionNotes: conditionNotes.isEmpty ? nil : conditionNotes,
            warrantyExpiryDate: hasWarranty ? warrantyExpiryDate : nil
        )
        
        modelContext.insert(item)
        return item
    }
    
    /// Reset form to initial state
    func reset() {
        name = ""
        brand = ""
        modelNumber = ""
        serialNumber = ""
        purchasePrice = ""
        purchaseDate = Date()
        hasPurchaseDate = false
        selectedCategory = nil
        selectedRoom = nil
        condition = .good
        conditionNotes = ""
        warrantyExpiryDate = Date()
        hasWarranty = false
        showingPaywall = false
    }
}

/// ViewModel for EditItemView that handles editing existing items
@MainActor
@Observable
final class EditItemViewModel {
    
    // MARK: - Form State
    
    var name: String
    var brand: String
    var modelNumber: String
    var serialNumber: String
    var purchasePrice: String
    var purchaseDate: Date
    var hasPurchaseDate: Bool
    var selectedCategory: Category?
    var selectedRoom: Room?
    var condition: ItemCondition
    var conditionNotes: String
    var warrantyExpiryDate: Date
    var hasWarranty: Bool
    
    // MARK: - Private State
    
    private let item: Item
    
    // MARK: - Initialization
    
    init(item: Item) {
        self.item = item
        self.name = item.name
        self.brand = item.brand ?? ""
        self.modelNumber = item.modelNumber ?? ""
        self.serialNumber = item.serialNumber ?? ""
        self.purchasePrice = item.purchasePrice.map { "\($0)" } ?? ""
        self.purchaseDate = item.purchaseDate ?? Date()
        self.hasPurchaseDate = item.purchaseDate != nil
        self.selectedCategory = item.category
        self.selectedRoom = item.room
        self.condition = item.condition
        self.conditionNotes = item.conditionNotes ?? ""
        self.warrantyExpiryDate = item.warrantyExpiryDate ?? Date()
        self.hasWarranty = item.warrantyExpiryDate != nil
    }
    
    // MARK: - Validation
    
    /// Check if form can be saved (name is not empty)
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Save Logic
    
    /// Apply changes to the item
    func saveChanges() {
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.brand = brand.isEmpty ? nil : brand
        item.modelNumber = modelNumber.isEmpty ? nil : modelNumber
        item.serialNumber = serialNumber.isEmpty ? nil : serialNumber
        item.purchasePrice = Decimal(string: purchasePrice)
        item.purchaseDate = hasPurchaseDate ? purchaseDate : nil
        item.category = selectedCategory
        item.room = selectedRoom
        item.condition = condition
        item.conditionNotes = conditionNotes.isEmpty ? nil : conditionNotes
        item.warrantyExpiryDate = hasWarranty ? warrantyExpiryDate : nil
        item.updatedAt = Date()
    }
}

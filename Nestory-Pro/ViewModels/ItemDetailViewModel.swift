//
//  ItemDetailViewModel.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import SwiftUI
import SwiftData
import Observation

/// ViewModel for ItemDetailView that handles UI state and actions
/// Follows MVVM pattern with proper dependency injection.
@MainActor
@Observable
final class ItemDetailViewModel {
    
    // MARK: - UI State
    
    var showingEditSheet: Bool = false
    var showingDeleteConfirmation: Bool = false
    var showingAddPhoto: Bool = false
    var showingAddReceipt: Bool = false
    
    // MARK: - Private State
    
    private let item: Item
    
    // MARK: - Initialization
    
    init(item: Item) {
        self.item = item
    }
    
    // MARK: - Actions
    
    /// Show edit sheet
    func showEditSheet() {
        showingEditSheet = true
    }
    
    /// Show delete confirmation dialog
    func showDeleteConfirmation() {
        showingDeleteConfirmation = true
    }
    
    /// Show add photo sheet
    func showAddPhoto() {
        showingAddPhoto = true
    }
    
    /// Show add receipt sheet
    func showAddReceipt() {
        showingAddReceipt = true
    }
    
    /// Delete the item and dismiss the view
    /// - Parameters:
    ///   - modelContext: SwiftData model context
    ///   - dismiss: Dismiss action from environment
    func deleteItem(modelContext: ModelContext, dismiss: DismissAction) {
        modelContext.delete(item)
        dismiss()
    }
    
    /// Copy text to clipboard
    /// - Parameter text: Text to copy
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    // MARK: - Computed Properties
    
    /// Check if warranty is expired
    func isWarrantyExpired(expiryDate: Date?) -> Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate < Date()
    }
    
    /// Get brand and model display text
    func brandModelText(brand: String?, modelNumber: String?) -> String? {
        guard let brand = brand, !brand.isEmpty else { return nil }
        
        if let model = modelNumber, !model.isEmpty {
            return "\(brand) • \(model)"
        } else {
            return brand
        }
    }
}

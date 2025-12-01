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

    /// Generate documentation status display model from item
    func documentationStatus(for item: Item) -> DocumentationStatus {
        DocumentationStatus(
            hasPhoto: !item.photos.isEmpty,
            hasValue: item.purchasePrice != nil,
            hasCategory: item.category != nil,
            hasRoom: item.room != nil,
            hasReceipt: !item.receipts.isEmpty,
            hasSerialNumber: item.serialNumber != nil && !item.serialNumber!.isEmpty
        )
    }
}

// MARK: - Presentation Models (P2-07)

/// Documentation status display model for an item
struct DocumentationStatus: Equatable {
    let hasPhoto: Bool
    let hasValue: Bool
    let hasCategory: Bool
    let hasRoom: Bool
    let hasReceipt: Bool
    let hasSerialNumber: Bool

    /// Core documentation score (0.0 to 1.0) - photo, value, category, room
    var coreScore: Double {
        let fields = [hasPhoto, hasValue, hasCategory, hasRoom]
        let completedCount = fields.filter { $0 }.count
        return Double(completedCount) / Double(fields.count)
    }

    /// Extended documentation score including receipt and serial
    var extendedScore: Double {
        let fields = [hasPhoto, hasValue, hasCategory, hasRoom, hasReceipt, hasSerialNumber]
        let completedCount = fields.filter { $0 }.count
        return Double(completedCount) / Double(fields.count)
    }

    /// Returns true if all core fields are documented
    var isFullyDocumented: Bool {
        hasPhoto && hasValue && hasCategory && hasRoom
    }

    /// Returns list of missing core fields
    var missingCoreFields: [String] {
        var missing: [String] = []
        if !hasPhoto { missing.append("Photo") }
        if !hasValue { missing.append("Value") }
        if !hasCategory { missing.append("Category") }
        if !hasRoom { missing.append("Room") }
        return missing
    }

    /// Returns list of missing optional fields
    var missingOptionalFields: [String] {
        var missing: [String] = []
        if !hasReceipt { missing.append("Receipt") }
        if !hasSerialNumber { missing.append("Serial Number") }
        return missing
    }

    /// Display status level
    var level: DocumentationLevel {
        switch coreScore {
        case 1.0:
            return .complete
        case 0.75..<1.0:
            return .good
        case 0.5..<0.75:
            return .partial
        default:
            return .minimal
        }
    }

    /// Documentation field display items
    var fieldDisplayItems: [DocumentationFieldItem] {
        [
            DocumentationFieldItem(name: "Photo", isComplete: hasPhoto, iconName: "photo.fill"),
            DocumentationFieldItem(name: "Value", isComplete: hasValue, iconName: "dollarsign.circle.fill"),
            DocumentationFieldItem(name: "Category", isComplete: hasCategory, iconName: "folder.fill"),
            DocumentationFieldItem(name: "Room", isComplete: hasRoom, iconName: "door.left.hand.closed"),
            DocumentationFieldItem(name: "Receipt", isComplete: hasReceipt, iconName: "doc.text.fill"),
            DocumentationFieldItem(name: "Serial #", isComplete: hasSerialNumber, iconName: "number")
        ]
    }
}

/// Documentation completeness level
enum DocumentationLevel: String {
    case complete = "Complete"
    case good = "Good"
    case partial = "Partial"
    case minimal = "Minimal"

    var iconName: String {
        switch self {
        case .complete: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .minimal: return "exclamationmark.circle.fill"
        }
    }

    var tintColor: String {
        switch self {
        case .complete: return "green"
        case .good: return "blue"
        case .partial: return "orange"
        case .minimal: return "red"
        }
    }
}

/// Individual documentation field display item
struct DocumentationFieldItem: Identifiable, Equatable {
    let name: String
    let isComplete: Bool
    let iconName: String

    var id: String { name }
}

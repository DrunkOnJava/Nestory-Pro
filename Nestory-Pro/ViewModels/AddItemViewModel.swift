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
    private let reminderService: ReminderService?

    // MARK: - Initialization

    init(settings: any SettingsProviding, reminderService: ReminderService? = nil) {
        self.settings = settings
        self.reminderService = reminderService
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

    /// Get validation state for a specific field (P2-12-1)
    func validationState(for field: AddItemField) -> FieldValidationState {
        switch field {
        case .name:
            if name.isEmpty {
                return .pending
            } else if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .invalid(message: "Name cannot be empty")
            }
            return .valid
        case .purchasePrice:
            if purchasePrice.isEmpty {
                return .valid // Optional field
            }
            if Decimal(string: purchasePrice) == nil {
                return .invalid(message: "Invalid price format")
            }
            return .valid
        case .purchaseDate:
            if hasPurchaseDate && purchaseDate > Date() {
                return .warning(message: "Future date selected")
            }
            return .valid
        case .warranty:
            if hasWarranty && warrantyExpiryDate < Date() {
                return .warning(message: "Warranty may have expired")
            }
            return .valid
        default:
            return .valid
        }
    }

    /// Get all validation errors (P2-12-1)
    var validationErrors: [String] {
        AddItemField.allCases.compactMap { field in
            let state = validationState(for: field)
            if case .invalid(let message) = state {
                return "\(field.displayName): \(message)"
            }
            return nil
        }
    }

    /// Get all form sections (P2-12-1)
    var formSections: [AddItemSection] {
        AddItemSection.allCases
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

        // F1: Schedule warranty reminders if item has warranty date
        if hasWarranty, let service = reminderService {
            Task {
                await service.scheduleAllWarrantyRemindersForItem(item)
            }
        }

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
    private let reminderService: ReminderService?
    private let originalHadWarranty: Bool
    private let originalWarrantyDate: Date?

    // MARK: - Initialization

    init(item: Item, reminderService: ReminderService? = nil) {
        self.item = item
        self.reminderService = reminderService
        self.originalHadWarranty = item.warrantyExpiryDate != nil
        self.originalWarrantyDate = item.warrantyExpiryDate
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

        // F1: Update warranty reminders based on changes
        updateWarrantyReminders()
    }

    /// Updates warranty reminders based on warranty date changes
    private func updateWarrantyReminders() {
        guard let service = reminderService else { return }

        let warrantyChanged = hasWarranty != originalHadWarranty ||
            (hasWarranty && warrantyExpiryDate != originalWarrantyDate)

        guard warrantyChanged else { return }

        Task {
            // Cancel existing reminders first
            service.cancelAllWarrantyReminders(for: item)

            // Schedule new reminders if warranty is set
            if hasWarranty {
                await service.scheduleAllWarrantyRemindersForItem(item)
            }
        }
    }
}

// MARK: - Presentation Models (P2-07)

/// Represents a field in the add/edit item form
enum AddItemField: String, CaseIterable, Identifiable {
    case name
    case brand
    case modelNumber
    case serialNumber
    case purchasePrice
    case purchaseDate
    case category
    case room
    case condition
    case warranty

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .name: return "Name"
        case .brand: return "Brand"
        case .modelNumber: return "Model Number"
        case .serialNumber: return "Serial Number"
        case .purchasePrice: return "Purchase Price"
        case .purchaseDate: return "Purchase Date"
        case .category: return "Category"
        case .room: return "Room"
        case .condition: return "Condition"
        case .warranty: return "Warranty"
        }
    }

    var iconName: String {
        switch self {
        case .name: return "textformat"
        case .brand: return "tag.fill"
        case .modelNumber: return "number"
        case .serialNumber: return "barcode"
        case .purchasePrice: return "dollarsign.circle.fill"
        case .purchaseDate: return "calendar"
        case .category: return "folder.fill"
        case .room: return "door.left.hand.closed"
        case .condition: return "star.fill"
        case .warranty: return "shield.checkered"
        }
    }

    var isRequired: Bool {
        self == .name
    }

    var placeholder: String {
        switch self {
        case .name: return "Item name (required)"
        case .brand: return "e.g., Apple, Samsung"
        case .modelNumber: return "e.g., A2141"
        case .serialNumber: return "e.g., C02XL123"
        case .purchasePrice: return "0.00"
        case .purchaseDate: return "Select date"
        case .category: return "Select category"
        case .room: return "Select room"
        case .condition: return "Select condition"
        case .warranty: return "Warranty expiry date"
        }
    }
}

/// Represents a section in the add/edit item form
enum AddItemSection: String, CaseIterable, Identifiable {
    case basicInfo
    case purchaseInfo
    case location
    case status

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .basicInfo: return "Basic Information"
        case .purchaseInfo: return "Purchase Details"
        case .location: return "Location"
        case .status: return "Status & Condition"
        }
    }

    var iconName: String {
        switch self {
        case .basicInfo: return "info.circle.fill"
        case .purchaseInfo: return "creditcard.fill"
        case .location: return "location.fill"
        case .status: return "checkmark.seal.fill"
        }
    }

    var fields: [AddItemField] {
        switch self {
        case .basicInfo:
            return [.name, .brand, .modelNumber, .serialNumber]
        case .purchaseInfo:
            return [.purchasePrice, .purchaseDate]
        case .location:
            return [.category, .room]
        case .status:
            return [.condition, .warranty]
        }
    }
}

/// Validation state for a form field
enum FieldValidationState: Equatable {
    case valid
    case invalid(message: String)
    case warning(message: String)
    case pending

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var message: String? {
        switch self {
        case .invalid(let message), .warning(let message):
            return message
        default:
            return nil
        }
    }

    var iconName: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .pending: return "circle.dashed"
        }
    }

    var tintColor: String {
        switch self {
        case .valid: return "green"
        case .invalid: return "red"
        case .warning: return "orange"
        case .pending: return "gray"
        }
    }
}

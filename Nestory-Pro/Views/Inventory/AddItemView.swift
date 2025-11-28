//
//  AddItemView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    
    @State private var name = ""
    @State private var brand = ""
    @State private var modelNumber = ""
    @State private var serialNumber = ""
    @State private var purchasePrice = ""
    @State private var purchaseDate = Date()
    @State private var hasPurchaseDate = false
    @State private var selectedCategory: Category?
    @State private var selectedRoom: Room?
    @State private var condition: ItemCondition = .good
    @State private var conditionNotes = ""
    @State private var warrantyExpiryDate = Date()
    @State private var hasWarranty = false
    
    private let settings = SettingsManager.shared
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Basic Information") {
                    TextField("Item Name *", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Model Number", text: $modelNumber)
                    TextField("Serial Number", text: $serialNumber)
                }
                
                // Location
                Section("Location") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }
                    
                    Picker("Room", selection: $selectedRoom) {
                        Text("None").tag(nil as Room?)
                        ForEach(rooms) { room in
                            Label(room.name, systemImage: room.iconName)
                                .tag(room as Room?)
                        }
                    }
                }
                
                // Value & Date
                Section("Purchase Information") {
                    HStack {
                        Text(settings.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("Purchase Price", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    Toggle("Purchase Date", isOn: $hasPurchaseDate)
                    
                    if hasPurchaseDate {
                        DatePicker(
                            "Date",
                            selection: $purchaseDate,
                            displayedComponents: .date
                        )
                    }
                }
                
                // Condition
                Section("Condition") {
                    Picker("Condition", selection: $condition) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                    
                    TextField("Condition Notes", text: $conditionNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Warranty
                Section("Warranty") {
                    Toggle("Has Warranty", isOn: $hasWarranty)
                    
                    if hasWarranty {
                        DatePicker(
                            "Expiry Date",
                            selection: $warrantyExpiryDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
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
        dismiss()
    }
}

// MARK: - Edit Item View
struct EditItemView: View {
    @Bindable var item: Item
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    
    @State private var name: String
    @State private var brand: String
    @State private var modelNumber: String
    @State private var serialNumber: String
    @State private var purchasePrice: String
    @State private var purchaseDate: Date
    @State private var hasPurchaseDate: Bool
    @State private var selectedCategory: Category?
    @State private var selectedRoom: Room?
    @State private var condition: ItemCondition
    @State private var conditionNotes: String
    @State private var warrantyExpiryDate: Date
    @State private var hasWarranty: Bool
    
    private let settings = SettingsManager.shared
    
    init(item: Item) {
        self.item = item
        _name = State(initialValue: item.name)
        _brand = State(initialValue: item.brand ?? "")
        _modelNumber = State(initialValue: item.modelNumber ?? "")
        _serialNumber = State(initialValue: item.serialNumber ?? "")
        _purchasePrice = State(initialValue: item.purchasePrice.map { "\($0)" } ?? "")
        _purchaseDate = State(initialValue: item.purchaseDate ?? Date())
        _hasPurchaseDate = State(initialValue: item.purchaseDate != nil)
        _selectedCategory = State(initialValue: item.category)
        _selectedRoom = State(initialValue: item.room)
        _condition = State(initialValue: item.condition)
        _conditionNotes = State(initialValue: item.conditionNotes ?? "")
        _warrantyExpiryDate = State(initialValue: item.warrantyExpiryDate ?? Date())
        _hasWarranty = State(initialValue: item.warrantyExpiryDate != nil)
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Item Name *", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Model Number", text: $modelNumber)
                    TextField("Serial Number", text: $serialNumber)
                }
                
                Section("Location") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }
                    
                    Picker("Room", selection: $selectedRoom) {
                        Text("None").tag(nil as Room?)
                        ForEach(rooms) { room in
                            Label(room.name, systemImage: room.iconName)
                                .tag(room as Room?)
                        }
                    }
                }
                
                Section("Purchase Information") {
                    HStack {
                        Text(settings.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("Purchase Price", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    Toggle("Purchase Date", isOn: $hasPurchaseDate)
                    
                    if hasPurchaseDate {
                        DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                    }
                }
                
                Section("Condition") {
                    Picker("Condition", selection: $condition) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                    
                    TextField("Condition Notes", text: $conditionNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Warranty") {
                    Toggle("Has Warranty", isOn: $hasWarranty)
                    
                    if hasWarranty {
                        DatePicker("Expiry Date", selection: $warrantyExpiryDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func saveChanges() {
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
        
        dismiss()
    }
}

#Preview {
    AddItemView()
        .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
}

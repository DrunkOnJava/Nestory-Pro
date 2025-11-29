//
//  AddItemView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// TASK 4.1.1 COMPLETED: 100-item free tier limit enforcement added
// ============================================================================
// Implementation:
// - Added @Query for items count
// - Added @State showingPaywall for limit enforcement
// - Check items.count >= maxFreeItems before saving
// - Show ProPaywallView if limit reached (user must dismiss or upgrade)
//
// REMAINING TASKS:
// - Task 5.1.2: Extract form state to AddItemViewModel
// - Task 6.1.2: Pre-select default room from settings
// - Task 7.1.x: Add accessibility labels to all form fields
//
// TECHNICAL NOTES:
// - Uses SettingsManager.shared (singleton, needs DI refactor in future)
// - ProPaywallView dismisses automatically on successful purchase
// ============================================================================

import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    @Query private var items: [Item] // Task 4.1.1: Count existing items for free tier limit
    
    @State private var viewModel: AddItemViewModel
    
    init() {
        // ViewModel will be properly initialized via @Environment in body
        _viewModel = State(initialValue: AddItemViewModel(settings: SettingsManager()))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        
        return NavigationStack {
            Form {
                // Basic Info
                Section("Basic Information") {
                    TextField("Item Name *", text: $vm.name)
                    TextField("Brand", text: $vm.brand)
                    TextField("Model Number", text: $vm.modelNumber)
                    TextField("Serial Number", text: $vm.serialNumber)
                }
                
                // Location
                Section("Location") {
                    Picker("Category", selection: $vm.selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }
                    
                    Picker("Room", selection: $vm.selectedRoom) {
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
                        Text(env.settings.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("Purchase Price", text: $vm.purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    Toggle("Purchase Date", isOn: $vm.hasPurchaseDate)
                    
                    if vm.hasPurchaseDate {
                        DatePicker(
                            "Date",
                            selection: $vm.purchaseDate,
                            displayedComponents: .date
                        )
                    }
                }
                
                // Condition
                Section("Condition") {
                    Picker("Condition", selection: $vm.condition) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                    
                    TextField("Condition Notes", text: $vm.conditionNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Warranty
                Section("Warranty") {
                    Toggle("Has Warranty", isOn: $vm.hasWarranty)
                    
                    if vm.hasWarranty {
                        DatePicker(
                            "Expiry Date",
                            selection: $vm.warrantyExpiryDate,
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
                    .disabled(!viewModel.canSave)
                }
            }
            .sheet(isPresented: $vm.showingPaywall) {
                ProPaywallView()
            }
            .task {
                // Initialize with proper AppEnvironment settings
                viewModel = env.makeAddItemViewModel()
            }
        }
    }

    private func saveItem() {
        if viewModel.saveItem(modelContext: modelContext, itemCount: items.count) != nil {
            dismiss()
        }
        // If saveItem returns nil, either validation failed or paywall is shown
    }
}

// MARK: - Edit Item View
struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    
    @State private var viewModel: EditItemViewModel
    
    init(item: Item) {
        _viewModel = State(initialValue: EditItemViewModel(item: item))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        
        return NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Item Name *", text: $vm.name)
                    TextField("Brand", text: $vm.brand)
                    TextField("Model Number", text: $vm.modelNumber)
                    TextField("Serial Number", text: $vm.serialNumber)
                }
                
                Section("Location") {
                    Picker("Category", selection: $vm.selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }
                    
                    Picker("Room", selection: $vm.selectedRoom) {
                        Text("None").tag(nil as Room?)
                        ForEach(rooms) { room in
                            Label(room.name, systemImage: room.iconName)
                                .tag(room as Room?)
                        }
                    }
                }
                
                Section("Purchase Information") {
                    HStack {
                        Text(env.settings.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("Purchase Price", text: $vm.purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    Toggle("Purchase Date", isOn: $vm.hasPurchaseDate)
                    
                    if vm.hasPurchaseDate {
                        DatePicker("Date", selection: $vm.purchaseDate, displayedComponents: .date)
                    }
                }
                
                Section("Condition") {
                    Picker("Condition", selection: $vm.condition) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                    
                    TextField("Condition Notes", text: $vm.conditionNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Warranty") {
                    Toggle("Has Warranty", isOn: $vm.hasWarranty)
                    
                    if vm.hasWarranty {
                        DatePicker("Expiry Date", selection: $vm.warrantyExpiryDate, displayedComponents: .date)
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
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
    
    private func saveChanges() {
        viewModel.saveChanges()
        dismiss()
    }
}

#Preview {
    AddItemView()
        .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
}

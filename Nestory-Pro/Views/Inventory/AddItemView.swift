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
        // ViewModel will be initialized in .task using AppEnvironment.makeAddItemViewModel()
        // Placeholder with nil reminderService - proper ViewModel created in .task
        _viewModel = State(initialValue: AddItemViewModel(settings: SettingsManager(), reminderService: nil))
    }
    
    var body: some View {
        @Bindable var vm = viewModel

        return NavigationStack {
            Form {
                // Validation error banner (P2-12-1)
                if !viewModel.validationErrors.isEmpty {
                    Section {
                        HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(NestoryTheme.Colors.warning)
                            Text("Fix errors to save")
                                .font(NestoryTheme.Typography.subheadline)
                                .foregroundStyle(NestoryTheme.Colors.warning)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                // Basic Info (P2-12-1)
                Section {
                    validatedTextField(field: .name, text: $vm.name)
                    validatedTextField(field: .brand, text: $vm.brand)
                    validatedTextField(field: .modelNumber, text: $vm.modelNumber)
                    validatedTextField(field: .serialNumber, text: $vm.serialNumber)
                } header: {
                    sectionHeader(AddItemSection.basicInfo)
                }

                // Location (P2-12-1)
                Section {
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
                } header: {
                    sectionHeader(AddItemSection.location)
                }

                // Purchase Information (P2-12-1)
                Section {
                    HStack {
                        Text(env.settings.currencySymbol)
                            .font(NestoryTheme.Typography.body)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                        validatedTextField(field: .purchasePrice, text: $vm.purchasePrice, keyboardType: .decimalPad)
                    }

                    Toggle("Purchase Date", isOn: $vm.hasPurchaseDate)

                    if vm.hasPurchaseDate {
                        DatePicker(
                            "Date",
                            selection: $vm.purchaseDate,
                            displayedComponents: .date
                        )
                        validationCaption(for: .purchaseDate)
                    }
                } header: {
                    sectionHeader(AddItemSection.purchaseInfo)
                }

                // Condition (P2-12-1)
                Section {
                    Picker("Condition", selection: $vm.condition) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }

                    TextField("Condition Notes", text: $vm.conditionNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    sectionHeader(AddItemSection.status)
                }

                // Warranty (P2-12-1)
                Section("Warranty") {
                    Toggle("Has Warranty", isOn: $vm.hasWarranty)

                    if vm.hasWarranty {
                        DatePicker(
                            "Expiry Date",
                            selection: $vm.warrantyExpiryDate,
                            displayedComponents: .date
                        )
                        validationCaption(for: .warranty)
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
                // Keyboard toolbar (P2-12-1)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .sheet(isPresented: $vm.showingPaywall) {
                ProPaywallView()
            }
            .task {
                // Initialize with proper AppEnvironment settings
                let vm = env.makeAddItemViewModel()
                // Task 6.1.2: Set default room from settings
                vm.setDefaultRoom(rooms)
                viewModel = vm
            }
        }
    }

    // MARK: - Section Header (P2-12-1)

    private func sectionHeader(_ section: AddItemSection) -> some View {
        Label(section.displayName, systemImage: section.iconName)
            .font(NestoryTheme.Typography.caption)
            .foregroundStyle(NestoryTheme.Colors.muted)
    }

    // MARK: - Validated TextField (P2-12-1)

    @ViewBuilder
    private func validatedTextField(
        field: AddItemField,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        let state = viewModel.validationState(for: field)
        let tintColor: Color = {
            switch state {
            case .valid: return .primary
            case .invalid: return NestoryTheme.Colors.warning
            case .warning: return .orange
            case .pending: return .primary
            }
        }()

        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
            TextField(field.isRequired ? "\(field.displayName) *" : field.displayName, text: text)
                .keyboardType(keyboardType)
                .foregroundStyle(tintColor)

            validationCaption(for: field)
        }
    }

    // MARK: - Validation Caption (P2-12-1)

    @ViewBuilder
    private func validationCaption(for field: AddItemField) -> some View {
        let state = viewModel.validationState(for: field)
        if let message = state.message {
            HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                Image(systemName: state.iconName)
                Text(message)
            }
            .font(NestoryTheme.Typography.caption)
            .foregroundStyle(state.tintColor == "red" ? NestoryTheme.Colors.warning : .orange)
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
    private let item: Item

    init(item: Item) {
        self.item = item
        // Placeholder ViewModel - proper one with reminderService created in .task
        _viewModel = State(initialValue: EditItemViewModel(item: item, reminderService: nil))
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
            .task {
                // Initialize with proper AppEnvironment reminderService for warranty notifications
                viewModel = env.makeEditItemViewModel(for: item)
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
        .environment(AppEnvironment())
        .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
}

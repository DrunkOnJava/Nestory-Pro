//
//  PropertyEditorSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture - Property editor
// Add/edit property form
// ============================================================================

import SwiftUI
import SwiftData

/// Editor sheet for creating or editing properties
struct PropertyEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: Mode
    
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var selectedIcon: String = "house.fill"
    @State private var selectedColor: String = "#007AFF"
    @State private var notes: String = ""
    @State private var isDefault: Bool = false
    @State private var showingValidationError = false
    @State private var validationError: String = ""
    
    enum Mode {
        case add
        case edit(Property)
        
        var title: String {
            switch self {
            case .add: return "Add Property"
            case .edit: return "Edit Property"
            }
        }
        
        var property: Property? {
            switch self {
            case .add: return nil
            case .edit(let property): return property
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("Details") {
                    TextField("Property Name", text: $name)
                        .textContentType(.location)
                    
                    TextField("Address (optional)", text: $address)
                        .textContentType(.fullStreetAddress)
                }
                
                // Icon selection
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Property.availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : Color(hex: selectedColor) ?? .blue)
                                    .frame(width: 48, height: 48)
                                    .background(selectedIcon == icon ? Color(hex: selectedColor) ?? .blue : Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Color selection
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Property.availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.body.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Notes
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Default toggle
                Section {
                    Toggle("Set as Default Property", isOn: $isDefault)
                } footer: {
                    Text("The default property is shown first when browsing your inventory.")
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK") { }
            } message: {
                Text(validationError)
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadExistingData() {
        guard let property = mode.property else { return }
        name = property.name
        address = property.address ?? ""
        selectedIcon = property.iconName
        selectedColor = property.colorHex
        notes = property.notes ?? ""
        isDefault = property.isDefault
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            validationError = "Property name cannot be empty"
            showingValidationError = true
            return
        }
        
        switch mode {
        case .add:
            let property = Property(
                name: trimmedName,
                address: address.isEmpty ? nil : address,
                iconName: selectedIcon,
                colorHex: selectedColor,
                isDefault: isDefault,
                notes: notes.isEmpty ? nil : notes
            )
            
            // If setting as default, clear other defaults
            if isDefault {
                clearOtherDefaults()
            }
            
            modelContext.insert(property)
            
        case .edit(let property):
            property.name = trimmedName
            property.address = address.isEmpty ? nil : address
            property.iconName = selectedIcon
            property.colorHex = selectedColor
            property.notes = notes.isEmpty ? nil : notes
            property.updatedAt = Date()
            
            if isDefault && !property.isDefault {
                clearOtherDefaults()
            }
            property.isDefault = isDefault
        }
        
        dismiss()
    }
    
    private func clearOtherDefaults() {
        let descriptor = FetchDescriptor<Property>(predicate: #Predicate { $0.isDefault })
        if let properties = try? modelContext.fetch(descriptor) {
            for property in properties {
                property.isDefault = false
            }
        }
    }
}

#Preview("Add") {
    PropertyEditorSheet(mode: .add)
        .modelContainer(for: Property.self, inMemory: true)
}

#Preview("Edit") {
    PropertyEditorSheet(mode: .edit(Property(name: "My Home", isDefault: true)))
        .modelContainer(for: Property.self, inMemory: true)
}

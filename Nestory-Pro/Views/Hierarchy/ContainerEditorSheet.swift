//
//  ContainerEditorSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture - Container editor
// Add/edit container form
// ============================================================================

import SwiftUI
import SwiftData

/// Editor sheet for creating or editing containers
struct ContainerEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: Mode
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "shippingbox.fill"
    @State private var selectedColor: String = "#8B5CF6"
    @State private var notes: String = ""
    @State private var showingValidationError = false
    @State private var validationError: String = ""
    
    enum Mode {
        case add(room: Room)
        case edit(Container)
        
        var title: String {
            switch self {
            case .add: return "Add Container"
            case .edit: return "Edit Container"
            }
        }
        
        var container: Container? {
            switch self {
            case .add: return nil
            case .edit(let container): return container
            }
        }
        
        var room: Room? {
            switch self {
            case .add(let room): return room
            case .edit(let container): return container.room
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("Details") {
                    TextField("Container Name", text: $name)
                }
                
                // Icon selection
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Container.availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : Color(hex: selectedColor) ?? .purple)
                                    .frame(width: 48, height: 48)
                                    .background(selectedIcon == icon ? Color(hex: selectedColor) ?? .purple : Color(.systemGray5))
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
                        ForEach(Container.availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(hex: color) ?? .purple)
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
                
                // Quick templates
                if case .add = mode {
                    Section("Common Containers") {
                        ForEach(Container.templates.prefix(6), id: \.name) { template in
                            Button(action: {
                                name = template.name
                                selectedIcon = template.icon
                            }) {
                                HStack {
                                    Image(systemName: template.icon)
                                        .foregroundStyle(Color(hex: selectedColor) ?? .purple)
                                        .frame(width: 28)
                                    Text(template.name)
                                    Spacer()
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
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
        guard let container = mode.container else { return }
        name = container.name
        selectedIcon = container.iconName
        selectedColor = container.colorHex
        notes = container.notes ?? ""
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            validationError = "Container name cannot be empty"
            showingValidationError = true
            return
        }
        
        switch mode {
        case .add(let room):
            let container = Container(
                name: trimmedName,
                iconName: selectedIcon,
                colorHex: selectedColor,
                sortOrder: room.containers.count,
                notes: notes.isEmpty ? nil : notes,
                room: room
            )
            modelContext.insert(container)
            
        case .edit(let container):
            container.name = trimmedName
            container.iconName = selectedIcon
            container.colorHex = selectedColor
            container.notes = notes.isEmpty ? nil : notes
            container.updatedAt = Date()
        }
        
        dismiss()
    }
}

#Preview("Add") {
    ContainerEditorSheet(mode: .add(room: Room(name: "Living Room")))
        .modelContainer(for: [Room.self, Container.self], inMemory: true)
}

#Preview("Edit") {
    ContainerEditorSheet(mode: .edit(Container(name: "TV Stand", iconName: "cabinet.fill")))
        .modelContainer(for: [Room.self, Container.self], inMemory: true)
}

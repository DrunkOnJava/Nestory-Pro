//
//  RoomEditorSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture - Room editor
// Add/edit room form
// ============================================================================

import SwiftUI
import SwiftData

/// Editor sheet for creating or editing rooms
struct RoomEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: Mode
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "door.left.hand.closed"
    @State private var showingValidationError = false
    @State private var validationError: String = ""
    
    enum Mode {
        case add(property: Property)
        case edit(Room)
        
        var title: String {
            switch self {
            case .add: return "Add Room"
            case .edit: return "Edit Room"
            }
        }
        
        var room: Room? {
            switch self {
            case .add: return nil
            case .edit(let room): return room
            }
        }
        
        var property: Property? {
            switch self {
            case .add(let property): return property
            case .edit(let room): return room.property
            }
        }
    }
    
    private let availableIcons = Room.defaultRooms.map { $0.icon } + [
        "door.left.hand.closed",
        "door.garage.closed",
        "washer.fill",
        "dryer.fill",
        "lamp.desk.fill",
        "lamp.floor.fill",
        "fan.ceiling.fill",
        "window.horizontal.closed"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("Details") {
                    TextField("Room Name", text: $name)
                }
                
                // Icon selection
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Array(Set(availableIcons)).sorted(), id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : .blue)
                                    .frame(width: 48, height: 48)
                                    .background(selectedIcon == icon ? Color.blue : Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Quick templates
                if case .add = mode {
                    Section("Quick Add") {
                        ForEach(Room.defaultRooms.prefix(6), id: \.name) { roomData in
                            Button(action: {
                                name = roomData.name
                                selectedIcon = roomData.icon
                            }) {
                                HStack {
                                    Image(systemName: roomData.icon)
                                        .foregroundStyle(.blue)
                                        .frame(width: 28)
                                    Text(roomData.name)
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
        guard let room = mode.room else { return }
        name = room.name
        selectedIcon = room.iconName
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            validationError = "Room name cannot be empty"
            showingValidationError = true
            return
        }
        
        switch mode {
        case .add(let property):
            let room = Room(
                name: trimmedName,
                iconName: selectedIcon,
                sortOrder: property.rooms.count,
                isDefault: false,
                property: property
            )
            modelContext.insert(room)
            
        case .edit(let room):
            room.name = trimmedName
            room.iconName = selectedIcon
        }
        
        dismiss()
    }
}

#Preview("Add") {
    RoomEditorSheet(mode: .add(property: Property(name: "My Home")))
        .modelContainer(for: [Property.self, Room.self], inMemory: true)
}

#Preview("Edit") {
    RoomEditorSheet(mode: .edit(Room(name: "Living Room", iconName: "sofa.fill")))
        .modelContainer(for: [Property.self, Room.self], inMemory: true)
}

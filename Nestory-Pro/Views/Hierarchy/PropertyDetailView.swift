//
//  PropertyDetailView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture - Property detail view
// Shows rooms within a property with stats and navigation
// ============================================================================

import SwiftUI
import SwiftData

/// Displays details of a property including its rooms
struct PropertyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var property: Property
    
    @State private var showingAddRoom = false
    @State private var editingRoom: Room?
    @State private var roomToDelete: Room?
    @State private var showingDeleteConfirmation = false
    @State private var showingEditProperty = false
    
    var body: some View {
        List {
            // Summary section
            summarySection
            
            // Rooms section
            roomsSection
        }
        .navigationTitle(property.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddRoom = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Room")
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingEditProperty = true }) {
                    Label("Edit Property", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingAddRoom) {
            RoomEditorSheet(mode: .add(property: property))
        }
        .sheet(item: $editingRoom) { room in
            RoomEditorSheet(mode: .edit(room))
        }
        .sheet(isPresented: $showingEditProperty) {
            PropertyEditorSheet(mode: .edit(property))
        }
        .confirmationDialog(
            "Delete Room?",
            isPresented: $showingDeleteConfirmation,
            presenting: roomToDelete
        ) { room in
            Button("Delete \"\(room.name)\"", role: .destructive) {
                deleteRoom(room)
            }
        } message: { room in
            Text("This will delete all containers and items in this room. This action cannot be undone.")
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                // Icon and name
                HStack {
                    Image(systemName: property.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: property.colorHex) ?? .blue)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: property.colorHex)?.opacity(0.1) ?? Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let address = property.address, !address.isEmpty {
                            Text(address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if property.isDefault {
                            Text("Default Property")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Stats grid
                HStack(spacing: 0) {
                    StatCell(
                        value: "\(property.rooms.count)",
                        label: "Rooms",
                        iconName: "door.left.hand.closed"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatCell(
                        value: "\(property.totalItemCount)",
                        label: "Items",
                        iconName: "archivebox.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatCell(
                        value: formatCurrency(property.totalValue),
                        label: "Value",
                        iconName: "dollarsign.circle.fill"
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Rooms Section
    
    private var roomsSection: some View {
        Section("Rooms") {
            if property.rooms.isEmpty {
                emptyRoomsView
            } else {
                ForEach(property.rooms.sorted(by: { $0.sortOrder < $1.sortOrder })) { room in
                    NavigationLink(destination: RoomDetailView(room: room)) {
                        RoomRowView(room: room)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !room.isDefault {
                            Button(role: .destructive) {
                                roomToDelete = room
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        
                        Button {
                            editingRoom = room
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
                .onMove(perform: moveRooms)
            }
        }
    }
    
    private var emptyRoomsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "door.left.hand.closed")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("No Rooms Yet")
                .font(.subheadline)
            
            Button(action: { showingAddRoom = true }) {
                Label("Add Room", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Actions
    
    private func moveRooms(from source: IndexSet, to destination: Int) {
        var orderedRooms = property.rooms.sorted(by: { $0.sortOrder < $1.sortOrder })
        orderedRooms.move(fromOffsets: source, toOffset: destination)
        for (index, room) in orderedRooms.enumerated() {
            room.sortOrder = index
        }
    }
    
    private func deleteRoom(_ room: Room) {
        modelContext.delete(room)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Room Row View

struct RoomRowView: View {
    let room: Room
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: room.iconName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(room.name)
                        .font(.body)
                    
                    if room.isDefault {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    if !room.containers.isEmpty {
                        Label("\(room.containers.count)", systemImage: "shippingbox.fill")
                    }
                    Label("\(room.items.count) items", systemImage: "archivebox.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Stat Cell

private struct StatCell: View {
    let value: String
    let label: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        PropertyDetailView(property: Property(name: "My Home", isDefault: true))
    }
    .modelContainer(for: [Property.self, Room.self, Item.self], inMemory: true)
}

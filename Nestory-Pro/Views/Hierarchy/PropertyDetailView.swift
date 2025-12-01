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
    @State private var renamingRoom: Room?
    @State private var renameText: String = ""
    
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
        .alert("Rename Room", isPresented: .init(
            get: { renamingRoom != nil },
            set: { if !$0 { renamingRoom = nil } }
        )) {
            TextField("Room Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renamingRoom = nil
            }
            Button("Rename") {
                if let room = renamingRoom {
                    renameRoom(room, to: renameText)
                }
            }
        } message: {
            Text("Enter a new name for this room.")
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Section {
            VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                // Icon and name
                HStack {
                    Image(systemName: property.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: property.colorHex) ?? NestoryTheme.Colors.accent)
                        .frame(width: NestoryTheme.Metrics.iconHero, height: NestoryTheme.Metrics.iconHero)
                        .background(Color(hex: property.colorHex)?.opacity(0.1) ?? NestoryTheme.Colors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))

                    VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                        if let address = property.address, !address.isEmpty {
                            Text(address)
                                .font(NestoryTheme.Typography.subheadline)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                        }

                        if property.isDefault {
                            Text("Default Property")
                                .font(NestoryTheme.Typography.caption)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                                .padding(.horizontal, NestoryTheme.Metrics.paddingSmall)
                                .padding(.vertical, NestoryTheme.Metrics.paddingXSmall)
                                .background(NestoryTheme.Colors.chipBackground)
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
                        .frame(height: NestoryTheme.Metrics.thumbnailSmall)

                    StatCell(
                        value: "\(property.totalItemCount)",
                        label: "Items",
                        iconName: "archivebox.fill"
                    )

                    Divider()
                        .frame(height: NestoryTheme.Metrics.thumbnailSmall)

                    StatCell(
                        value: formatCurrency(property.totalValue),
                        label: "Value",
                        iconName: "dollarsign.circle.fill"
                    )
                }
            }
            .padding(.vertical, NestoryTheme.Metrics.paddingSmall)
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
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            renameText = room.name
                            renamingRoom = room
                        } label: {
                            Label("Rename", systemImage: "character.cursor.ibeam")
                        }
                        .tint(.blue)
                    }
                }
                .onMove(perform: moveRooms)
            }
        }
    }
    
    private var emptyRoomsView: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            Image(systemName: "door.left.hand.closed")
                .font(.system(size: NestoryTheme.Metrics.iconLarge))
                .foregroundStyle(NestoryTheme.Colors.muted)

            Text("No Rooms Yet")
                .font(NestoryTheme.Typography.subheadline)

            Button(action: { showingAddRoom = true }) {
                Label("Add Room", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NestoryTheme.Metrics.spacingXLarge)
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

    private func renameRoom(_ room: Room, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        room.name = trimmedName
        renamingRoom = nil
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
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            Image(systemName: room.iconName)
                .font(.title3)
                .foregroundStyle(NestoryTheme.Colors.info)
                .frame(width: NestoryTheme.Metrics.iconLarge + 4, height: NestoryTheme.Metrics.iconLarge + 4)
                .background(NestoryTheme.Colors.info.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall + 2))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(room.name)
                        .font(NestoryTheme.Typography.body)

                    if room.isDefault {
                        Image(systemName: "checkmark.seal.fill")
                            .font(NestoryTheme.Typography.caption2)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                }

                HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                    if !room.containers.isEmpty {
                        Label("\(room.containers.count)", systemImage: "shippingbox.fill")
                    }
                    Label("\(room.items.count) items", systemImage: "archivebox.fill")
                }
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
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
        VStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
            Image(systemName: iconName)
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
            Text(value)
                .font(NestoryTheme.Typography.statValue)
            Text(label)
                .font(NestoryTheme.Typography.statLabel)
                .foregroundStyle(NestoryTheme.Colors.muted)
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

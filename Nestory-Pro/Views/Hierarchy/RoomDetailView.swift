//
//  RoomDetailView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture - Room detail view
// Shows containers and items within a room
// ============================================================================

import SwiftUI
import SwiftData

/// Displays details of a room including containers and items
struct RoomDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var room: Room
    
    @State private var showingAddContainer = false
    @State private var editingContainer: Container?
    @State private var containerToDelete: Container?
    @State private var showingDeleteConfirmation = false
    @State private var showingEditRoom = false
    
    var body: some View {
        List {
            // Breadcrumb
            if room.property != nil {
                Section {
                    BreadcrumbView(room: room)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // Summary section
            summarySection
            
            // Containers section
            if !room.containers.isEmpty {
                containersSection
            }
            
            // Items in room (not in containers)
            itemsSection
        }
        .navigationTitle(room.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingAddContainer = true }) {
                        Label("Add Container", systemImage: "shippingbox.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingEditRoom = true }) {
                    Label("Edit Room", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingAddContainer) {
            ContainerEditorSheet(mode: .add(room: room))
        }
        .sheet(item: $editingContainer) { container in
            ContainerEditorSheet(mode: .edit(container))
        }
        .sheet(isPresented: $showingEditRoom) {
            RoomEditorSheet(mode: .edit(room))
        }
        .confirmationDialog(
            "Delete Container?",
            isPresented: $showingDeleteConfirmation,
            presenting: containerToDelete
        ) { container in
            Button("Delete \"\(container.name)\"", role: .destructive) {
                deleteContainer(container)
            }
        } message: { _ in
            Text("Items in this container will remain in the room. This action cannot be undone.")
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Section {
            HStack(spacing: 0) {
                StatCell(
                    value: "\(room.containers.count)",
                    label: "Containers",
                    iconName: "shippingbox.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatCell(
                    value: "\(room.items.count)",
                    label: "Items",
                    iconName: "archivebox.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatCell(
                    value: formatCurrency(room.totalValue),
                    label: "Value",
                    iconName: "dollarsign.circle.fill"
                )
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Containers Section
    
    private var containersSection: some View {
        Section("Containers") {
            ForEach(room.containers.sorted(by: { $0.sortOrder < $1.sortOrder })) { container in
                NavigationLink(destination: ContainerDetailView(container: container)) {
                    ContainerRowView(container: container)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        containerToDelete = container
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        editingContainer = container
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
            .onMove(perform: moveContainers)
        }
    }
    
    // MARK: - Items Section
    
    private var itemsSection: some View {
        Section("Items in Room") {
            if room.items.isEmpty {
                Text("No items in this room yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(room.items) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemRowCompact(item: item)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func moveContainers(from source: IndexSet, to destination: Int) {
        var orderedContainers = room.containers.sorted(by: { $0.sortOrder < $1.sortOrder })
        orderedContainers.move(fromOffsets: source, toOffset: destination)
        for (index, container) in orderedContainers.enumerated() {
            container.sortOrder = index
        }
    }
    
    private func deleteContainer(_ container: Container) {
        // Items remain in room but lose container reference
        for item in container.items {
            item.container = nil
        }
        modelContext.delete(container)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Container Row View

struct ContainerRowView: View {
    let container: Container
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: container.iconName)
                .font(.title3)
                .foregroundStyle(Color(hex: container.colorHex) ?? .purple)
                .frame(width: 36, height: 36)
                .background(Color(hex: container.colorHex)?.opacity(0.1) ?? Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(.body)
                
                Label("\(container.items.count) items", systemImage: "archivebox.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Item Row Compact

private struct ItemRowCompact: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let firstPhoto = item.photos.first {
                AsyncPhotoThumbnail(identifier: firstPhoto.imageIdentifier)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: item.category?.iconName ?? "archivebox.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)
                
                if let container = item.container {
                    Label(container.name, systemImage: "shippingbox.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let price = item.purchasePrice {
                Text(formatCurrency(price))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Async Photo Thumbnail

private struct AsyncPhotoThumbnail: View {
    let identifier: String
    
    var body: some View {
        // Placeholder - actual implementation would load from PhotoStorageService
        Rectangle()
            .fill(Color(.systemGray4))
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
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
        RoomDetailView(room: Room(name: "Living Room", iconName: "sofa.fill"))
    }
    .modelContainer(for: [Property.self, Room.self, Container.self, Item.self], inMemory: true)
}

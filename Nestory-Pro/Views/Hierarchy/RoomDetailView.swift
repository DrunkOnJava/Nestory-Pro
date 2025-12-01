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
    @State private var renamingContainer: Container?
    @State private var renameText: String = ""
    
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
        .alert("Rename Container", isPresented: .init(
            get: { renamingContainer != nil },
            set: { if !$0 { renamingContainer = nil } }
        )) {
            TextField("Container Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renamingContainer = nil
            }
            Button("Rename") {
                if let container = renamingContainer {
                    renameContainer(container, to: renameText)
                }
            }
        } message: {
            Text("Enter a new name for this container.")
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
                    .frame(height: NestoryTheme.Metrics.thumbnailSmall)

                StatCell(
                    value: "\(room.items.count)",
                    label: "Items",
                    iconName: "archivebox.fill"
                )

                Divider()
                    .frame(height: NestoryTheme.Metrics.thumbnailSmall)

                StatCell(
                    value: formatCurrency(room.totalValue),
                    label: "Value",
                    iconName: "dollarsign.circle.fill"
                )
            }
            .padding(.vertical, NestoryTheme.Metrics.paddingSmall)
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
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        renameText = container.name
                        renamingContainer = container
                    } label: {
                        Label("Rename", systemImage: "character.cursor.ibeam")
                    }
                    .tint(.blue)
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

    private func renameContainer(_ container: Container, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        container.name = trimmedName
        container.updatedAt = Date()
        renamingContainer = nil
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
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            Image(systemName: container.iconName)
                .font(.title3)
                .foregroundStyle(Color(hex: container.colorHex) ?? .purple)
                .frame(width: NestoryTheme.Metrics.iconLarge + 4, height: NestoryTheme.Metrics.iconLarge + 4)
                .background(Color(hex: container.colorHex)?.opacity(0.1) ?? Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall + 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(NestoryTheme.Typography.body)

                Label("\(container.items.count) items", systemImage: "archivebox.fill")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
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
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Thumbnail
            if let firstPhoto = item.photos.first {
                AsyncPhotoThumbnail(identifier: firstPhoto.imageIdentifier)
                    .frame(width: NestoryTheme.Metrics.thumbnailSmall, height: NestoryTheme.Metrics.thumbnailSmall)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
            } else {
                Image(systemName: item.category?.iconName ?? "archivebox.fill")
                    .font(.title3)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .frame(width: NestoryTheme.Metrics.thumbnailSmall, height: NestoryTheme.Metrics.thumbnailSmall)
                    .background(NestoryTheme.Colors.chipBackground)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(NestoryTheme.Typography.body)
                    .lineLimit(1)

                if let container = item.container {
                    Label(container.name, systemImage: "shippingbox.fill")
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }

            Spacer()

            if let price = item.purchasePrice {
                Text(formatCurrency(price))
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
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
        RoomDetailView(room: Room(name: "Living Room", iconName: "sofa.fill"))
    }
    .modelContainer(for: [Property.self, Room.self, Container.self, Item.self], inMemory: true)
}

//
//  ContainerDetailView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture - Container detail view
// Shows items within a container
// ============================================================================

import SwiftUI
import SwiftData

/// Displays details of a container and its items
struct ContainerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var container: Container
    
    @State private var showingEditContainer = false
    @State private var itemToRemove: Item?
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        List {
            // Breadcrumb
            Section {
                BreadcrumbView(container: container)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // Summary section
            summarySection
            
            // Items section
            itemsSection
        }
        .navigationTitle(container.name)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingEditContainer = true }) {
                    Label("Edit Container", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditContainer) {
            ContainerEditorSheet(mode: .edit(container))
        }
        .confirmationDialog(
            "Remove from Container?",
            isPresented: $showingRemoveConfirmation,
            presenting: itemToRemove
        ) { item in
            Button("Remove \"\(item.name)\"") {
                removeItem(item)
            }
        } message: { item in
            Text("This item will remain in the room but will no longer be in this container.")
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: container.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: container.colorHex) ?? .purple)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: container.colorHex)?.opacity(0.1) ?? Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let notes = container.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        if let room = container.room {
                            Label(room.name, systemImage: room.iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack(spacing: 0) {
                    StatCell(
                        value: "\(container.items.count)",
                        label: "Items",
                        iconName: "archivebox.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatCell(
                        value: formatCurrency(container.totalValue),
                        label: "Value",
                        iconName: "dollarsign.circle.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    StatCell(
                        value: "\(Int(container.averageDocumentationScore * 100))%",
                        label: "Documented",
                        iconName: "checkmark.shield.fill"
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Items Section
    
    private var itemsSection: some View {
        Section("Items") {
            if container.items.isEmpty {
                emptyItemsView
            } else {
                ForEach(container.items) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ContainerItemRow(item: item)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            itemToRemove = item
                            showingRemoveConfirmation = true
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
    }
    
    private var emptyItemsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("No Items in Container")
                .font(.subheadline)
            
            Text("Add items to this container from the item detail view.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Actions
    
    private func removeItem(_ item: Item) {
        item.container = nil
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Container Item Row

private struct ContainerItemRow: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let firstPhoto = item.photos.first {
                AsyncPhotoThumbnail(identifier: firstPhoto.imageIdentifier)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: item.category?.iconName ?? "archivebox.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let category = item.category {
                        Label(category.name, systemImage: category.iconName)
                    }
                    
                    // Documentation status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.isDocumented ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(item.isDocumented ? "Documented" : "Incomplete")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let price = item.purchasePrice {
                Text(formatCurrency(price))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
        ContainerDetailView(container: Container(name: "TV Stand", iconName: "cabinet.fill"))
    }
    .modelContainer(for: [Property.self, Room.self, Container.self, Item.self], inMemory: true)
}

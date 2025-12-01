//
//  PropertyListView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture - Property list view
// Top-level hierarchy navigation showing all properties
// ============================================================================

import SwiftUI
import SwiftData

/// Displays list of all properties with navigation to rooms
struct PropertyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Property.sortOrder) private var properties: [Property]
    
    @State private var showingAddProperty = false
    @State private var editingProperty: Property?
    @State private var propertyToDelete: Property?
    @State private var showingDeleteConfirmation = false
    @State private var renamingProperty: Property?
    @State private var renameText: String = ""
    
    var body: some View {
        List {
            if properties.isEmpty {
                emptyStateSection
            } else {
                propertiesSection
            }
        }
        .navigationTitle("Properties")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddProperty = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Property")
            }
        }
        .sheet(isPresented: $showingAddProperty) {
            PropertyEditorSheet(mode: .add)
        }
        .sheet(item: $editingProperty) { property in
            PropertyEditorSheet(mode: .edit(property))
        }
        .confirmationDialog(
            "Delete Property?",
            isPresented: $showingDeleteConfirmation,
            presenting: propertyToDelete
        ) { property in
            Button("Delete \"\(property.name)\"", role: .destructive) {
                deleteProperty(property)
            }
        } message: { property in
            Text("This will delete all rooms and items in this property. This action cannot be undone.")
        }
        .alert("Rename Property", isPresented: .init(
            get: { renamingProperty != nil },
            set: { if !$0 { renamingProperty = nil } }
        )) {
            TextField("Property Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renamingProperty = nil
            }
            Button("Rename") {
                if let property = renamingProperty {
                    renameProperty(property, to: renameText)
                }
            }
        } message: {
            Text("Enter a new name for this property.")
        }
        .onAppear {
            ensureDefaultPropertyExists()
        }
    }
    
    // MARK: - Properties Section
    
    private var propertiesSection: some View {
        ForEach(properties) { property in
            NavigationLink(destination: PropertyDetailView(property: property)) {
                PropertyRowView(property: property)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    propertyToDelete = property
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    editingProperty = property
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    renameText = property.name
                    renamingProperty = property
                } label: {
                    Label("Rename", systemImage: "character.cursor.ibeam")
                }
                .tint(.blue)
            }
        }
        .onMove(perform: moveProperties)
    }
    
    // MARK: - Empty State
    
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                Image(systemName: "house.fill")
                    .font(.system(size: NestoryTheme.Metrics.iconXLarge))
                    .foregroundStyle(NestoryTheme.Colors.muted)

                Text("No Properties Yet")
                    .font(NestoryTheme.Typography.headline)

                Text("Add your first property to start organizing your inventory by location.")
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .multilineTextAlignment(.center)

                Button(action: { showingAddProperty = true }) {
                    Label("Add Property", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NestoryTheme.Metrics.spacingXXLarge)
        }
    }
    
    // MARK: - Actions
    
    private func ensureDefaultPropertyExists() {
        guard properties.isEmpty else { return }
        _ = Property.createDefault(in: modelContext)
        try? modelContext.save()
    }
    
    private func moveProperties(from source: IndexSet, to destination: Int) {
        var orderedProperties = properties
        orderedProperties.move(fromOffsets: source, toOffset: destination)
        for (index, property) in orderedProperties.enumerated() {
            property.sortOrder = index
        }
    }
    
    private func deleteProperty(_ property: Property) {
        modelContext.delete(property)
    }

    private func renameProperty(_ property: Property, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        property.name = trimmedName
        property.updatedAt = Date()
        renamingProperty = nil
    }
}

// MARK: - Property Row View

struct PropertyRowView: View {
    let property: Property

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Icon
            Image(systemName: property.iconName)
                .font(.title2)
                .foregroundStyle(Color(hex: property.colorHex) ?? NestoryTheme.Colors.accent)
                .frame(width: NestoryTheme.Metrics.thumbnailSmall + 4, height: NestoryTheme.Metrics.thumbnailSmall + 4)
                .background(Color(hex: property.colorHex)?.opacity(0.1) ?? NestoryTheme.Colors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))

            // Info
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                HStack {
                    Text(property.name)
                        .font(NestoryTheme.Typography.headline)

                    if property.isDefault {
                        Text("Default")
                            .font(NestoryTheme.Typography.caption2)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                            .padding(.horizontal, NestoryTheme.Metrics.paddingSmall - 2)
                            .padding(.vertical, 2)
                            .background(NestoryTheme.Colors.chipBackground)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                    Label("\(property.rooms.count) rooms", systemImage: "door.left.hand.closed")
                    Label("\(property.totalItemCount) items", systemImage: "archivebox.fill")
                }
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
            }

            Spacer()
        }
        .padding(.vertical, NestoryTheme.Metrics.paddingXSmall)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PropertyListView()
    }
    .modelContainer(for: [Property.self, Room.self, Item.self], inMemory: true)
}

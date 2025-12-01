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
        }
        .onMove(perform: moveProperties)
    }
    
    // MARK: - Empty State
    
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No Properties Yet")
                    .font(.headline)
                
                Text("Add your first property to start organizing your inventory by location.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { showingAddProperty = true }) {
                    Label("Add Property", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
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
}

// MARK: - Property Row View

struct PropertyRowView: View {
    let property: Property
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: property.iconName)
                .font(.title2)
                .foregroundStyle(Color(hex: property.colorHex) ?? .blue)
                .frame(width: 44, height: 44)
                .background(Color(hex: property.colorHex)?.opacity(0.1) ?? Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(property.name)
                        .font(.headline)
                    
                    if property.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    Label("\(property.rooms.count) rooms", systemImage: "door.left.hand.closed")
                    Label("\(property.totalItemCount) items", systemImage: "archivebox.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PropertyListView()
    }
    .modelContainer(for: [Property.self, Room.self, Item.self], inMemory: true)
}

//
//  ItemDetailView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    
    @State private var viewModel: ItemDetailViewModel
    
    init(item: Item) {
        self.item = item
        _viewModel = State(initialValue: ItemDetailViewModel(item: item))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Photo Header
                photoHeaderSection
                
                VStack(spacing: 20) {
                    // Title & Location
                    titleSection
                    
                    // Documentation Status
                    documentationSection
                    
                    // Basic Info
                    basicInfoSection
                    
                    // Receipts
                    receiptsSection
                    
                    // Warranty
                    warrantySection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: viewModel.showEditSheet) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: viewModel.showAddPhoto) {
                        Label("Add Photo", systemImage: "camera")
                    }
                    Button(action: viewModel.showAddReceipt) {
                        Label("Add Receipt", systemImage: "doc.text")
                    }
                    Divider()
                    Button(role: .destructive, action: viewModel.showDeleteConfirmation) {
                        Label("Delete Item", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            EditItemView(item: item)
        }
        .confirmationDialog("Delete Item?", isPresented: $viewModel.showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.deleteItem(modelContext: modelContext, dismiss: dismiss)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(item.name)\" and all associated photos and data.")
        }
        .safeAreaInset(edge: .bottom) {
            quickActionsBar
        }
    }
    
    // MARK: - Photo Header
    private var photoHeaderSection: some View {
        ZStack {
            Rectangle()
                .fill(Color(.tertiarySystemGroupedBackground))
            
            if item.photos.isEmpty {
                VStack(spacing: 12) {
                    if let category = item.category {
                        Image(systemName: category.iconName)
                            .font(.system(size: 60))
                            .foregroundStyle(Color(hex: category.colorHex) ?? .secondary)
                    } else {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("No photos yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button(action: viewModel.showAddPhoto) {
                        Label("Add Photo", systemImage: "camera")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // TODO: Photo carousel when photos exist
                Text("Photo Carousel")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 250)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.title)
                .fontWeight(.bold)
            
            if let brandModel = viewModel.brandModelText(brand: item.brand, modelNumber: item.modelNumber) {
                Text(brandModel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Category & Room pills
            HStack(spacing: 8) {
                if let category = item.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.iconName)
                            .font(.caption)
                        Text(category.name)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: category.colorHex)?.opacity(0.15) ?? Color.secondary.opacity(0.1))
                    .foregroundStyle(Color(hex: category.colorHex) ?? .secondary)
                    .clipShape(Capsule())
                }
                
                if let room = item.room {
                    HStack(spacing: 4) {
                        Image(systemName: room.iconName)
                            .font(.caption)
                        Text(room.name)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Documentation Section
    private var documentationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documentation Status")
                .font(.headline)
            
            HStack(spacing: 8) {
                DocumentationBadge("Photo", isComplete: item.hasPhoto)
                DocumentationBadge("Value", isComplete: item.hasValue)
                DocumentationBadge("Receipt", isComplete: item.hasReceipt)
                DocumentationBadge("Serial", isComplete: item.hasSerial)
            }
            
            if !item.missingDocumentation.isEmpty {
                Text("Missing: \(item.missingDocumentation.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            VStack(spacing: 0) {
                if let price = item.purchasePrice {
                    infoRow(label: "Purchase Price", value: env.settings.formatCurrency(price))
                }
                
                if let date = item.purchaseDate {
                    infoRow(label: "Purchase Date", value: date.formatted(date: .long, time: .omitted))
                }
                
                if let serial = item.serialNumber, !serial.isEmpty {
                    infoRow(label: "Serial Number", value: serial, canCopy: true)
                }
                
                infoRow(label: "Condition", value: item.condition.displayName)
                
                if let notes = item.conditionNotes, !notes.isEmpty {
                    infoRow(label: "Condition Notes", value: notes)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func infoRow(label: String, value: String, canCopy: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            if canCopy {
                Button(action: {
                    viewModel.copyToClipboard(value)
                }) {
                    HStack(spacing: 4) {
                        Text(value)
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(value)
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Receipts Section
    private var receiptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Receipts")
                    .font(.headline)
                Spacer()
                Button(action: viewModel.showAddReceipt) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.accentColor)
                }
            }
            
            if item.receipts.isEmpty {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    Text("No receipts linked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Add Receipt") {
                        viewModel.showAddReceipt()
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(item.receipts) { receipt in
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(Color.accentColor)
                        VStack(alignment: .leading) {
                            Text(receipt.vendor ?? "Unknown Vendor")
                                .font(.subheadline)
                            if let total = receipt.total {
                                Text(env.settings.formatCurrency(total))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let date = receipt.purchaseDate {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Warranty Section
    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Warranty")
                .font(.headline)
            
            if let expiryDate = item.warrantyExpiryDate {
                let isExpired = viewModel.isWarrantyExpired(expiryDate: expiryDate)
                HStack {
                    Image(systemName: isExpired ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                        .foregroundStyle(isExpired ? .red : .green)
                    VStack(alignment: .leading) {
                        Text(isExpired ? "Warranty Expired" : "Warranty Active")
                            .font(.subheadline)
                        Text("Expires: \(expiryDate.formatted(date: .long, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "shield")
                        .foregroundStyle(.secondary)
                    Text("No warranty information")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Add") {
                        viewModel.showEditSheet()
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Quick Actions Bar
    private var quickActionsBar: some View {
        HStack(spacing: 16) {
            Button(action: viewModel.showEditSheet) {
                VStack(spacing: 4) {
                    Image(systemName: "pencil")
                    Text("Edit")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button(action: viewModel.showAddPhoto) {
                VStack(spacing: 4) {
                    Image(systemName: "camera")
                    Text("Photo")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button(action: viewModel.showAddReceipt) {
                VStack(spacing: 4) {
                    Image(systemName: "doc.text")
                    Text("Receipt")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "doc.badge.plus")
                    Text("Report")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(item: Item(
            name: "MacBook Pro 16\"",
            brand: "Apple",
            modelNumber: "A2485",
            serialNumber: "C02XL0GTMD6M",
            purchasePrice: 2499.00,
            purchaseDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
            condition: .likeNew
        ))
    }
    .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
}

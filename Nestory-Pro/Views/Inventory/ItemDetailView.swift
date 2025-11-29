//
//  ItemDetailView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: ITEM DETAIL VIEW
// ============================================================================
// Task 2.3.1: Implement ItemDetail layout per spec
//
// SPEC REQUIREMENTS (PRODUCT-SPEC.md):
// 1. Header: Photo carousel (pager) + name/brand + room/category pills
// 2. Basic Info: Purchase price/date, serial, condition
// 3. Documentation Status: 6-field badges + "What's missing?" sheet
// 4. Receipts Section: Thumbnail list with vendor/date/amount
// 5. Warranty Info: Expiry date, text note
// 6. Quick Actions: Edit, Add Photo, Add Receipt, Add to Report
//
// DESIGN TOKENS:
// - Corner radius: 12pt for cards
// - Spacing: 16pt between sections, 8pt internal
// - Photo header: ~40% of screen height
// ============================================================================

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    @State private var viewModel: ItemDetailViewModel
    @State private var selectedPhotoIndex = 0
    @State private var showingDocumentationInfo = false

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
    
    // MARK: - Photo Header (~40% of screen)
    private var photoHeaderSection: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color(.tertiarySystemGroupedBackground))

                if item.photos.isEmpty {
                    emptyPhotoPlaceholder
                } else {
                    photoCarousel
                }
            }
            .frame(height: geometry.size.height)
        }
        .frame(idealHeight: 300)
        .frame(maxHeight: 400)
    }

    private var emptyPhotoPlaceholder: some View {
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
    }

    private var photoCarousel: some View {
        TabView(selection: $selectedPhotoIndex) {
            ForEach(Array(sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                photoView(for: photo)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: sortedPhotos.count > 1 ? .automatic : .never))
        .overlay(alignment: .topTrailing) {
            if sortedPhotos.count > 1 {
                Text("\(selectedPhotoIndex + 1)/\(sortedPhotos.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(12)
            }
        }
    }

    private var sortedPhotos: [ItemPhoto] {
        item.photos.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func photoView(for photo: ItemPhoto) -> some View {
        PhotoThumbnailView(identifier: photo.imageIdentifier, photoStorage: env.photoStorage)
    }
}

// MARK: - Photo Thumbnail View (async loading)
private struct PhotoThumbnailView: View {
    let identifier: String
    let photoStorage: any PhotoStorageProtocol

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else if isLoading {
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
            } else {
                // Error state
                ZStack {
                    Color(.systemGray5)
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Unable to load")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            await loadPhoto()
        }
    }

    private func loadPhoto() async {
        do {
            image = try await photoStorage.loadPhoto(identifier: identifier)
        } catch {
            // Photo not found or error loading
        }
        isLoading = false
    }
}

// MARK: - ItemDetailView Sections
extension ItemDetailView {
    // MARK: - Title Section
    var titleSection: some View {
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
    
    // MARK: - Documentation Section (6-field scoring per Task 1.4.1)
    private var documentationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Documentation Status")
                    .font(.headline)
                Spacer()

                // Documentation score percentage
                Text("\(Int(item.documentationScore * 100))%")
                    .font(.headline)
                    .foregroundStyle(documentationScoreColor)

                // "What's missing?" info button
                Button(action: { showingDocumentationInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(documentationScoreColor)
                        .frame(width: geometry.size.width * item.documentationScore, height: 8)
                }
            }
            .frame(height: 8)

            // 6-field badges in two rows
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    DocumentationBadge("Photo", isComplete: item.hasPhoto, weight: "30%")
                    DocumentationBadge("Value", isComplete: item.hasValue, weight: "25%")
                    DocumentationBadge("Room", isComplete: item.hasLocation, weight: "15%")
                }
                HStack(spacing: 8) {
                    DocumentationBadge("Category", isComplete: item.hasCategory, weight: "10%")
                    DocumentationBadge("Receipt", isComplete: item.hasReceipt, weight: "10%")
                    DocumentationBadge("Serial", isComplete: item.hasSerial, weight: "10%")
                }
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
        .sheet(isPresented: $showingDocumentationInfo) {
            documentationInfoSheet
        }
    }

    private var documentationScoreColor: Color {
        switch item.documentationScore {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }

    private var documentationInfoSheet: some View {
        NavigationStack {
            List {
                Section {
                    Text("Your documentation score shows how well-prepared you are for an insurance claim. A higher score means faster, smoother claims processing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Field Weights") {
                    documentationInfoRow(field: "Photo", weight: 30, description: "Visual proof of ownership and condition")
                    documentationInfoRow(field: "Value", weight: 25, description: "Purchase price for claim valuation")
                    documentationInfoRow(field: "Room", weight: 15, description: "Location helps organize and verify items")
                    documentationInfoRow(field: "Category", weight: 10, description: "Type classification for proper coverage")
                    documentationInfoRow(field: "Receipt", weight: 10, description: "Proof of purchase for claims")
                    documentationInfoRow(field: "Serial Number", weight: 10, description: "Unique identifier for high-value items")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(.green).frame(width: 12, height: 12)
                            Text("80%+ — Excellent")
                        }
                        HStack {
                            Circle().fill(.orange).frame(width: 12, height: 12)
                            Text("50-79% — Needs improvement")
                        }
                        HStack {
                            Circle().fill(.red).frame(width: 12, height: 12)
                            Text("Below 50% — Incomplete")
                        }
                    }
                    .font(.subheadline)
                } header: {
                    Text("Score Thresholds")
                }
            }
            .navigationTitle("Documentation Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingDocumentationInfo = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func documentationInfoRow(field: String, weight: Int, description: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(field)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(weight)%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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
                
                if let barcode = item.barcode, !barcode.isEmpty {
                    infoRow(label: "Barcode", value: barcode, canCopy: true)
                }
                
                infoRow(label: "Condition", value: item.condition.displayName)
                
                if let notes = item.conditionNotes, !notes.isEmpty {
                    infoRow(label: "Condition Notes", value: notes)
                }
                
                if let notes = item.notes, !notes.isEmpty {
                    infoRow(label: "Notes", value: notes)
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

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
    @State private var showingTagEditor = false

    // F4: Market Value Lookup state
    @State private var isCheckingValue = false
    @State private var valueLookupError: String?

    init(item: Item) {
        self.item = item
        _viewModel = State(initialValue: ItemDetailViewModel(item: item))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Photo Header
                photoHeaderSection

                VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                    // Title & Location
                    titleSection

                    // Tags (P2-05)
                    tagsSection

                    // Documentation Status
                    documentationSection

                    // Basic Info
                    basicInfoSection

                    // Market Value (F4)
                    marketValueSection

                    // Receipts
                    receiptsSection

                    // Warranty
                    warrantySection
                }
                .padding(NestoryTheme.Metrics.paddingMedium)
            }
        }
        .background(NestoryTheme.Colors.background)
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
                .accessibilityLabel("Item actions")
                .accessibilityHint("Double tap for edit, add photo, add receipt, or delete options")
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
        VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            if let category = item.category {
                Image(systemName: category.iconName)
                    .font(.system(size: NestoryTheme.Metrics.iconHero))
                    .foregroundStyle(Color(hex: category.colorHex) ?? NestoryTheme.Colors.muted)
            } else {
                Image(systemName: "cube.fill")
                    .font(.system(size: NestoryTheme.Metrics.iconHero))
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }

            Text("No photos yet")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)

            Button(action: viewModel.showAddPhoto) {
                Label("Add Photo", systemImage: "camera")
                    .font(NestoryTheme.Typography.subheadline)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Photo Carousel (P2-10-1)
    private var photoCarousel: some View {
        ZStack(alignment: .bottom) {
            // Photo pager
            TabView(selection: $selectedPhotoIndex) {
                ForEach(Array(sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                    photoView(for: photo)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: sortedPhotos.count > 1 ? .automatic : .never))

            // Gradient overlay with item name (P2-10-1)
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)

            // Overlaid name and brand (P2-10-1)
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text(item.name)
                    .font(NestoryTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)

                if let brandModel = viewModel.brandModelText(brand: item.brand, modelNumber: item.modelNumber) {
                    Text(brandModel)
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(radius: 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(NestoryTheme.Metrics.paddingMedium)
        }
        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusXLarge))
        .overlay(alignment: .topTrailing) {
            // Photo counter badge
            if sortedPhotos.count > 1 {
                Text("\(selectedPhotoIndex + 1)/\(sortedPhotos.count)")
                    .font(NestoryTheme.Typography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, NestoryTheme.Metrics.paddingSmall)
                    .padding(.vertical, NestoryTheme.Metrics.paddingXSmall)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(NestoryTheme.Metrics.paddingMedium)
            }
        }
        // Accessibility (P2-10-1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Photo \(selectedPhotoIndex + 1) of \(sortedPhotos.count). \(item.name)")
        .accessibilityHint("Swipe left or right to view other photos")
    }

    private var sortedPhotos: [ItemPhoto] {
        item.photos.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func photoView(for photo: ItemPhoto) -> some View {
        PhotoThumbnailView(identifier: photo.imageIdentifier, photoStorage: env.photoStorage)
    }
}

// MARK: - Pro Badge View (F4)
private struct ProBadgeView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
            Text("PRO")
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(NestoryTheme.Colors.accent)
        .clipShape(Capsule())
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
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
            Text(item.name)
                .font(NestoryTheme.Typography.title)

            if let brandModel = viewModel.brandModelText(brand: item.brand, modelNumber: item.modelNumber) {
                Text(brandModel)
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }

            // Category & Room pills
            HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                if let category = item.category {
                    HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                        Image(systemName: category.iconName)
                            .font(NestoryTheme.Typography.caption)
                        Text(category.name)
                            .font(NestoryTheme.Typography.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: category.colorHex)?.opacity(0.15) ?? NestoryTheme.Colors.muted.opacity(0.1))
                    .foregroundStyle(Color(hex: category.colorHex) ?? NestoryTheme.Colors.muted)
                    .clipShape(Capsule())
                }

                if let room = item.room {
                    HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                        Image(systemName: room.iconName)
                            .font(NestoryTheme.Typography.caption)
                        Text(room.name)
                            .font(NestoryTheme.Typography.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(NestoryTheme.Colors.muted.opacity(0.1))
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Tags Section (P2-05)
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
            HStack {
                Text("Tags")
                    .font(NestoryTheme.Typography.headline)
                Spacer()
                Button {
                    showingTagEditor = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(NestoryTheme.Colors.accent)
                }
                .accessibilityLabel("Add tags")
            }

            if item.tagObjects.isEmpty {
                Text("No tags")
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            } else {
                TagFlowView(tags: item.tagObjects) { tag in
                    item.tagObjects.removeAll { $0.id == tag.id }
                    item.updatedAt = Date()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showingTagEditor) {
            TagEditorSheet(item: item)
        }
    }
    
    // MARK: - Documentation Section (6-field scoring per Task 1.4.1)
    private var documentationSection: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
            HStack {
                Text("Documentation Status")
                    .font(NestoryTheme.Typography.headline)
                Spacer()

                // Documentation score percentage with status text
                HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                    Text("\(Int(item.documentationScore * 100))%")
                        .font(NestoryTheme.Typography.headline)
                        .foregroundStyle(documentationScoreColor)
                    Text("•")
                        .foregroundStyle(NestoryTheme.Colors.muted)
                    Text(documentationStatusText)
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(documentationScoreColor)
                }

                // "What's missing?" info button
                Button(action: { showingDocumentationInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
                .accessibilityLabel("Documentation score info")
                .accessibilityHint("Double tap to learn about documentation score weights")
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall)
                        .fill(NestoryTheme.Colors.cardBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall)
                        .fill(documentationScoreColor)
                        .frame(width: geometry.size.width * item.documentationScore, height: 8)
                }
            }
            .frame(height: 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Documentation progress")
            .accessibilityValue("\(Int(item.documentationScore * 100)) percent, \(documentationStatusText)")

            // 6-field badges in two rows
            VStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                    DocumentationBadge("Photo", isComplete: item.hasPhoto, weight: "30%")
                    DocumentationBadge("Value", isComplete: item.hasValue, weight: "25%")
                    DocumentationBadge("Room", isComplete: item.hasLocation, weight: "15%")
                }
                HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                    DocumentationBadge("Category", isComplete: item.hasCategory, weight: "10%")
                    DocumentationBadge("Receipt", isComplete: item.hasReceipt, weight: "10%")
                    DocumentationBadge("Serial", isComplete: item.hasSerial, weight: "10%")
                }
            }

            if !item.missingDocumentation.isEmpty {
                Text("Missing: \(item.missingDocumentation.joined(separator: ", "))")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .sheet(isPresented: $showingDocumentationInfo) {
            documentationInfoSheet
        }
    }
    
    private var documentationStatusText: String {
        switch item.documentationScore {
        case 0.8...1.0:
            return "Excellent"
        case 0.5..<0.8:
            return "Needs Work"
        default:
            return "Incomplete"
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
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
            Text("Details")
                .font(NestoryTheme.Typography.headline)

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Market Value Section (F4)
    private var marketValueSection: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
            HStack {
                Text("Market Value")
                    .font(NestoryTheme.Typography.headline)
                Spacer()

                // Pro badge if needed
                if !env.settings.isProUnlocked {
                    ProBadgeView()
                }
            }

            if let estimatedValue = item.estimatedReplacementValue {
                // Show existing value estimate
                VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                    // Main value
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(NestoryTheme.Colors.success)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Estimated Value")
                                .font(NestoryTheme.Typography.caption)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                            Text(env.settings.formatCurrency(estimatedValue))
                                .font(NestoryTheme.Typography.title2)
                                .fontWeight(.semibold)
                        }
                    }

                    // Price range
                    if let lowValue = item.estimatedValueLow, let highValue = item.estimatedValueHigh {
                        HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                            Text("Range:")
                                .font(NestoryTheme.Typography.caption)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                            Text("\(env.settings.formatCurrency(lowValue)) – \(env.settings.formatCurrency(highValue))")
                                .font(NestoryTheme.Typography.subheadline)
                        }
                    }

                    // Source and date
                    HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                        if let source = item.valueLookupSource {
                            Text("Source: \(source)")
                                .font(NestoryTheme.Typography.caption)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                        }

                        if let lookupDate = item.valueLookupDate {
                            Text("•")
                                .foregroundStyle(NestoryTheme.Colors.muted)
                            if let days = item.daysSinceValueLookup {
                                Text(days == 0 ? "Updated today" : "Updated \(days) days ago")
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.muted)
                            }
                        }
                    }

                    // Refresh button
                    Button(action: checkMarketValue) {
                        HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                            if isCheckingValue {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh Value")
                        }
                        .font(NestoryTheme.Typography.subheadline)
                    }
                    .disabled(isCheckingValue || !env.settings.isProUnlocked)
                    .padding(.top, NestoryTheme.Metrics.spacingSmall)
                }
            } else {
                // No value yet - show check button
                VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(NestoryTheme.Colors.muted)
                        Text("Get market-based price estimate")
                            .font(NestoryTheme.Typography.subheadline)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }

                    Button(action: checkMarketValue) {
                        HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                            if isCheckingValue {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text("Check Value")
                        }
                        .font(NestoryTheme.Typography.buttonLabel)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCheckingValue || !env.settings.isProUnlocked)
                }
            }

            // Error message
            if let error = valueLookupError {
                Text(error)
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    /// Check market value for this item
    private func checkMarketValue() {
        guard env.settings.isProUnlocked else {
            valueLookupError = "Market value lookup requires Nestory Pro"
            return
        }

        isCheckingValue = true
        valueLookupError = nil

        Task {
            do {
                let result = try await env.valueLookupService.lookupValue(
                    name: item.name,
                    brand: item.brand,
                    category: item.category?.name,
                    condition: item.condition
                )

                // Update item with results
                await MainActor.run {
                    item.estimatedReplacementValue = result.estimatedValue
                    item.estimatedValueLow = result.lowValue
                    item.estimatedValueHigh = result.highValue
                    item.valueLookupSource = result.source
                    item.valueLookupDate = result.lookupDate
                    item.updatedAt = Date()
                    isCheckingValue = false
                    NestoryTheme.Haptics.success()
                }
            } catch {
                await MainActor.run {
                    valueLookupError = error.localizedDescription
                    isCheckingValue = false
                    NestoryTheme.Haptics.error()
                }
            }
        }
    }

    private func infoRow(label: String, value: String, canCopy: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(NestoryTheme.Colors.muted)
            Spacer()
            if canCopy {
                Button(action: {
                    viewModel.copyToClipboard(value)
                }) {
                    HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                        Text(value)
                        Image(systemName: "doc.on.doc")
                            .font(NestoryTheme.Typography.caption)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(value)
            }
        }
        .padding(.vertical, NestoryTheme.Metrics.spacingSmall)
    }
    
    // MARK: - Receipts Section
    private var receiptsSection: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
            HStack {
                Text("Receipts")
                    .font(NestoryTheme.Typography.headline)
                Spacer()
                Button(action: viewModel.showAddReceipt) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(NestoryTheme.Colors.accent)
                }
            }

            if item.receipts.isEmpty {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(NestoryTheme.Colors.muted)
                    Text("No receipts linked")
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                    Spacer()
                    Button("Add Receipt") {
                        viewModel.showAddReceipt()
                    }
                    .font(NestoryTheme.Typography.subheadline)
                }
                .padding(.vertical, NestoryTheme.Metrics.spacingSmall)
            } else {
                ForEach(item.receipts) { receipt in
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(NestoryTheme.Colors.accent)
                        VStack(alignment: .leading) {
                            Text(receipt.vendor ?? "Unknown Vendor")
                                .font(NestoryTheme.Typography.subheadline)
                            if let total = receipt.total {
                                Text(env.settings.formatCurrency(total))
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.muted)
                            }
                        }
                        Spacer()
                        if let date = receipt.purchaseDate {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(NestoryTheme.Typography.caption)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                        }
                    }
                    .padding(.vertical, NestoryTheme.Metrics.spacingXSmall)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Warranty Section
    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
            Text("Warranty")
                .font(NestoryTheme.Typography.headline)

            if let expiryDate = item.warrantyExpiryDate {
                let isExpired = viewModel.isWarrantyExpired(expiryDate: expiryDate)
                HStack {
                    Image(systemName: isExpired ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                        .foregroundStyle(isExpired ? NestoryTheme.Colors.error : NestoryTheme.Colors.success)
                    VStack(alignment: .leading) {
                        Text(isExpired ? "Warranty Expired" : "Warranty Active")
                            .font(NestoryTheme.Typography.subheadline)
                        Text("Expires: \(expiryDate.formatted(date: .long, time: .omitted))")
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "shield")
                        .foregroundStyle(NestoryTheme.Colors.muted)
                    Text("No warranty information")
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                    Spacer()
                    Button("Add") {
                        viewModel.showEditSheet()
                    }
                    .font(NestoryTheme.Typography.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Quick Actions Bar
    private var quickActionsBar: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            Button(action: viewModel.showEditSheet) {
                VStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                    Image(systemName: "pencil")
                    Text("Edit")
                        .font(NestoryTheme.Typography.caption)
                }
            }
            .accessibilityLabel("Edit item")
            .accessibilityHint("Double tap to edit item details")

            Spacer()

            Button(action: viewModel.showAddPhoto) {
                VStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                    Image(systemName: "camera")
                    Text("Photo")
                        .font(NestoryTheme.Typography.caption)
                }
            }
            .accessibilityLabel("Add photo")
            .accessibilityHint("Double tap to add a photo to this item")

            Spacer()

            Button(action: viewModel.showAddReceipt) {
                VStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                    Image(systemName: "doc.text")
                    Text("Receipt")
                        .font(NestoryTheme.Typography.caption)
                }
            }
            .accessibilityLabel("Add receipt")
            .accessibilityHint("Double tap to add a receipt to this item")

            Spacer()

            Button(action: {}) {
                VStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                    Image(systemName: "doc.badge.plus")
                    Text("Report")
                        .font(NestoryTheme.Typography.caption)
                }
            }
            .accessibilityLabel("Add to report")
            .accessibilityHint("Double tap to include this item in a report")
        }
        .padding(NestoryTheme.Metrics.paddingMedium)
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

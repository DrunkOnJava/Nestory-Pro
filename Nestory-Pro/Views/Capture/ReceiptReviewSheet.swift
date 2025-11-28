//
//  ReceiptReviewSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: RECEIPT REVIEW SHEET
// ============================================================================
// Task 2.3.4: Post-OCR review and edit sheet for receipt data
//
// PURPOSE:
// - Display OCR-extracted receipt data with confidence indicators
// - Allow manual editing of extracted fields (vendor, total, tax, date)
// - Option to link receipt to existing item or create new item
// - Save Receipt model to SwiftData on confirmation
//
// CONFIDENCE BADGES:
// - Green: >= 0.8 (high confidence)
// - Yellow: >= 0.5 (medium confidence)
// - Red: < 0.5 (low confidence, review recommended)
//
// ARCHITECTURE:
// - Pure SwiftUI view with @Environment for SwiftData context
// - Accepts ReceiptData from OCR service as input
// - Creates Receipt model linked to optional Item
// - Dismisses automatically on save
//
// FUTURE ENHANCEMENTS:
// - Task 2.3.5: Auto-create new item with receipt data pre-filled
// - Task 4.1.1: Add Pro unlock check for unlimited receipts
// - Task 7.1.x: Add accessibility labels
//
// SEE: TODO.md Task 2.3.4 | OCRService.swift | Receipt.swift
// ============================================================================

import SwiftUI
import SwiftData

struct ReceiptReviewSheet: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries

    @Query(sort: \Item.name) private var items: [Item]

    // MARK: - Dependencies

    /// OCR-extracted receipt data to review
    let receiptData: ReceiptData

    /// Image identifier for the receipt photo
    let imageIdentifier: String

    /// Settings for currency formatting
    private let settings = SettingsManager.shared

    // MARK: - State

    @State private var vendor: String
    @State private var totalAmount: String
    @State private var taxAmount: String
    @State private var purchaseDate: Date
    @State private var selectedItem: Item?
    @State private var linkToItem: Bool = false

    @State private var isSaving: Bool = false
    @State private var saveError: Error?
    @State private var showingError: Bool = false

    // MARK: - Computed Properties

    /// Enable save when at least one field has data
    private var canSave: Bool {
        !isSaving && (!vendor.isEmpty || !totalAmount.isEmpty)
    }

    /// Parsed decimal from total amount string
    private var parsedTotal: Decimal? {
        let cleaned = totalAmount.replacingOccurrences(of: settings.currencySymbol, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned)
    }

    /// Parsed decimal from tax amount string
    private var parsedTax: Decimal? {
        let cleaned = taxAmount.replacingOccurrences(of: settings.currencySymbol, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned)
    }

    // MARK: - Initialization

    init(receiptData: ReceiptData, imageIdentifier: String) {
        self.receiptData = receiptData
        self.imageIdentifier = imageIdentifier

        // Initialize state from OCR data
        _vendor = State(initialValue: receiptData.vendor ?? "")
        _totalAmount = State(initialValue: receiptData.total.map { String(describing: $0) } ?? "")
        _taxAmount = State(initialValue: receiptData.taxAmount.map { String(describing: $0) } ?? "")
        _purchaseDate = State(initialValue: receiptData.purchaseDate ?? Date())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Receipt Fields Section
                receiptFieldsSection

                // Item Linking Section
                itemLinkingSection

                // Raw OCR Text (for debugging/review)
                rawTextSection
            }
            .navigationTitle("Review Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveReceipt()
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Save Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let saveError {
                    Text(saveError.localizedDescription)
                }
            }
        }
    }

    // MARK: - View Components

    private var receiptFieldsSection: some View {
        Section {
            // Vendor
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Vendor")
                            .font(.subheadline)
                        confidenceBadge(for: receiptData.vendor != nil ? receiptData.confidence : 0.0)
                    }
                    TextField("Store name", text: $vendor)
                        .textInputAutocapitalization(.words)
                }
            }

            // Total
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Total")
                            .font(.subheadline)
                        confidenceBadge(for: receiptData.total != nil ? receiptData.confidence : 0.0)
                    }
                    TextField("0.00", text: $totalAmount)
                        .keyboardType(.decimalPad)
                }
            }

            // Tax
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Tax")
                            .font(.subheadline)
                        confidenceBadge(for: receiptData.taxAmount != nil ? receiptData.confidence : 0.0)
                    }
                    TextField("0.00", text: $taxAmount)
                        .keyboardType(.decimalPad)
                }
            }

            // Date
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Purchase Date")
                        .font(.subheadline)
                    confidenceBadge(for: receiptData.purchaseDate != nil ? receiptData.confidence : 0.0)
                }
                DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

        } header: {
            Text("Receipt Details")
        } footer: {
            Text("Review and edit the extracted information. Fields marked with low confidence may need correction.")
                .font(.caption)
        }
    }

    private var itemLinkingSection: some View {
        Section {
            Toggle("Link to Item", isOn: $linkToItem)

            if linkToItem {
                Picker("Select Item", selection: $selectedItem) {
                    Text("None").tag(nil as Item?)
                    ForEach(items) { item in
                        Text(item.name).tag(item as Item?)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        } header: {
            Text("Item Association")
        } footer: {
            if linkToItem {
                Text("This receipt will be linked to the selected item and visible in its details.")
                    .font(.caption)
            } else {
                Text("Save as standalone receipt. You can link it to an item later.")
                    .font(.caption)
            }
        }
    }

    private var rawTextSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Recognized Text")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(receiptData.confidence * 100))% confidence")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(receiptData.rawText.isEmpty ? "No text recognized" : receiptData.rawText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(10)
            }
        } header: {
            Text("OCR Output")
        }
    }

    // MARK: - Helper Views

    private func confidenceBadge(for confidence: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor(for: confidence))
                .frame(width: 8, height: 8)
            Text(confidenceLabel(for: confidence))
                .font(.caption2)
                .foregroundStyle(confidenceColor(for: confidence))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(confidenceColor(for: confidence).opacity(0.15))
        )
    }

    private func confidenceColor(for confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }

    private func confidenceLabel(for confidence: Double) -> String {
        if confidence >= 0.8 {
            return "High"
        } else if confidence >= 0.5 {
            return "Medium"
        } else {
            return "Low"
        }
    }

    // MARK: - Actions

    /// Saves the receipt to SwiftData
    @MainActor
    private func saveReceipt() async {
        guard canSave else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // Create Receipt model
            let receipt = Receipt(
                imageIdentifier: imageIdentifier,
                vendor: vendor.isEmpty ? nil : vendor,
                total: parsedTotal,
                taxAmount: parsedTax,
                purchaseDate: purchaseDate,
                rawText: receiptData.rawText,
                confidence: receiptData.confidence
            )

            // Link to item if selected
            if linkToItem, let selectedItem {
                receipt.linkedItem = selectedItem
                selectedItem.receipts.append(receipt)
            }

            // Insert into SwiftData context
            modelContext.insert(receipt)

            // Save context
            try modelContext.save()

            // Dismiss sheet
            dismiss()

        } catch {
            // Handle errors gracefully
            saveError = error
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview("Receipt Review - High Confidence") {
    let receiptData = ReceiptData(
        vendor: "Apple Store",
        total: Decimal(string: "1299.99"),
        taxAmount: Decimal(string: "104.00"),
        purchaseDate: Date(),
        rawText: """
        Apple Store
        123 Main Street
        Purchase Date: 11/28/2025

        MacBook Pro    $1,199.99
        AppleCare+       $100.00

        Subtotal      $1,299.99
        Tax             $104.00
        Total         $1,403.99
        """,
        confidence: 0.92
    )

    return ReceiptReviewSheet(
        receiptData: receiptData,
        imageIdentifier: "test-receipt.jpg"
    )
    .modelContainer(for: [Receipt.self, Item.self], inMemory: true)
}

#Preview("Receipt Review - Low Confidence") {
    let receiptData = ReceiptData(
        vendor: nil,
        total: nil,
        taxAmount: nil,
        purchaseDate: nil,
        rawText: "Unable to clearly read receipt text...",
        confidence: 0.32
    )

    return ReceiptReviewSheet(
        receiptData: receiptData,
        imageIdentifier: "test-receipt-blurry.jpg"
    )
    .modelContainer(for: [Receipt.self, Item.self], inMemory: true)
}

#Preview("Receipt Review - With Items") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Receipt.self, Item.self, configurations: config)

    // Seed with sample items
    let context = container.mainContext
    let item1 = Item(name: "MacBook Pro", purchasePrice: 1299.99)
    let item2 = Item(name: "iPhone 15 Pro", purchasePrice: 999.99)
    let item3 = Item(name: "AirPods Pro", purchasePrice: 249.99)

    context.insert(item1)
    context.insert(item2)
    context.insert(item3)

    let receiptData = ReceiptData(
        vendor: "Apple Store",
        total: Decimal(string: "1299.99"),
        taxAmount: Decimal(string: "104.00"),
        purchaseDate: Date(),
        rawText: "Apple Store receipt text...",
        confidence: 0.85
    )

    return ReceiptReviewSheet(
        receiptData: receiptData,
        imageIdentifier: "test-receipt.jpg"
    )
    .modelContainer(container)
}

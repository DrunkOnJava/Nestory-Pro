//
//  LabelGeneratorView.swift
//  Nestory-Pro
//
//  Created for v1.2 - F2 QR Code Label Generation Feature
//

// ============================================================================
// LABEL GENERATOR VIEW - Task F2
// ============================================================================
// UI for generating and printing QR code labels for inventory items.
//
// FEATURES:
// - Select items to generate labels for
// - Choose label size template (small/medium/large)
// - Preview labels before printing
// - AirPrint integration
// - Batch generation for rooms
//
// SEE: TODO-FEATURES.md F2 | QRCodeService.swift | ReportsTab.swift
// ============================================================================

import SwiftUI
import SwiftData

struct LabelGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    @Query(sort: \Item.name) private var allItems: [Item]
    @Query(sort: \Room.sortOrder) private var rooms: [Room]

    @State private var selectedItems: Set<UUID> = []
    @State private var selectedLabelSize: LabelSize = .medium
    @State private var filterRoom: Room?
    @State private var showingPreview = false
    @State private var generatedLabels: [(item: Item, image: UIImage)] = []
    @State private var isPrinting = false

    private let qrService = QRCodeService.shared

    private var filteredItems: [Item] {
        if let room = filterRoom {
            return allItems.filter { $0.room?.id == room.id }
        }
        return allItems
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Label size picker
                labelSizePicker

                // Room filter
                roomFilter

                Divider()

                // Item selection list
                itemSelectionList
            }
            .navigationTitle("Generate Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        generateLabels()
                    }
                    .disabled(selectedItems.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    selectAllButton
                }
            }
            .sheet(isPresented: $showingPreview) {
                LabelPreviewSheet(
                    labels: generatedLabels,
                    labelSize: selectedLabelSize,
                    onPrint: printLabels
                )
            }
        }
    }

    // MARK: - Label Size Picker

    private var labelSizePicker: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
            Text("Label Size")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)

            Picker("Label Size", selection: $selectedLabelSize) {
                ForEach(LabelSize.allCases) { size in
                    VStack(alignment: .leading) {
                        Text(size.displayName)
                    }
                    .tag(size)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedLabelSize.description)
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
        .padding(.vertical, NestoryTheme.Metrics.spacingMedium)
        .background(NestoryTheme.Colors.cardBackground)
    }

    // MARK: - Room Filter

    private var roomFilter: some View {
        HStack {
            Text("Filter by Room")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)

            Spacer()

            Picker("Room", selection: $filterRoom) {
                Text("All Rooms").tag(nil as Room?)
                ForEach(rooms) { room in
                    Label(room.name, systemImage: room.iconName)
                        .tag(room as Room?)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
        .padding(.vertical, NestoryTheme.Metrics.spacingSmall)
    }

    // MARK: - Item Selection List

    private var itemSelectionList: some View {
        List(filteredItems, selection: $selectedItems) { item in
            ItemSelectionRow(item: item, isSelected: selectedItems.contains(item.id))
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSelection(for: item)
                }
        }
        .listStyle(.plain)
        .overlay {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "qrcode",
                    description: Text("Add items to your inventory to generate labels")
                )
            }
        }
    }

    // MARK: - Select All Button

    private var selectAllButton: some View {
        Button {
            if selectedItems.count == filteredItems.count {
                selectedItems.removeAll()
            } else {
                selectedItems = Set(filteredItems.map(\.id))
            }
        } label: {
            Text(selectedItems.count == filteredItems.count ? "Deselect All" : "Select All")
        }
        .disabled(filteredItems.isEmpty)
    }

    // MARK: - Actions

    private func toggleSelection(for item: Item) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
        NestoryTheme.Haptics.selection()
    }

    private func generateLabels() {
        let itemsToGenerate = filteredItems.filter { selectedItems.contains($0.id) }
        generatedLabels = qrService.generateLabels(for: itemsToGenerate, size: selectedLabelSize, settings: env.settings)
        showingPreview = true
        NestoryTheme.Haptics.success()
    }

    private func printLabels() {
        guard !generatedLabels.isEmpty else { return }
        isPrinting = true

        // Create a combined image or PDF for printing
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Nestory Labels"
        printInfo.outputType = .general

        printController.printInfo = printInfo
        printController.printingItems = generatedLabels.map(\.image)

        printController.present(animated: true) { _, completed, error in
            isPrinting = false
            if completed {
                NestoryTheme.Haptics.success()
            } else if let error {
                print("Print error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Item Selection Row

private struct ItemSelectionRow: View {
    let item: Item
    let isSelected: Bool

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? NestoryTheme.Colors.accent : NestoryTheme.Colors.muted)

            // Item info
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text(item.name)
                    .font(NestoryTheme.Typography.body)
                    .foregroundStyle(.primary)

                HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                    if let room = item.room {
                        Label(room.name, systemImage: room.iconName)
                    }
                    if let category = item.category {
                        Label(category.name, systemImage: category.iconName)
                    }
                }
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
            }

            Spacer()
        }
        .padding(.vertical, NestoryTheme.Metrics.spacingXSmall)
    }
}

// MARK: - Label Preview Sheet

private struct LabelPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let labels: [(item: Item, image: UIImage)]
    let labelSize: LabelSize
    let onPrint: () -> Void

    @State private var currentIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                // Preview area
                if !labels.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                            LabelPreviewCard(label: label, size: labelSize)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 300)

                    // Label info
                    Text("\(currentIndex + 1) of \(labels.count)")
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)

                    if labels.count <= 10 {
                        Text(labels[currentIndex].item.name)
                            .font(NestoryTheme.Typography.headline)
                    }
                }

                Spacer()

                // Print button
                Button {
                    onPrint()
                    dismiss()
                } label: {
                    Label("Print Labels", systemImage: "printer.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
            }
            .padding(.top, NestoryTheme.Metrics.spacingLarge)
            .navigationTitle("Preview Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Label Preview Card

private struct LabelPreviewCard: View {
    let label: (item: Item, image: UIImage)
    let size: LabelSize

    var body: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Label image
            Image(uiImage: label.image)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: size.labelWidth * 2, maxHeight: size.labelHeight * 2)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Size indicator
            Text(size.displayName)
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
        }
        .padding(NestoryTheme.Metrics.paddingMedium)
    }
}

// MARK: - Previews

#Preview("Label Generator") {
    LabelGeneratorView()
        .environment(AppEnvironment())
        .modelContainer(for: [Item.self, Room.self], inMemory: true)
}

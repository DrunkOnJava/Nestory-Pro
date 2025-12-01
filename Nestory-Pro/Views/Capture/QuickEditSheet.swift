//
//  QuickEditSheet.swift
//  Nestory-Pro
//
//  F8-05: Quick edit sheet for single pending capture
//

// ============================================================================
// F8-05: QuickEditSheet
// ============================================================================
// Sheet for quickly editing a single pending capture.
// - Name input with keyboard focus
// - Room selector
// - Category selector
// - Optional notes
// - "Save" and "Save & Next" actions
//
// SEE: TODO.md F8-05 | PendingCapture.swift | EditQueueView.swift
// ============================================================================

import SwiftUI

// MARK: - QuickEditSheet

struct QuickEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let capture: PendingCapture
    let rooms: [Room]
    let categories: [Category]
    let onSave: (PendingCapture) -> Void
    let onSaveAndNext: (PendingCapture) -> Void

    // Editable state
    @State private var itemName: String
    @State private var selectedRoomID: UUID?
    @State private var selectedCategoryID: UUID?
    @State private var notes: String

    // UI state
    @FocusState private var isNameFocused: Bool
    @State private var image: UIImage?

    init(
        capture: PendingCapture,
        rooms: [Room],
        categories: [Category],
        onSave: @escaping (PendingCapture) -> Void,
        onSaveAndNext: @escaping (PendingCapture) -> Void
    ) {
        self.capture = capture
        self.rooms = rooms
        self.categories = categories
        self.onSave = onSave
        self.onSaveAndNext = onSaveAndNext

        // Initialize state from capture
        _itemName = State(initialValue: capture.itemName)
        _selectedRoomID = State(initialValue: capture.roomID)
        _selectedCategoryID = State(initialValue: capture.categoryID)
        _notes = State(initialValue: capture.notes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                    // Photo preview
                    photoPreview

                    // Form fields
                    VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                        nameField
                        roomPicker
                        categoryPicker
                        notesField
                    }
                    .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)

                    // Capture info
                    captureInfo
                }
                .padding(.vertical, NestoryTheme.Metrics.paddingMedium)
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task {
                image = await CaptureQueueService.shared.loadPhoto(identifier: capture.photoIdentifier)
            }
            .onAppear {
                // Auto-focus name field after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFocused = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Photo Preview

    private var photoPreview: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))
            } else {
                Rectangle()
                    .fill(NestoryTheme.Colors.cardBackground)
                    .frame(height: 200)
                    .overlay {
                        ProgressView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))
            }
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
    }

    // MARK: - Name Field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
            Text("Item Name")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)

            TextField("Enter item name", text: $itemName)
                .font(NestoryTheme.Typography.body)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
                .submitLabel(.done)
                .accessibilityIdentifier("quickEdit.nameField")
        }
    }

    // MARK: - Room Picker

    private var roomPicker: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
            Text("Room")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)

            Menu {
                Button("None") {
                    selectedRoomID = nil
                }

                Divider()

                ForEach(rooms) { room in
                    Button {
                        selectedRoomID = room.id
                    } label: {
                        HStack {
                            Text(room.name)
                            if selectedRoomID == room.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "door.left.hand.open")
                        .foregroundStyle(NestoryTheme.Colors.accent)

                    Text(selectedRoom?.name ?? "Select Room")
                        .foregroundStyle(selectedRoom != nil ? .primary : NestoryTheme.Colors.muted)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
                .padding(NestoryTheme.Metrics.paddingMedium)
                .background(NestoryTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
            }
            .accessibilityIdentifier("quickEdit.roomPicker")
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
            Text("Category")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)

            Menu {
                Button("None") {
                    selectedCategoryID = nil
                }

                Divider()

                ForEach(categories) { category in
                    Button {
                        selectedCategoryID = category.id
                    } label: {
                        HStack {
                            Image(systemName: category.iconName)
                            Text(category.name)
                            if selectedCategoryID == category.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedCategory?.iconName ?? "tag")
                        .foregroundStyle(NestoryTheme.Colors.accent)

                    Text(selectedCategory?.name ?? "Select Category")
                        .foregroundStyle(selectedCategory != nil ? .primary : NestoryTheme.Colors.muted)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
                .padding(NestoryTheme.Metrics.paddingMedium)
                .background(NestoryTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
            }
            .accessibilityIdentifier("quickEdit.categoryPicker")
        }
    }

    // MARK: - Notes Field

    private var notesField: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
            Text("Notes (Optional)")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)

            TextField("Add notes...", text: $notes, axis: .vertical)
                .font(NestoryTheme.Typography.body)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .accessibilityIdentifier("quickEdit.notesField")
        }
    }

    // MARK: - Capture Info

    private var captureInfo: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundStyle(NestoryTheme.Colors.muted)

            Text("Captured \(capture.capturedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted)
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Save") {
                    saveAndDismiss()
                }

                Button("Save & Next") {
                    saveAndNext()
                }
            } label: {
                Text("Save")
                    .fontWeight(.semibold)
            } primaryAction: {
                saveAndDismiss()
            }
        }
    }

    // MARK: - Helpers

    private var selectedRoom: Room? {
        rooms.first { $0.id == selectedRoomID }
    }

    private var selectedCategory: Category? {
        categories.first { $0.id == selectedCategoryID }
    }

    private func buildUpdatedCapture() -> PendingCapture {
        var updated = capture
        updated.itemName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.roomID = selectedRoomID
        updated.categoryID = selectedCategoryID
        updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return updated
    }

    private func saveAndDismiss() {
        let updated = buildUpdatedCapture()
        onSave(updated)
        HapticManager.success()
        dismiss()
    }

    private func saveAndNext() {
        let updated = buildUpdatedCapture()
        HapticManager.success()
        onSaveAndNext(updated)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Quick Edit Sheet") {
    QuickEditSheet(
        capture: PendingCapture(
            photoIdentifier: "test.jpg",
            itemName: "Test Item"
        ),
        rooms: [],
        categories: [],
        onSave: { _ in },
        onSaveAndNext: { _ in }
    )
}
#endif

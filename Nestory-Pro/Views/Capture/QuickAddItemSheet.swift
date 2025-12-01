//
//  QuickAddItemSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: QUICK ADD ITEM SHEET
// ============================================================================
// Task 2.2.2: Minimal post-capture sheet for quick item creation
//
// PURPOSE:
// - Streamlined UI for adding items immediately after photo capture
// - Only essential fields: name (required) and room (optional)
// - Auto-attaches captured photo to new item
// - Completes photo capture workflow started in PhotoCaptureView
//
// DESIGN RATIONALE:
// - Minimal friction - user just took photo, wants quick save
// - Additional details can be added later in full edit view
// - Follows iOS camera app pattern: capture → quick save → done
//
// ARCHITECTURE:
// - Pure SwiftUI view with @Environment for SwiftData context
// - Uses PhotoStorageService to persist the captured image
// - Creates Item + ItemPhoto in single transaction
// - Dismisses automatically on save
//
// FUTURE ENHANCEMENTS (NOT in v1):
// - Task 4.1.1: Add 100-item limit check before save
// - Task 6.1.2: Pre-select default room from SettingsManager
// - Task 7.1.x: Add accessibility labels
//
// SEE: TODO.md Task 2.2.2 | AddItemView.swift | PhotoCaptureView.swift
// ============================================================================

import SwiftUI
import SwiftData
import UIKit

struct QuickAddItemSheet: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries

    @Query(sort: \Room.sortOrder) private var rooms: [Room]

    // MARK: - Dependencies

    /// The photo to attach to the new item
    let capturedImage: UIImage

    /// Dependencies from environment
    @Environment(AppEnvironment.self) private var env

    // MARK: - State

    @State private var itemName: String = ""
    @State private var selectedRoom: Room?
    @State private var isSaving: Bool = false
    @State private var saveError: Error?
    @State private var showingError: Bool = false

    // MARK: - Computed Properties

    /// Enable save when name is not empty
    private var canSave: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Item Name Section (P2-12-2)
                Section {
                    TextField("Item Name", text: $itemName)
                        .font(NestoryTheme.Typography.body)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                } header: {
                    Label("What did you photograph?", systemImage: "camera.fill")
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                } footer: {
                    Text("You can add more details like price and category later.")
                        .font(NestoryTheme.Typography.caption)
                }

                // Room Selection (P2-12-2)
                Section {
                    Picker("Room", selection: $selectedRoom) {
                        Text("None").tag(nil as Room?)
                        ForEach(rooms) { room in
                            Label(room.name, systemImage: room.iconName)
                                .tag(room as Room?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Label("Location (Optional)", systemImage: "location.fill")
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }

                // Photo Preview (P2-12-2)
                Section {
                    HStack {
                        Spacer()
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
                        Spacer()
                    }
                } header: {
                    Label("Captured Photo", systemImage: "photo.fill")
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }
            .navigationTitle("Add Item")
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
                            await saveItem()
                        }
                    }
                    .disabled(!canSave)
                }
                // Keyboard toolbar (P2-12-2)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
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
        .presentationDetents([.medium, .large]) // P2-12-2: Medium detent for minimal form
        .presentationDragIndicator(.visible)
    }

    // MARK: - Actions (P2-16-1: Haptic feedback)

    /// Saves the item with attached photo to SwiftData
    @MainActor
    private func saveItem() async {
        guard canSave else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // 1. Save photo to disk via PhotoStorageService
            let photoIdentifier = try await env.photoStorage.savePhoto(capturedImage)

            // 2. Create ItemPhoto model
            let itemPhoto = ItemPhoto(
                imageIdentifier: photoIdentifier,
                sortOrder: 0,
                isPrimary: true // First photo is always primary
            )

            // 3. Create Item with minimal required data
            let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
            let newItem = Item(
                name: trimmedName,
                currencyCode: env.settings.preferredCurrencyCode,
                room: selectedRoom
            )

            // 4. Link photo to item
            itemPhoto.item = newItem
            newItem.photos.append(itemPhoto)

            // 5. Insert into SwiftData context
            modelContext.insert(newItem)
            modelContext.insert(itemPhoto)

            // 6. Save context
            try modelContext.save()

            // 7. Success haptic feedback (P2-16-1)
            NestoryTheme.Haptics.success()

            // 8. Dismiss sheet
            dismiss()

        } catch {
            // Handle errors gracefully
            saveError = error
            showingError = true
            NestoryTheme.Haptics.error() // P2-16-2: Error haptic
        }
    }
}

// MARK: - Preview

#Preview("Quick Add - Empty State") {
    QuickAddItemSheet(
        capturedImage: UIImage(systemName: "photo")!
    )
    .modelContainer(for: [Item.self, Room.self], inMemory: true)
}

#Preview("Quick Add - With Sample Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, Room.self, configurations: config)

    // Seed with default rooms
    let context = container.mainContext
    for (index, roomData) in Room.defaultRooms.enumerated() {
        let room = Room(
            name: roomData.name,
            iconName: roomData.icon,
            sortOrder: index,
            isDefault: true
        )
        context.insert(room)
    }

    return QuickAddItemSheet(
        capturedImage: UIImage(systemName: "camera")!
    )
    .modelContainer(container)
}

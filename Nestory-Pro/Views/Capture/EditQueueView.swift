//
//  EditQueueView.swift
//  Nestory-Pro
//
//  F8-04: Queue editing view for batch captures
//

// ============================================================================
// F8-04: EditQueueView
// ============================================================================
// Grid/list view showing all pending captures in the queue.
// - Grid/list toggle for different viewing modes
// - Multi-select mode for batch operations
// - Swipe to delete individual captures
// - Tap to open QuickEditSheet for editing
// - Toolbar actions for batch assign/delete/process
//
// SEE: TODO.md F8-04 | CaptureQueueService.swift | QuickEditSheet.swift
// ============================================================================

import SwiftUI
import SwiftData

// MARK: - EditQueueView

struct EditQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = EditQueueViewModel()

    // Rooms and categories for assignment
    @Query private var rooms: [Room]
    @Query private var categories: [Category]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.captures.isEmpty {
                    emptyStateView
                } else {
                    queueContentView
                }
            }
            .navigationTitle("Edit Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task {
                await viewModel.loadQueue()
            }
            .refreshable {
                await viewModel.loadQueue()
            }
            .sheet(item: $viewModel.editingCapture) { capture in
                QuickEditSheet(
                    capture: capture,
                    rooms: rooms,
                    categories: categories,
                    onSave: { updatedCapture in
                        Task {
                            await viewModel.updateCapture(updatedCapture)
                        }
                    },
                    onSaveAndNext: { updatedCapture in
                        Task {
                            await viewModel.updateCapture(updatedCapture)
                            viewModel.moveToNextCapture()
                        }
                    }
                )
            }
            .confirmationDialog(
                "Delete Selected",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(viewModel.selectedIDs.count) Photos", role: .destructive) {
                    Task {
                        await viewModel.deleteSelected()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove the selected photos from the queue.")
            }
            .sheet(isPresented: $viewModel.showBatchAssignRoom) {
                BatchAssignRoomSheet(
                    rooms: rooms,
                    selectedCount: viewModel.selectedIDs.count
                ) { roomID in
                    Task {
                        await viewModel.assignRoom(roomID)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showBatchAssignCategory) {
                BatchAssignCategorySheet(
                    categories: categories,
                    selectedCount: viewModel.selectedIDs.count
                ) { categoryID in
                    Task {
                        await viewModel.assignCategory(categoryID)
                    }
                }
            }
            .alert("Queue Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading queue...")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Photos in Queue", systemImage: "tray")
        } description: {
            Text("Take photos in Batch Capture mode to add them to the queue.")
        } actions: {
            Button("Start Capturing") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .accessibilityIdentifier("editQueue.emptyState")
    }

    // MARK: - Queue Content

    private var queueContentView: some View {
        ScrollView {
            VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                // Stats bar
                statsBar

                // Selection bar (in multi-select mode)
                if viewModel.isMultiSelectMode {
                    selectionBar
                }

                // Grid of captures
                captureGrid
            }
            .padding(NestoryTheme.Metrics.paddingMedium)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack {
            Label("\(viewModel.captures.count) pending", systemImage: "photo.stack")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)

            Spacer()

            // View mode toggle
            Picker("View", selection: $viewModel.viewMode) {
                Image(systemName: "square.grid.2x2")
                    .tag(QueueViewMode.grid)
                Image(systemName: "list.bullet")
                    .tag(QueueViewMode.list)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
        }
    }

    // MARK: - Selection Bar

    private var selectionBar: some View {
        HStack {
            Text("\(viewModel.selectedIDs.count) selected")
                .font(NestoryTheme.Typography.headline)

            Spacer()

            Button(viewModel.selectedIDs.count == viewModel.captures.count ? "Deselect All" : "Select All") {
                viewModel.toggleSelectAll()
            }
            .font(NestoryTheme.Typography.subheadline)
        }
        .padding(.vertical, NestoryTheme.Metrics.paddingSmall)
    }

    // MARK: - Capture Grid

    @ViewBuilder
    private var captureGrid: some View {
        if viewModel.viewMode == .grid {
            let columns = [
                GridItem(.flexible(), spacing: NestoryTheme.Metrics.spacingMedium),
                GridItem(.flexible(), spacing: NestoryTheme.Metrics.spacingMedium),
                GridItem(.flexible(), spacing: NestoryTheme.Metrics.spacingMedium)
            ]

            LazyVGrid(columns: columns, spacing: NestoryTheme.Metrics.spacingMedium) {
                ForEach(viewModel.captures) { capture in
                    CaptureGridCell(
                        capture: capture,
                        isSelected: viewModel.selectedIDs.contains(capture.id),
                        isMultiSelectMode: viewModel.isMultiSelectMode,
                        onTap: {
                            if viewModel.isMultiSelectMode {
                                viewModel.toggleSelection(capture.id)
                            } else {
                                viewModel.editCapture(capture)
                            }
                        },
                        onLongPress: {
                            viewModel.enableMultiSelect()
                            viewModel.toggleSelection(capture.id)
                        }
                    )
                    .contextMenu {
                        captureContextMenu(for: capture)
                    }
                }
            }
        } else {
            LazyVStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                ForEach(viewModel.captures) { capture in
                    CaptureListCell(
                        capture: capture,
                        isSelected: viewModel.selectedIDs.contains(capture.id),
                        isMultiSelectMode: viewModel.isMultiSelectMode,
                        onTap: {
                            if viewModel.isMultiSelectMode {
                                viewModel.toggleSelection(capture.id)
                            } else {
                                viewModel.editCapture(capture)
                            }
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteCapture(capture.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        captureContextMenu(for: capture)
                    }
                }
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func captureContextMenu(for capture: PendingCapture) -> some View {
        Button {
            viewModel.editCapture(capture)
        } label: {
            Label("Edit", systemImage: "pencil")
        }

        Divider()

        Button(role: .destructive) {
            Task {
                await viewModel.deleteCapture(capture.id)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Done") {
                dismiss()
            }
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.isMultiSelectMode {
                Menu {
                    Button {
                        viewModel.showBatchAssignRoom = true
                    } label: {
                        Label("Assign Room", systemImage: "door.left.hand.open")
                    }
                    .disabled(viewModel.selectedIDs.isEmpty)

                    Button {
                        viewModel.showBatchAssignCategory = true
                    } label: {
                        Label("Assign Category", systemImage: "tag")
                    }
                    .disabled(viewModel.selectedIDs.isEmpty)

                    Divider()

                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                    .disabled(viewModel.selectedIDs.isEmpty)

                    Divider()

                    Button {
                        viewModel.disableMultiSelect()
                    } label: {
                        Label("Cancel Selection", systemImage: "xmark")
                    }
                } label: {
                    Text("Actions")
                }
            } else {
                Button {
                    viewModel.enableMultiSelect()
                } label: {
                    Text("Select")
                }
            }
        }
    }
}

// MARK: - Queue View Mode

enum QueueViewMode: String, CaseIterable {
    case grid
    case list
}

// MARK: - EditQueueViewModel

@Observable
@MainActor
final class EditQueueViewModel {
    // State
    var captures: [PendingCapture] = []
    var isLoading = false
    var viewMode: QueueViewMode = .grid

    // Multi-select
    var isMultiSelectMode = false
    var selectedIDs: Set<UUID> = []

    // Editing
    var editingCapture: PendingCapture?
    private var editingIndex: Int = 0

    // Sheets & dialogs
    var showDeleteConfirmation = false
    var showBatchAssignRoom = false
    var showBatchAssignCategory = false

    // Error
    var showError = false
    var errorMessage = ""

    // Service
    private let queueService = CaptureQueueService.shared

    // MARK: - Load Queue

    func loadQueue() async {
        isLoading = true
        captures = await queueService.pendingCaptures
        isLoading = false
    }

    // MARK: - Selection

    func enableMultiSelect() {
        isMultiSelectMode = true
    }

    func disableMultiSelect() {
        isMultiSelectMode = false
        selectedIDs.removeAll()
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func toggleSelectAll() {
        if selectedIDs.count == captures.count {
            selectedIDs.removeAll()
        } else {
            selectedIDs = Set(captures.map(\.id))
        }
    }

    // MARK: - Editing

    func editCapture(_ capture: PendingCapture) {
        editingIndex = captures.firstIndex(where: { $0.id == capture.id }) ?? 0
        editingCapture = capture
    }

    func moveToNextCapture() {
        let nextIndex = editingIndex + 1
        if nextIndex < captures.count {
            editingIndex = nextIndex
            editingCapture = captures[nextIndex]
        } else {
            editingCapture = nil
        }
    }

    func updateCapture(_ capture: PendingCapture) async {
        await queueService.updateCapture(
            id: capture.id,
            itemName: capture.itemName,
            roomID: capture.roomID,
            categoryID: capture.categoryID,
            containerID: capture.containerID,
            notes: capture.notes
        )
        await loadQueue()
    }

    // MARK: - Delete

    func deleteCapture(_ id: UUID) async {
        await queueService.removeCapture(id)
        await loadQueue()
        HapticManager.success()
    }

    func deleteSelected() async {
        await queueService.removeCaptures(Array(selectedIDs))
        selectedIDs.removeAll()
        isMultiSelectMode = false
        await loadQueue()
        HapticManager.success()
    }

    // MARK: - Batch Assign

    func assignRoom(_ roomID: UUID) async {
        await queueService.assignRoom(roomID, to: Array(selectedIDs))
        selectedIDs.removeAll()
        isMultiSelectMode = false
        await loadQueue()
        HapticManager.success()
    }

    func assignCategory(_ categoryID: UUID) async {
        await queueService.assignCategory(categoryID, to: Array(selectedIDs))
        selectedIDs.removeAll()
        isMultiSelectMode = false
        await loadQueue()
        HapticManager.success()
    }
}

// MARK: - Capture Grid Cell

struct CaptureGridCell: View {
    let capture: PendingCapture
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var image: UIImage?

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Photo thumbnail
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(NestoryTheme.Colors.cardBackground)
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))

                // Selection indicator
                if isMultiSelectMode {
                    ZStack {
                        Circle()
                            .fill(isSelected ? NestoryTheme.Colors.accent : .white.opacity(0.8))
                            .frame(width: 28, height: 28)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(8)
                }

                // Edit indicator (if has been edited)
                if capture.hasBeenEdited && !isMultiSelectMode {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white).padding(2))
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            HapticManager.mediumImpact()
            onLongPress()
        }
        .task {
            image = await CaptureQueueService.shared.loadPhoto(identifier: capture.photoIdentifier)
        }
    }
}

// MARK: - Capture List Cell

struct CaptureListCell: View {
    let capture: PendingCapture
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                // Selection checkbox
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? NestoryTheme.Colors.accent : NestoryTheme.Colors.muted)
                }

                // Thumbnail
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(NestoryTheme.Colors.cardBackground)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(capture.itemName.isEmpty ? "Untitled" : capture.itemName)
                        .font(NestoryTheme.Typography.headline)
                        .foregroundStyle(capture.itemName.isEmpty ? NestoryTheme.Colors.muted : .primary)

                    Text(capture.capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }

                Spacer()

                // Status indicators
                if capture.hasBeenEdited {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                if !isMultiSelectMode {
                    Image(systemName: "chevron.right")
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }
            .padding(NestoryTheme.Metrics.paddingMedium)
            .background(NestoryTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
        .task {
            image = await CaptureQueueService.shared.loadPhoto(identifier: capture.photoIdentifier)
        }
    }
}

// MARK: - Batch Assign Room Sheet

struct BatchAssignRoomSheet: View {
    @Environment(\.dismiss) private var dismiss

    let rooms: [Room]
    let selectedCount: Int
    let onAssign: (UUID) -> Void

    var body: some View {
        NavigationStack {
            List(rooms) { room in
                Button {
                    onAssign(room.id)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "door.left.hand.open")
                            .foregroundStyle(NestoryTheme.Colors.accent)
                        Text(room.name)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Assign Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) {
                Text("Assign \(selectedCount) photos to a room")
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .padding()
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Batch Assign Category Sheet

struct BatchAssignCategorySheet: View {
    @Environment(\.dismiss) private var dismiss

    let categories: [Category]
    let selectedCount: Int
    let onAssign: (UUID) -> Void

    var body: some View {
        NavigationStack {
            List(categories) { category in
                Button {
                    onAssign(category.id)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundStyle(NestoryTheme.Colors.accent)
                        Text(category.name)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Assign Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) {
                Text("Assign \(selectedCount) photos to a category")
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .padding()
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Edit Queue") {
    EditQueueView()
        .modelContainer(PreviewContainer.withSampleData())
}
#endif

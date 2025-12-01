//
//  TagPillView.swift
//  Nestory-Pro
//
//  Created for v1.2 - P2-05
//

// ============================================================================
// TAG PILL UI - Task P2-05: Tags & quick categorization
// ============================================================================
// Pill-style tag display for item detail and list views.
//
// USAGE:
// - TagPillView: Single tag pill with color
// - TagFlowView: Horizontal wrapping layout for multiple tags
// - TagEditorView: Sheet for adding/removing tags from an item
//
// SEE: TODO.md P2-05 | Tag.swift | ItemDetailView.swift
// ============================================================================

import SwiftUI
import SwiftData

// MARK: - Tag Pill View

/// Single pill-style tag display
struct TagPillView: View {
    let tag: Tag
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.caption.weight(.medium))
            
            if onRemove != nil {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tagColor.opacity(isSelected ? 1.0 : 0.85))
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .onTapGesture {
            onTap?()
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Tags.pill)
    }
    
    private var tagColor: Color {
        Color(hex: tag.colorHex) ?? .blue
    }
}

// MARK: - Tag Flow View

/// Horizontal wrapping layout for multiple tags
struct TagFlowView: View {
    let tags: [Tag]
    var onRemove: ((Tag) -> Void)? = nil
    
    var body: some View {
        if tags.isEmpty {
            Text("No tags")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            FlowLayout(spacing: 6) {
                ForEach(tags) { tag in
                    TagPillView(
                        tag: tag,
                        onRemove: onRemove != nil ? { onRemove?(tag) } : nil
                    )
                }
            }
        }
    }
}

// MARK: - Flow Layout

/// Horizontal wrapping layout container
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }
        
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Tag Editor Sheet

/// Sheet for adding/removing tags from an item
struct TagEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var item: Item
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    @State private var searchText = ""
    @State private var showingCreateTag = false
    @State private var newTagName = ""
    @State private var newTagColor = Tag.predefinedColors[0]
    
    var body: some View {
        NavigationStack {
            List {
                // Current tags section
                if !item.tagObjects.isEmpty {
                    Section("Current Tags") {
                        TagFlowView(tags: item.tagObjects) { tag in
                            removeTag(tag)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                
                // Available tags section
                Section("Available Tags") {
                    ForEach(filteredTags) { tag in
                        TagRowView(
                            tag: tag,
                            isSelected: item.tagObjects.contains { $0.id == tag.id }
                        ) {
                            toggleTag(tag)
                        }
                    }
                    
                    // Create new tag button
                    Button {
                        showingCreateTag = true
                    } label: {
                        Label("Create New Tag", systemImage: "plus.circle")
                    }
                }
                
                // Favorite tags quick add
                if !favoriteTags.isEmpty && item.tagObjects.isEmpty {
                    Section("Quick Add") {
                        FlowLayout(spacing: 8) {
                            ForEach(favoriteTags) { tag in
                                TagPillView(tag: tag) {
                                    addTag(tag)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search tags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateTag) {
                CreateTagSheet(
                    name: $newTagName,
                    colorHex: $newTagColor,
                    onCreate: createAndAddTag
                )
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Tags.editorSheet)
    }
    
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags.filter { tag in
                !item.tagObjects.contains { $0.id == tag.id }
            }
        }
        return allTags.filter { tag in
            tag.name.localizedCaseInsensitiveContains(searchText) &&
            !item.tagObjects.contains { $0.id == tag.id }
        }
    }
    
    private var favoriteTags: [Tag] {
        allTags.filter { $0.isFavorite && !item.tagObjects.contains { $0.id == $0.id } }
    }
    
    private func toggleTag(_ tag: Tag) {
        if item.tagObjects.contains(where: { $0.id == tag.id }) {
            removeTag(tag)
        } else {
            addTag(tag)
        }
    }
    
    private func addTag(_ tag: Tag) {
        item.tagObjects.append(tag)
        item.updatedAt = Date()
    }
    
    private func removeTag(_ tag: Tag) {
        item.tagObjects.removeAll { $0.id == tag.id }
        item.updatedAt = Date()
    }
    
    private func createAndAddTag() {
        guard !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let tag = Tag(
            name: newTagName.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: newTagColor,
            isFavorite: false
        )
        modelContext.insert(tag)
        item.tagObjects.append(tag)
        item.updatedAt = Date()
        
        newTagName = ""
        newTagColor = Tag.predefinedColors[0]
        showingCreateTag = false
    }
}

// MARK: - Tag Row View

private struct TagRowView: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Circle()
                    .fill(Color(hex: tag.colorHex) ?? .blue)
                    .frame(width: 12, height: 12)
                
                Text(tag.name)
                    .foregroundStyle(.primary)
                
                if tag.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Tag Sheet

private struct CreateTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var name: String
    @Binding var colorHex: String
    let onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Name") {
                    TextField("Enter tag name", text: $name)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Tags.nameField)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Tag.predefinedColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? .blue)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if color == colorHex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.body.weight(.bold))
                                    }
                                }
                                .onTapGesture {
                                    colorHex = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Accessibility Identifiers

extension AccessibilityIdentifiers {
    enum Tags {
        static let pill = "tags.pill"
        static let editorSheet = "tags.editorSheet"
        static let nameField = "tags.nameField"
        static let flowView = "tags.flowView"
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Tag Pill") {
    let tag = Tag(name: "Essential", colorHex: "#34C759", isFavorite: true)
    return TagPillView(tag: tag)
        .padding()
}

#Preview("Tag Flow") {
    let tags = [
        Tag(name: "Essential", colorHex: "#34C759"),
        Tag(name: "High Value", colorHex: "#FF9500"),
        Tag(name: "Electronics", colorHex: "#007AFF")
    ]
    return TagFlowView(tags: tags)
        .padding()
}
#endif

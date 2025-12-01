//
//  BreadcrumbView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/30/25.
//

// ============================================================================
// Task P2-02: Information architecture breadcrumbs
// Shows navigation path: "Property > Room > Container > Item"
// ============================================================================

import SwiftUI

/// Displays a breadcrumb navigation path for hierarchical navigation
/// Format: "Home > Apartment > Living Room > TV Stand"
struct BreadcrumbView: View {
    let components: [BreadcrumbComponent]
    let onTap: ((BreadcrumbComponent) -> Void)?
    
    init(components: [BreadcrumbComponent], onTap: ((BreadcrumbComponent) -> Void)? = nil) {
        self.components = components
        self.onTap = onTap
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(components.enumerated()), id: \.element.id) { index, component in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    BreadcrumbButton(
                        component: component,
                        isLast: index == components.count - 1,
                        onTap: onTap
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

/// A single component in the breadcrumb trail
struct BreadcrumbComponent: Identifiable, Sendable {
    let id: UUID
    let name: String
    let iconName: String
    let level: BreadcrumbLevel
    
    enum BreadcrumbLevel: Sendable {
        case property
        case room
        case container
        case item
    }
}

/// Button for a single breadcrumb component
private struct BreadcrumbButton: View {
    let component: BreadcrumbComponent
    let isLast: Bool
    let onTap: ((BreadcrumbComponent) -> Void)?
    
    var body: some View {
        Button(action: { onTap?(component) }) {
            HStack(spacing: 4) {
                Image(systemName: component.iconName)
                    .font(.caption)
                Text(component.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(isLast ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isLast
                    ? Color.accentColor.opacity(0.1)
                    : Color(.systemGray5)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLast)
    }
}

// MARK: - Convenience Initializers

extension BreadcrumbView {
    /// Creates breadcrumbs from an Item's full path
    init(item: Item, onTap: ((BreadcrumbComponent) -> Void)? = nil) {
        var components: [BreadcrumbComponent] = []
        
        if let property = item.room?.property {
            components.append(BreadcrumbComponent(
                id: property.id,
                name: property.name,
                iconName: property.iconName,
                level: .property
            ))
        }
        
        if let room = item.room {
            components.append(BreadcrumbComponent(
                id: room.id,
                name: room.name,
                iconName: room.iconName,
                level: .room
            ))
        }
        
        if let container = item.container {
            components.append(BreadcrumbComponent(
                id: container.id,
                name: container.name,
                iconName: container.iconName,
                level: .container
            ))
        }
        
        components.append(BreadcrumbComponent(
            id: item.id,
            name: item.name,
            iconName: "archivebox.fill",
            level: .item
        ))
        
        self.init(components: components, onTap: onTap)
    }
    
    /// Creates breadcrumbs from a Container's path
    init(container: Container, onTap: ((BreadcrumbComponent) -> Void)? = nil) {
        var components: [BreadcrumbComponent] = []
        
        if let property = container.room?.property {
            components.append(BreadcrumbComponent(
                id: property.id,
                name: property.name,
                iconName: property.iconName,
                level: .property
            ))
        }
        
        if let room = container.room {
            components.append(BreadcrumbComponent(
                id: room.id,
                name: room.name,
                iconName: room.iconName,
                level: .room
            ))
        }
        
        components.append(BreadcrumbComponent(
            id: container.id,
            name: container.name,
            iconName: container.iconName,
            level: .container
        ))
        
        self.init(components: components, onTap: onTap)
    }
    
    /// Creates breadcrumbs from a Room's path
    init(room: Room, onTap: ((BreadcrumbComponent) -> Void)? = nil) {
        var components: [BreadcrumbComponent] = []
        
        if let property = room.property {
            components.append(BreadcrumbComponent(
                id: property.id,
                name: property.name,
                iconName: property.iconName,
                level: .property
            ))
        }
        
        components.append(BreadcrumbComponent(
            id: room.id,
            name: room.name,
            iconName: room.iconName,
            level: .room
        ))
        
        self.init(components: components, onTap: onTap)
    }
}

#Preview {
    VStack(spacing: 20) {
        BreadcrumbView(components: [
            BreadcrumbComponent(id: UUID(), name: "My Home", iconName: "house.fill", level: .property),
            BreadcrumbComponent(id: UUID(), name: "Living Room", iconName: "sofa.fill", level: .room),
            BreadcrumbComponent(id: UUID(), name: "TV Stand", iconName: "cabinet.fill", level: .container),
            BreadcrumbComponent(id: UUID(), name: "Apple TV", iconName: "archivebox.fill", level: .item)
        ])
        
        BreadcrumbView(components: [
            BreadcrumbComponent(id: UUID(), name: "Apartment", iconName: "building.2.fill", level: .property),
            BreadcrumbComponent(id: UUID(), name: "Kitchen", iconName: "refrigerator.fill", level: .room)
        ])
    }
    .padding()
}

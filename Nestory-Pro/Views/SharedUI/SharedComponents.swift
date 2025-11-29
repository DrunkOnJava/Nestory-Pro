//
//  SharedComponents.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let iconName: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(color)
                    Spacer()
                }
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(minWidth: 140)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Documentation Badge
struct DocumentationBadge: View {
    let label: String
    let isComplete: Bool
    let compact: Bool
    let weight: String?

    init(_ label: String, isComplete: Bool, compact: Bool = false, weight: String? = nil) {
        self.label = label
        self.isComplete = isComplete
        self.compact = compact
        self.weight = weight
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(compact ? .caption2 : .caption)
            if !compact {
                Text(label)
                    .font(.caption)
                if let weight = weight {
                    Text("(\(weight))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .foregroundStyle(isComplete ? .green : .secondary)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isComplete ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
        )
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item List Cell
struct ItemListCell: View {
    let item: Item
    let settings: SettingsManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemGroupedBackground))
                
                if let category = item.category {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundStyle(Color(hex: category.colorHex) ?? .secondary)
                } else {
                    Image(systemName: "cube.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 60, height: 60)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let room = item.room {
                        Text(room.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if item.room != nil && item.category != nil {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let category = item.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let price = item.purchasePrice {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(settings.formatCurrency(price))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Documentation badges (compact)
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    DocumentationBadge("Photo", isComplete: item.hasPhoto, compact: true)
                    DocumentationBadge("Value", isComplete: item.hasValue, compact: true)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Item Grid Cell
struct ItemGridCell: View {
    let item: Item
    let settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
                
                if let category = item.category {
                    Image(systemName: category.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: category.colorHex) ?? .secondary)
                } else {
                    Image(systemName: "cube.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let price = item.purchasePrice {
                    Text(settings.formatCurrency(price))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Documentation indicators
            HStack(spacing: 4) {
                Circle()
                    .fill(item.hasPhoto ? .green : .secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(item.hasValue ? .green : .secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(item.hasReceipt ? .green : .secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let buttonTitle, let buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Summary Card") {
    HStack {
        SummaryCard(
            title: "Total Items",
            value: "124",
            subtitle: "Across 9 rooms",
            iconName: "archivebox.fill",
            color: .blue
        )
        SummaryCard(
            title: "Documentation",
            value: "78%",
            subtitle: "Items documented",
            iconName: "checkmark.shield.fill",
            color: .green
        )
    }
    .padding()
}

#Preview("Badges") {
    HStack {
        DocumentationBadge("Photo", isComplete: true)
        DocumentationBadge("Receipt", isComplete: false)
        DocumentationBadge("Value", isComplete: true, compact: true)
    }
    .padding()
}

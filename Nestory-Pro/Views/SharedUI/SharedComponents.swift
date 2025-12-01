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
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
                HStack {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(color)
                    Spacer()
                }

                Text(value)
                    .font(NestoryTheme.Typography.title)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(NestoryTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
            .padding(NestoryTheme.Metrics.paddingLarge)
            .frame(minWidth: NestoryTheme.Metrics.cardMinWidth)
            .background(NestoryTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
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

    private var statusText: String {
        isComplete ? "Complete" : "Missing"
    }

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(compact ? NestoryTheme.Typography.caption2 : NestoryTheme.Typography.caption)
            if !compact {
                Text(label)
                    .font(NestoryTheme.Typography.caption)
                if let weight = weight {
                    Text("(\(weight))")
                        .font(NestoryTheme.Typography.caption2)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }
        }
        .foregroundStyle(isComplete ? NestoryTheme.Colors.documented : NestoryTheme.Colors.muted)
        .padding(.horizontal, compact ? NestoryTheme.Metrics.paddingSmall - 2 : NestoryTheme.Metrics.paddingSmall)
        .padding(.vertical, NestoryTheme.Metrics.paddingXSmall)
        .background(
            Capsule()
                .fill(isComplete ? NestoryTheme.Colors.documented.opacity(0.15) : NestoryTheme.Colors.missing)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(statusText)")
        .accessibilityValue(weight.map { "Weight: \($0)" } ?? "")
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
                .font(NestoryTheme.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
                .padding(.vertical, NestoryTheme.Metrics.paddingSmall)
                .background(
                    Capsule()
                        .fill(isSelected ? NestoryTheme.Colors.accent : NestoryTheme.Colors.chipBackground)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item List Cell
struct ItemListCell: View {
    let item: Item
    let settings: SettingsManager

    private var accessibilityDescription: String {
        var parts: [String] = [item.name]
        if let room = item.room {
            parts.append("in \(room.name)")
        }
        if let price = item.purchasePrice {
            parts.append("valued at \(settings.formatCurrency(price))")
        }
        let status = item.documentationScore >= 0.8 ? "fully documented" :
                     item.documentationScore >= 0.5 ? "partially documented" : "needs documentation"
        parts.append(status)
        return parts.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall + 2)
                    .fill(NestoryTheme.Colors.elevatedBackground)

                if let category = item.category {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundStyle(Color(hex: category.colorHex) ?? NestoryTheme.Colors.muted)
                } else {
                    Image(systemName: "cube.fill")
                        .font(.title2)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }
            .frame(width: NestoryTheme.Metrics.thumbnailMedium, height: NestoryTheme.Metrics.thumbnailMedium)
            .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text(item.name)
                    .font(NestoryTheme.Typography.headline)
                    .lineLimit(1)

                HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                    if let room = item.room {
                        Text(room.name)
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                    if item.room != nil && item.category != nil {
                        Text("•")
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                    if let category = item.category {
                        Text(category.name)
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                    if let price = item.purchasePrice {
                        Text("•")
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                        Text(settings.formatCurrency(price))
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                }
            }

            Spacer()

            // Documentation badges (compact)
            VStack(alignment: .trailing, spacing: NestoryTheme.Metrics.spacingXSmall) {
                HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                    DocumentationBadge("Photo", isComplete: item.hasPhoto, compact: true)
                    DocumentationBadge("Value", isComplete: item.hasValue, compact: true)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.vertical, NestoryTheme.Metrics.paddingXSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
    }
}

// MARK: - Item Grid Cell
struct ItemGridCell: View {
    let item: Item
    let settings: SettingsManager

    private var accessibilityDescription: String {
        var parts: [String] = [item.name]
        if let room = item.room {
            parts.append("in \(room.name)")
        }
        if let price = item.purchasePrice {
            parts.append("valued at \(settings.formatCurrency(price))")
        }
        let status = item.documentationScore >= 0.8 ? "fully documented" :
                     item.documentationScore >= 0.5 ? "partially documented" : "needs documentation"
        parts.append(status)
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingSmall) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge)
                    .fill(NestoryTheme.Colors.elevatedBackground)

                if let category = item.category {
                    Image(systemName: category.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: category.colorHex) ?? NestoryTheme.Colors.muted)
                } else {
                    Image(systemName: "cube.fill")
                        .font(.largeTitle)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(NestoryTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let price = item.purchasePrice {
                    Text(settings.formatCurrency(price))
                        .font(NestoryTheme.Typography.caption)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }

            // Documentation indicators
            HStack(spacing: NestoryTheme.Metrics.spacingXSmall) {
                Circle()
                    .fill(item.hasPhoto ? NestoryTheme.Colors.documented : NestoryTheme.Colors.missing)
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(item.hasValue ? NestoryTheme.Colors.documented : NestoryTheme.Colors.missing)
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(item.hasReceipt ? NestoryTheme.Colors.documented : NestoryTheme.Colors.missing)
                    .frame(width: 6, height: 6)
            }
            .accessibilityHidden(true)
        }
        .padding(NestoryTheme.Metrics.paddingMedium)
        .background(NestoryTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
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
        VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
            Image(systemName: iconName)
                .font(.system(size: NestoryTheme.Metrics.iconHero))
                .foregroundStyle(NestoryTheme.Colors.muted)
                .accessibilityHidden(true)

            Text(title)
                .font(NestoryTheme.Typography.title2)

            Text(message)
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)

            if let buttonTitle, let buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(NestoryTheme.Typography.buttonLabel)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, NestoryTheme.Metrics.paddingSmall)
                .accessibilityIdentifier(AccessibilityIdentifiers.Common.emptyStateButton)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityIdentifier(AccessibilityIdentifiers.Common.emptyStateView)
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

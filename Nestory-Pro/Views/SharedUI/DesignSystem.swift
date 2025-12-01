//
//  DesignSystem.swift
//  Nestory-Pro
//
//  Created by Griffin on 12/1/25.
//

// ============================================================================
// Task P2-06: Design System Foundation
// Centralized design tokens for consistent visual language across the app
// ============================================================================

import SwiftUI

// MARK: - NestoryTheme

/// Central design system containing all visual tokens for Nestory Pro
enum NestoryTheme {

    // MARK: - Colors

    /// Semantic color tokens for consistent theming
    enum Colors {
        // Backgrounds
        static let background = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)
        static let elevatedBackground = Color(.tertiarySystemGroupedBackground)

        // Accent & Brand
        static let accent = Color.accentColor
        static let brand = Color("BrandColor")

        // Semantic States
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // UI Elements
        static let border = Color(.separator)
        static let muted = Color(.secondaryLabel)
        static let chipBackground = Color(.systemGray5)

        // Documentation Status
        static let documented = Color.green
        static let incomplete = Color.orange
        static let missing = Color(.systemGray4)
    }

    // MARK: - Metrics

    /// Spacing, sizing, and dimension tokens
    enum Metrics {
        // Corner Radii
        static let cornerRadiusSmall: CGFloat = 6
        static let cornerRadiusMedium: CGFloat = 10
        static let cornerRadiusLarge: CGFloat = 12
        static let cornerRadiusXLarge: CGFloat = 16

        // Padding
        static let paddingXSmall: CGFloat = 4
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 12
        static let paddingLarge: CGFloat = 16
        static let paddingXLarge: CGFloat = 24

        // Spacing (between elements)
        static let spacingXSmall: CGFloat = 4
        static let spacingSmall: CGFloat = 8
        static let spacingMedium: CGFloat = 12
        static let spacingLarge: CGFloat = 16
        static let spacingXLarge: CGFloat = 24
        static let spacingXXLarge: CGFloat = 32

        // Icon Sizes
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
        static let iconXLarge: CGFloat = 48
        static let iconHero: CGFloat = 60

        // Thumbnail Sizes
        static let thumbnailSmall: CGFloat = 40
        static let thumbnailMedium: CGFloat = 60
        static let thumbnailLarge: CGFloat = 80

        // Card Dimensions
        static let cardMinWidth: CGFloat = 140
        static let cardMinHeight: CGFloat = 100
    }

    // MARK: - Typography

    /// Font presets for consistent text styling
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2

        // Special use cases
        static let statValue = Font.title.weight(.bold)
        static let statLabel = Font.caption2
        static let badge = Font.caption.weight(.medium)
        static let buttonLabel = Font.body.weight(.semibold)
    }

    // MARK: - Shadows

    /// Shadow definitions for elevation
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let card = Shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )

        static let elevated = Shadow(
            color: Color.black.opacity(0.12),
            radius: 12,
            x: 0,
            y: 4
        )

        static let subtle = Shadow(
            color: Color.black.opacity(0.04),
            radius: 4,
            x: 0,
            y: 1
        )
    }

    // MARK: - Animation

    /// Animation timing presets
    enum Animation {
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.4)
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
        static let bouncy: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.6)
    }

    // MARK: - Haptics

    /// Haptic feedback generators
    enum Haptics {
        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        static func error() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        static func warning() {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }

        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }

        static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }

        static func lightImpact() {
            impact(.light)
        }

        static func heavyImpact() {
            impact(.heavy)
        }
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies standard card styling with background, corner radius, and shadow
    func cardStyle(
        cornerRadius: CGFloat = NestoryTheme.Metrics.cornerRadiusLarge,
        shadow: NestoryTheme.Shadow = .card
    ) -> some View {
        self
            .background(NestoryTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }

    /// Applies loading/skeleton card styling with redaction
    func loadingCard() -> some View {
        self
            .redacted(reason: .placeholder)
            .shimmering()
    }

    /// Applies error card styling with red tint
    func errorCard() -> some View {
        self
            .background(NestoryTheme.Colors.error.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge)
                    .stroke(NestoryTheme.Colors.error.opacity(0.3), lineWidth: 1)
            )
    }

    /// Applies empty state card styling centered content
    func emptyStateCard() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(NestoryTheme.Metrics.paddingXLarge)
            .background(NestoryTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
    }

    /// Applies section header styling
    func sectionHeader() -> some View {
        self
            .font(NestoryTheme.Typography.headline)
            .foregroundStyle(.primary)
    }
}

// MARK: - Section Header View

/// Consistent section header with optional icon
struct SectionHeader: View {
    let title: String
    let systemImage: String?

    init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.accent)
            }
            Text(title)
                .font(NestoryTheme.Typography.headline)
        }
    }
}

// MARK: - Shimmer Effect

/// Shimmer animation modifier for loading states
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Preview

#Preview("Design System Colors") {
    VStack(spacing: 16) {
        HStack {
            colorSwatch(NestoryTheme.Colors.success, "Success")
            colorSwatch(NestoryTheme.Colors.warning, "Warning")
            colorSwatch(NestoryTheme.Colors.error, "Error")
            colorSwatch(NestoryTheme.Colors.info, "Info")
        }

        HStack {
            colorSwatch(NestoryTheme.Colors.documented, "Documented")
            colorSwatch(NestoryTheme.Colors.incomplete, "Incomplete")
            colorSwatch(NestoryTheme.Colors.missing, "Missing")
        }
    }
    .padding()
}

#Preview("Card Styles") {
    VStack(spacing: 20) {
        Text("Standard Card")
            .padding()
            .cardStyle()

        Text("Loading Card")
            .padding()
            .cardStyle()
            .loadingCard()

        Text("Error Card")
            .padding()
            .errorCard()

        VStack {
            Image(systemName: "tray")
                .font(.largeTitle)
            Text("Empty State")
        }
        .emptyStateCard()
    }
    .padding()
    .background(NestoryTheme.Colors.background)
}

@ViewBuilder
private func colorSwatch(_ color: Color, _ name: String) -> some View {
    VStack(spacing: 4) {
        Circle()
            .fill(color)
            .frame(width: 40, height: 40)
        Text(name)
            .font(.caption2)
    }
}

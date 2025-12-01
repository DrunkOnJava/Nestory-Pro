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

// MARK: - Accessibility Support

/// Accessibility convenience modifiers for VoiceOver and inclusive design
extension View {
    /// Applies a VoiceOver label and optional hint
    func accessibilityCard(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = .isButton
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Applies accessibility label for a stat card
    func accessibilityStat(label: String, value: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label): \(value)")
    }

    /// Applies accessibility for documentation progress
    func accessibilityProgress(percentage: Int, label: String = "Documentation") -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label) \(percentage) percent complete")
            .accessibilityValue("\(percentage) percent")
    }

    /// Applies accessibility for item row
    func accessibilityItemRow(
        name: String,
        location: String?,
        value: String?
    ) -> some View {
        var description = name
        if let location { description += ", in \(location)" }
        if let value { description += ", valued at \(value)" }
        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(description)
            .accessibilityHint("Double-tap to view details")
            .accessibilityAddTraits(.isButton)
    }

    /// Conditionally applies animation based on Reduce Motion preference
    func animateWithMotionPreference<V: Equatable>(
        value: V,
        animation: Animation = NestoryTheme.Animation.standard
    ) -> some View {
        modifier(ReduceMotionAnimationModifier(value: value, animation: animation))
    }

    /// Applies transition that respects Reduce Motion
    func transitionWithMotionPreference(
        _ transition: AnyTransition = .opacity.combined(with: .scale(scale: 0.95))
    ) -> some View {
        modifier(ReduceMotionTransitionModifier(transition: transition))
    }
}

// MARK: - Reduce Motion Modifiers

/// Animation modifier that respects Reduce Motion preference
struct ReduceMotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: V
    let animation: Animation

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

/// Transition modifier that respects Reduce Motion preference
struct ReduceMotionTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transition: AnyTransition

    func body(content: Content) -> some View {
        content.transition(reduceMotion ? .opacity : transition)
    }
}

/// Shimmer modifier with Reduce Motion support
struct AccessibleShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if reduceMotion {
            // Static placeholder without animation
            content.opacity(0.6)
        } else {
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
}

extension View {
    /// Applies shimmer effect that respects Reduce Motion
    func accessibleShimmer() -> some View {
        modifier(AccessibleShimmerModifier())
    }
}

// MARK: - Motion-Safe Animations

extension NestoryTheme.Animation {
    /// Returns appropriate animation based on Reduce Motion setting
    /// Use this for programmatic animations
    @MainActor
    static func motionSafe(
        _ animation: Animation,
        reduceMotion: Bool
    ) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// Note: EmptyStateView, LoadingStateView, ErrorStateView are defined in SharedComponents.swift

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

#Preview("State Views") {
    ScrollView {
        VStack(spacing: 24) {
            // Uses EmptyStateView from SharedComponents.swift
            EmptyStateView(
                iconName: "archivebox",
                title: "No Items Yet",
                message: "Start building your inventory by adding your first item.",
                buttonTitle: "Add Item",
                buttonAction: {}
            )
            .cardStyle()

            // Loading state placeholder
            VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                ProgressView()
                    .controlSize(.large)
                Text("Loading inventory...")
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .cardStyle()

            // Error state placeholder
            VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: NestoryTheme.Metrics.iconXLarge))
                    .foregroundStyle(NestoryTheme.Colors.error)
                Text("Failed to load inventory.")
                    .font(NestoryTheme.Typography.subheadline)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                Button("Try Again") {}
                    .buttonStyle(.bordered)
            }
            .padding(NestoryTheme.Metrics.paddingXLarge)
            .errorCard()
        }
        .padding()
    }
    .background(NestoryTheme.Colors.background)
}

// MARK: - Button Press Feedback (P2-15-2)

/// Button style that provides press feedback with scale effect
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let hapticStyle: NestoryHapticStyle

    enum NestoryHapticStyle {
        case selection
        case impact
        case none
    }

    init(haptic: NestoryHapticStyle = .selection) {
        self.hapticStyle = haptic
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : NestoryTheme.Animation.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    triggerHaptic()
                }
            }
    }

    private func triggerHaptic() {
        switch hapticStyle {
        case .selection:
            NestoryTheme.Haptics.selection()
        case .impact:
            NestoryTheme.Haptics.lightImpact()
        case .none:
            break
        }
    }
}

/// Card button style with press feedback and shadow animation
struct CardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .shadow(
                color: configuration.isPressed ? Color.black.opacity(0.04) : NestoryTheme.Shadow.card.color,
                radius: configuration.isPressed ? 4 : NestoryTheme.Shadow.card.radius,
                x: 0,
                y: configuration.isPressed ? 1 : NestoryTheme.Shadow.card.y
            )
            .animation(reduceMotion ? nil : NestoryTheme.Animation.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    NestoryTheme.Haptics.selection()
                }
            }
    }
}

extension View {
    /// Applies pressable button style with scale effect and optional haptic
    func pressableStyle(haptic: PressableButtonStyle.NestoryHapticStyle = .selection) -> some View {
        buttonStyle(PressableButtonStyle(haptic: haptic))
    }

    /// Applies card button style for tappable cards
    func cardButtonStyle() -> some View {
        buttonStyle(CardButtonStyle())
    }
}

#Preview("Button Styles") {
    VStack(spacing: 24) {
        Button("Pressable Button") {}
            .buttonStyle(.borderedProminent)
            .pressableStyle()

        Button {
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Button")
                    .font(NestoryTheme.Typography.headline)
                Text("Tap to see press effect")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(NestoryTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
        }
        .cardButtonStyle()
    }
    .padding()
    .background(NestoryTheme.Colors.background)
}

// MARK: - P2-06-3: Layout Scaffolding

// ============================================================================
// Layout Standards Documentation
// ============================================================================
//
// NAVIGATION BAR STANDARDS:
// - Tab roots (Inventory, Capture, Reports, Settings): Use `.navigationBarTitleDisplayMode(.large)`
// - Detail views (ItemDetail, PropertyDetail, etc.): Use `.navigationBarTitleDisplayMode(.inline)`
// - Modal sheets: Use `.inline` with Cancel/Done buttons in toolbar
//
// BACKGROUND STANDARDS:
// - All screens: Use `NestoryTheme.Colors.background` as base
// - Apply `.standardBackground()` modifier to root view for full coverage
// - Cards float on top with `.cardStyle()` modifier
//
// SCROLL LAYOUT STANDARDS:
// - Use `StandardScrollLayout` for consistent padding and spacing
// - Content padding: 16pt horizontal, 16pt vertical
// - Section spacing: 24pt between major sections
// - Card spacing: 16pt between cards within a section
//
// ============================================================================

/// Standard layout wrapper for scrollable content screens
///
/// Provides consistent padding, spacing, and background for tab views
/// and detail screens. Use this as the root container for most screens.
///
/// Example:
/// ```swift
/// StandardScrollLayout {
///     VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
///         SectionHeader("Items")
///         ForEach(items) { item in
///             ItemRow(item: item)
///                 .cardStyle()
///         }
///     }
/// }
/// ```
struct StandardScrollLayout<Content: View>: View {
    let showsIndicators: Bool
    let content: Content

    init(
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            content
                .padding(.horizontal, NestoryTheme.Metrics.paddingLarge)
                .padding(.vertical, NestoryTheme.Metrics.paddingLarge)
        }
        .standardBackground()
    }
}

/// Standard layout wrapper for non-scrollable content screens
///
/// Use this for screens that don't need scrolling but need consistent
/// background treatment.
struct StandardLayout<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .standardBackground()
    }
}

// MARK: - Background Modifiers

extension View {
    /// Applies the standard grouped background that extends to safe area edges
    ///
    /// Use this on root views to ensure consistent background across all screens.
    /// The background uses `systemGroupedBackground` which adapts to light/dark mode.
    func standardBackground() -> some View {
        self.background(NestoryTheme.Colors.background.ignoresSafeArea())
    }

    /// Applies navigation bar styling for tab root screens
    ///
    /// Tab roots should use large navigation titles for prominent headers.
    /// Example screens: Inventory, Capture, Reports, Settings
    func tabRootNavigationStyle(title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
    }

    /// Applies navigation bar styling for detail screens
    ///
    /// Detail screens use inline titles to maximize content space.
    /// Example screens: ItemDetailView, PropertyDetailView, RoomDetailView
    func detailNavigationStyle(title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }

    /// Applies navigation bar styling for modal sheets
    ///
    /// Sheets use inline titles with Cancel/Done toolbar items.
    /// Apply this, then add toolbar items separately.
    func sheetNavigationStyle(title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tab Bar Styling

extension View {
    /// Applies visible tab bar background for separation from content
    ///
    /// Use on tab views to ensure clear separation between content and tabs.
    func visibleTabBarBackground() -> some View {
        self.toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Layout Preview

#Preview("StandardScrollLayout") {
    NavigationStack {
        StandardScrollLayout {
            VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
                // Section 1: Summary
                SectionHeader("Summary", systemImage: "chart.bar.fill")
                HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                    VStack {
                        Text("24")
                            .font(NestoryTheme.Typography.statValue)
                        Text("Items")
                            .font(NestoryTheme.Typography.statLabel)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()

                    VStack {
                        Text("$4,250")
                            .font(NestoryTheme.Typography.statValue)
                        Text("Total Value")
                            .font(NestoryTheme.Typography.statLabel)
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()
                }

                // Section 2: Recent Items
                SectionHeader("Recent Items", systemImage: "clock.fill")
                VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                    ForEach(1...3, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(NestoryTheme.Colors.chipBackground)
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading) {
                                Text("Item \(index)")
                                    .font(NestoryTheme.Typography.headline)
                                Text("Living Room")
                                    .font(NestoryTheme.Typography.caption)
                                    .foregroundStyle(NestoryTheme.Colors.muted)
                            }
                            Spacer()
                            Text("$\(index * 100)")
                                .font(NestoryTheme.Typography.subheadline)
                                .foregroundStyle(NestoryTheme.Colors.muted)
                        }
                        .padding()
                        .cardStyle()
                    }
                }

                // Section 3: Empty State
                SectionHeader("Containers", systemImage: "archivebox.fill")
                EmptyStateView(
                    iconName: "archivebox",
                    title: "No Containers",
                    message: "Add containers to organize items within rooms.",
                    buttonTitle: "Add Container",
                    buttonAction: {}
                )
                .cardStyle()
            }
        }
        .tabRootNavigationStyle(title: "Inventory")
    }
}

#Preview("Navigation Styles") {
    TabView {
        // Tab Root Style
        NavigationStack {
            StandardScrollLayout {
                VStack(spacing: 20) {
                    Text("Tab roots use .large title display mode")
                        .padding()
                        .cardStyle()

                    NavigationLink("Go to Detail") {
                        // Detail Style
                        StandardScrollLayout {
                            VStack(spacing: 20) {
                                Text("Detail screens use .inline title display mode")
                                    .padding()
                                    .cardStyle()
                            }
                        }
                        .detailNavigationStyle(title: "Item Detail")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .tabRootNavigationStyle(title: "Inventory")
        }
        .tabItem {
            Label("Inventory", systemImage: "archivebox.fill")
        }

        // Settings Tab
        NavigationStack {
            StandardScrollLayout {
                Text("Settings content")
                    .padding()
                    .cardStyle()
            }
            .tabRootNavigationStyle(title: "Settings")
        }
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
    }
    .visibleTabBarBackground()
}

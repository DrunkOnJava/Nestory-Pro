//
//  PreviewHelpers.swift
//  Nestory-Pro
//
//  SwiftUI preview configuration helpers and utilities
//

import SwiftUI

#if DEBUG

// MARK: - Preview Device Configuration

extension PreviewDevice {
    static let iPhone15Pro = PreviewDevice(rawValue: "iPhone 15 Pro")
    static let iPhone15ProMax = PreviewDevice(rawValue: "iPhone 15 Pro Max")
    static let iPhoneSE = PreviewDevice(rawValue: "iPhone SE (3rd generation)")
    static let iPadPro12 = PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)")
}

// MARK: - Preview Trait Helpers

extension PreviewTrait where T == Preview.ViewTraits {
    /// Standard preview sizes for common devices
    static var previewDevices: [PreviewTrait<Preview.ViewTraits>] {
        [
            .previewDevice("iPhone 15 Pro"),
            .previewDevice("iPhone 15 Pro Max"),
            .previewDevice("iPhone SE (3rd generation)")
        ]
    }
    
    /// Preview with different color schemes
    static var colorSchemes: [PreviewTrait<Preview.ViewTraits>] {
        [
            .previewDisplayName("Light"),
            .previewDisplayName("Dark")
                .previewColorScheme(.dark)
        ]
    }
    
    /// Preview with different Dynamic Type sizes
    static var dynamicTypeSizes: [PreviewTrait<Preview.ViewTraits>] {
        [
            .previewDisplayName("XS")
                .previewDynamicTypeSize(.xSmall),
            .previewDisplayName("Default")
                .previewDynamicTypeSize(.medium),
            .previewDisplayName("Accessibility XXXL")
                .previewDynamicTypeSize(.xxxLarge)
        ]
    }
    
    /// Compact device with dark mode
    static var compactDark: PreviewTrait<Preview.ViewTraits> {
        .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE - Dark")
            .previewColorScheme(.dark)
    }
    
    /// Large device with light mode
    static var largeLight: PreviewTrait<Preview.ViewTraits> {
        .previewDevice("iPhone 15 Pro Max")
            .previewDisplayName("iPhone 15 Pro Max - Light")
    }
}

// MARK: - View Modifiers for Previews

extension View {
    /// Wraps view in navigation stack for preview
    func previewInNavigation(title: String = "") -> some View {
        NavigationStack {
            self
                .navigationTitle(title)
        }
    }
    
    /// Applies preview styling with padding and background
    func previewLayout() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
    }
    
    /// Wraps view in ScrollView for preview
    func previewInScrollView() -> some View {
        ScrollView {
            self
        }
    }
    
    /// Applies fixed size for component previews
    func previewFixedSize(width: CGFloat = 375, height: CGFloat = 200) -> some View {
        self
            .frame(width: width, height: height)
    }
}

// MARK: - Preview State Wrappers

/// Helper for previewing views with @State bindings
struct PreviewStateWrapper<Content: View>: View {
    @State private var value: Any
    private let content: (Binding<Any>) -> Content
    
    init<T>(initialValue: T, @ViewBuilder content: @escaping (Binding<T>) -> Content) {
        self._value = State(initialValue: initialValue as Any)
        self.content = { binding in
            content(Binding(
                get: { binding.wrappedValue as! T },
                set: { binding.wrappedValue = $0 }
            ))
        }
    }
    
    var body: some View {
        content($value)
    }
}

// MARK: - Preview Data State Helpers

enum PreviewDataState {
    case empty
    case loading
    case populated
    case error(String)
    case partial
}

// MARK: - Preview Macro Helpers

/// Creates multiple previews with different configurations
struct MultiPreview<Content: View>: View {
    let content: Content
    let configurations: [String: (AnyView) -> AnyView]
    
    init(
        @ViewBuilder content: () -> Content,
        configurations: [String: (AnyView) -> AnyView] = [:]
    ) {
        self.content = content()
        self.configurations = configurations
    }
    
    var body: some View {
        content
    }
}

// MARK: - Sample Environment Values

extension EnvironmentValues {
    /// Preview-only flag to detect preview environment
    var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}

// MARK: - Preview Formatters

extension DateFormatter {
    static let previewDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension NumberFormatter {
    static let previewCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    static let previewDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

// MARK: - Preview Color Extensions

extension Color {
    static let previewBackground = Color(.systemBackground)
    static let previewSecondaryBackground = Color(.secondarySystemBackground)
    static let previewGroupedBackground = Color(.systemGroupedBackground)
}

#endif

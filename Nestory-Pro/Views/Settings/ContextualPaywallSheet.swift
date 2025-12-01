//
//  ContextualPaywallSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// P2-13-2: Contextual Paywall Sheet - Marketing Layout
// ============================================================================
// Updates:
// - Hero icon (120pt) with NestoryTheme styling
// - Benefits list in card with checkmarks
// - Primary CTA with .borderedProminent, .controlSize(.large)
// - Secondary "Maybe Later" button
// - Restore Purchases link
// - .presentationDetents([.medium, .large])
// ============================================================================

import SwiftUI
import StoreKit

/// Context-specific paywall presentation types
enum PaywallContext: Equatable {
    case itemLimit
    case lossListLimit
    case photosInPDF
    case csvExport

    var icon: String {
        switch self {
        case .itemLimit:
            return "infinity"
        case .lossListLimit:
            return "list.bullet.rectangle.fill"
        case .photosInPDF:
            return "photo.fill"
        case .csvExport:
            return "tablecells.fill"
        }
    }

    var headline: String {
        switch self {
        case .itemLimit:
            return "Unlock Unlimited Items"
        case .lossListLimit:
            return "Unlimited Loss Reports"
        case .photosInPDF:
            return "Photos in PDF Reports"
        case .csvExport:
            return "Export to CSV"
        }
    }

    var description: String {
        switch self {
        case .itemLimit:
            return "You've reached the 100-item limit on the free plan. Upgrade to Nestory Pro to document unlimited items."
        case .lossListLimit:
            return "Free accounts can include up to 20 items in loss reports. Upgrade to Pro for unlimited items in loss lists."
        case .photosInPDF:
            return "Include item photos in your PDF inventory reports. Perfect for insurance documentation."
        case .csvExport:
            return "Export your inventory to CSV format for use with spreadsheets and third-party tools."
        }
    }
}

/// Contextual paywall sheet for feature-specific upgrade prompts
struct ContextualPaywallSheet: View {
    let context: PaywallContext

    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @State private var product: Product?
    @State private var isLoadingProduct = true
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
                    // Already Pro State
                    if env.iapValidator.isProUnlocked {
                        alreadyProView
                    } else {
                        // Upgrade Required State
                        upgradeRequiredView
                    }
                }
                .padding(.vertical, NestoryTheme.Metrics.spacingXXLarge)
            }
            .background(NestoryTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier(AccessibilityIdentifiers.Pro.closeButton)
                }
            }
            .task {
                await loadProduct()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: env.iapValidator.isProUnlocked) { _, isUnlocked in
                if isUnlocked {
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large]) // P2-13-2
        .presentationDragIndicator(.visible)
    }

    // MARK: - Already Pro View (P2-13-2)

    private var alreadyProView: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(NestoryTheme.Colors.success)

            // Success Message
            VStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                Text("You're All Set!")
                    .font(NestoryTheme.Typography.largeTitle)
                    .fontWeight(.bold)

                Text("This feature is already unlocked with your Pro subscription.")
                    .font(NestoryTheme.Typography.body)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NestoryTheme.Metrics.spacingXLarge)
            }

            // Dismiss Button (P2-13-2: .borderedProminent, .controlSize(.large))
            Button("Continue") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, NestoryTheme.Metrics.spacingXLarge)
            .padding(.top, NestoryTheme.Metrics.spacingMedium)
        }
    }

    // MARK: - Upgrade Required View (P2-13-2)

    private var upgradeRequiredView: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
            // Hero Icon (120pt) - P2-13-2
            Image(systemName: context.icon)
                .font(.system(size: 120))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            // Context-specific Headline & Description
            VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                Text("Upgrade to Nestory Pro")
                    .font(NestoryTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(context.headline)
                    .font(NestoryTheme.Typography.title2)
                    .foregroundStyle(NestoryTheme.Colors.accent)

                Text(context.description)
                    .font(NestoryTheme.Typography.body)
                    .foregroundStyle(NestoryTheme.Colors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NestoryTheme.Metrics.spacingXLarge)
            }

            // Benefits card with checkmarks (P2-13-2)
            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
                ContextualBenefitRow(icon: "checkmark.circle.fill", text: "Unlimited items")
                ContextualBenefitRow(icon: "checkmark.circle.fill", text: "Photos in PDF reports")
                ContextualBenefitRow(icon: "checkmark.circle.fill", text: "CSV & JSON exports")
                ContextualBenefitRow(icon: "checkmark.circle.fill", text: "Unlimited loss lists")
            }
            .padding(NestoryTheme.Metrics.paddingMedium)
            .background(NestoryTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            .padding(.horizontal, NestoryTheme.Metrics.spacingXLarge)

            // Price Display
            VStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                if isLoadingProduct {
                    ProgressView()
                        .frame(height: 48)
                } else if let product = product {
                    Text(product.displayPrice)
                        .font(.system(size: 48, weight: .bold))

                    Text("One-time payment • No subscriptions")
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                } else {
                    Text("$19.99")
                        .font(.system(size: 48, weight: .bold))

                    Text("One-time payment • No subscriptions")
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }

            // Primary CTA (P2-13-2: .borderedProminent, .controlSize(.large))
            Button {
                Task {
                    await purchasePro()
                }
            } label: {
                if env.iapValidator.isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Upgrade to Pro")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(env.iapValidator.isPurchasing || isLoadingProduct)
            .accessibilityIdentifier(AccessibilityIdentifiers.Pro.purchaseButton)

            // Secondary "Maybe Later" button (P2-13-2)
            Button("Maybe Later") {
                dismiss()
            }
            .font(NestoryTheme.Typography.subheadline)
            .foregroundStyle(NestoryTheme.Colors.muted)

            // Restore Purchases Link
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.accent)
            }
            .disabled(env.iapValidator.isPurchasing)
            .accessibilityIdentifier(AccessibilityIdentifiers.Pro.restorePurchasesButton)

            // Legal Links (footnote style - P2-13-2)
            HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                Link("Terms", destination: URL(string: "https://nestory-support.netlify.app/terms")!)
                Link("Privacy", destination: URL(string: "https://nestory-support.netlify.app/privacy")!)
            }
            .font(NestoryTheme.Typography.caption2)
            .foregroundStyle(NestoryTheme.Colors.muted)
        }
    }

    // MARK: - Actions (P2-16-1: Haptic feedback)

    private func loadProduct() async {
        isLoadingProduct = true

        do {
            product = try await env.iapValidator.fetchProduct()
        } catch {
            errorMessage = "Failed to load product: \(error.localizedDescription)"
            showingError = true
            NestoryTheme.Haptics.error() // P2-16-2
        }

        isLoadingProduct = false
    }

    private func purchasePro() async {
        do {
            try await env.iapValidator.purchase()
            NestoryTheme.Haptics.success() // P2-16-1: Success on purchase
            // Success - dismiss handled by onChange
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            NestoryTheme.Haptics.error() // P2-16-2
        }
    }

    private func restorePurchases() async {
        do {
            try await env.iapValidator.restorePurchases()
            // Success - dismiss handled by onChange if Pro unlocked

            // If still not Pro after restore, show message
            if !env.iapValidator.isProUnlocked {
                errorMessage = "No previous purchases found. Please purchase Nestory Pro to unlock this feature."
                showingError = true
                NestoryTheme.Haptics.warning() // P2-16-2
            } else {
                NestoryTheme.Haptics.success() // P2-16-1
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            NestoryTheme.Haptics.error() // P2-16-2
        }
    }
}

// MARK: - Contextual Benefit Row (P2-13-2)

/// Simple benefit row with checkmark icon for the benefits card
private struct ContextualBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(NestoryTheme.Colors.success)

            Text(text)
                .font(NestoryTheme.Typography.body)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Pro Feature Row

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: NestoryTheme.Metrics.spacingMedium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingXSmall) {
                Text(title)
                    .font(NestoryTheme.Typography.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(NestoryTheme.Typography.caption)
                    .foregroundStyle(NestoryTheme.Colors.muted)
            }
        }
    }
}

// MARK: - Previews

#Preview("Item Limit") {
    ContextualPaywallSheet(context: .itemLimit)
}

#Preview("Loss List Limit") {
    ContextualPaywallSheet(context: .lossListLimit)
}

#Preview("Photos in PDF") {
    ContextualPaywallSheet(context: .photosInPDF)
}

#Preview("CSV Export") {
    ContextualPaywallSheet(context: .csvExport)
}

#Preview("Already Pro - Item Limit") {
    // Note: In actual app, IAPValidator.shared.isProUnlocked would be true
    // For preview purposes, you would need to mock this or use .simulateProUnlock() in debug
    ContextualPaywallSheet(context: .itemLimit)
}

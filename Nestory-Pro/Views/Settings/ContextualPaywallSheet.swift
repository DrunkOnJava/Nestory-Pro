//
//  ContextualPaywallSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//
//  CLAUDE CODE AGENT: Task 4.4.1 - Contextual Paywall Sheet
//  Reference: TODO.md
//

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
    @State private var iapValidator = IAPValidator.shared
    @State private var product: Product?
    @State private var isLoadingProduct = true
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Already Pro State
                    if iapValidator.isProUnlocked {
                        alreadyProView
                    } else {
                        // Upgrade Required State
                        upgradeRequiredView
                    }
                }
                .padding(.vertical, 40)
            }
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
            .onChange(of: iapValidator.isProUnlocked) { _, isUnlocked in
                if isUnlocked {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Already Pro View

    private var alreadyProView: some View {
        VStack(spacing: 24) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            // Success Message
            VStack(spacing: 8) {
                Text("You're All Set!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("This feature is already unlocked with your Pro subscription.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Dismiss Button
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Upgrade Required View

    private var upgradeRequiredView: some View {
        VStack(spacing: 32) {
            // Feature Icon
            Image(systemName: context.icon)
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            // Context-specific Headline & Description
            VStack(spacing: 12) {
                Text(context.headline)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(context.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 32)

            // Pro Features List
            VStack(alignment: .leading, spacing: 16) {
                ProFeatureRow(
                    icon: "infinity",
                    title: "Unlimited Items",
                    description: "No limits on inventory size"
                )

                ProFeatureRow(
                    icon: "photo.fill",
                    title: "Photos in Reports",
                    description: "Include photos in PDFs"
                )

                ProFeatureRow(
                    icon: "tablecells.fill",
                    title: "Advanced Exports",
                    description: "CSV and JSON formats"
                )

                ProFeatureRow(
                    icon: "list.bullet.rectangle.fill",
                    title: "Unlimited Loss Lists",
                    description: "No item limits in reports"
                )
            }
            .padding(.horizontal, 32)

            // Price Display
            VStack(spacing: 8) {
                if isLoadingProduct {
                    ProgressView()
                        .frame(height: 48)
                } else if let product = product {
                    Text(product.displayPrice)
                        .font(.system(size: 44, weight: .bold))

                    Text("One-time payment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("$19.99")
                        .font(.system(size: 44, weight: .bold))

                    Text("One-time payment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)

            // Purchase Button
            Button {
                Task {
                    await purchasePro()
                }
            } label: {
                if iapValidator.isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Upgrade to Pro")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(iapValidator.isPurchasing || isLoadingProduct)
            .padding(.horizontal, 24)
            .accessibilityIdentifier(AccessibilityIdentifiers.Pro.purchaseButton)

            // Restore Purchases Link
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(iapValidator.isPurchasing)
            .accessibilityIdentifier(AccessibilityIdentifiers.Pro.restorePurchasesButton)

            // Legal Links
            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://nestory.app/terms")!)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link("Privacy", destination: URL(string: "https://nestory.app/privacy")!)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Actions

    private func loadProduct() async {
        isLoadingProduct = true

        do {
            product = try await iapValidator.fetchProduct()
        } catch {
            errorMessage = "Failed to load product: \(error.localizedDescription)"
            showingError = true
        }

        isLoadingProduct = false
    }

    private func purchasePro() async {
        do {
            try await iapValidator.purchase()
            // Success - dismiss handled by onChange
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func restorePurchases() async {
        do {
            try await iapValidator.restorePurchases()
            // Success - dismiss handled by onChange if Pro unlocked

            // If still not Pro after restore, show message
            if !iapValidator.isProUnlocked {
                errorMessage = "No previous purchases found. Please purchase Nestory Pro to unlock this feature."
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Pro Feature Row

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

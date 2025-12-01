//
//  OnboardingView.swift
//  Nestory-Pro
//
//  Created for v1.2 - P2-01
//

// ============================================================================
// ONBOARDING VIEW
// ============================================================================
// Task P2-01: First-time user onboarding flow
// - 3-screen guided setup with page indicators
// - TipKit hints for best practices
// - Smooth path from install → first item → "Aha!" moment
//
// SEE: TODO.md P2-01 | SettingsManager.swift | Tips.swift
// ============================================================================

import SwiftUI
import Combine

/// First-time user onboarding flow with 3 screens
struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil

    @State private var currentPage = 0
    @State private var isAnimating = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.view)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding()
                    .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.skipButton)
                }

                // Page content
                TabView(selection: $currentPage) {
                    WelcomeScreen()
                        .tag(0)
                    HowItWorksScreen()
                        .tag(1)
                    GetStartedScreen()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundStyle(.primary)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.backButton)
                    }

                    Button {
                        handleNextButton()
                    } label: {
                        HStack {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                            if currentPage < totalPages - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityIdentifier(
                        currentPage == totalPages - 1
                            ? AccessibilityIdentifiers.Onboarding.getStartedButton
                            : AccessibilityIdentifiers.Onboarding.nextButton
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .animation(.easeInOut, value: currentPage)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                isAnimating = true
            }
        }
    }

    private func handleNextButton() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        appEnv.settings.hasCompletedOnboarding = true
        onComplete?()
        dismiss()
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomeScreen: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon/logo
            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAnimating)

            VStack(spacing: 16) {
                Text("Welcome to Nestory")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)

                Text("Your home inventory, simplified.\nDocument what matters for insurance and peace of mind.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
            }

            Spacer()
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

// MARK: - Screen 2: How It Works

private struct HowItWorksScreen: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("How It Works")
                .font(.system(size: 28, weight: .bold))
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5), value: isAnimating)

            VStack(spacing: 32) {
                OnboardingFeatureRow(
                    icon: "camera.fill",
                    title: "Capture Quickly",
                    description: "Snap photos, scan receipts, or use barcodes",
                    delay: 0.1
                )

                OnboardingFeatureRow(
                    icon: "folder.fill",
                    title: "Organize by Room",
                    description: "Group items by location for easy insurance claims",
                    delay: 0.2
                )

                OnboardingFeatureRow(
                    icon: "doc.text.fill",
                    title: "Export Reports",
                    description: "Generate PDF reports ready for insurance providers",
                    delay: 0.3
                )
            }
            .padding(.horizontal, 32)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)

            Spacer()
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double

    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screen 3: Get Started

private struct GetStartedScreen: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)

                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Tap to add")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.7)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: isAnimating)
            }

            VStack(spacing: 16) {
                Text("Ready to Start?")
                    .font(.system(size: 28, weight: .bold))
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: isAnimating)

                VStack(spacing: 12) {
                    TipItem(
                        icon: "photo",
                        text: "Add your first item from the Inventory tab",
                        delay: 0.4
                    )
                    TipItem(
                        icon: "arrow.left.arrow.right",
                        text: "Swipe left on items for quick actions",
                        delay: 0.5
                    )
                    TipItem(
                        icon: "checkmark.shield",
                        text: "Aim for 80%+ documentation score",
                        delay: 0.6
                    )
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

private struct TipItem: View {
    let icon: String
    let text: String
    let delay: Double

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(x: isVisible ? 0 : -15)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Onboarding Flow") {
    OnboardingView()
        .environment(AppEnvironment())
}

#Preview("Welcome Screen") {
    WelcomeScreen()
}

#Preview("How It Works") {
    HowItWorksScreen()
}

#Preview("Get Started") {
    GetStartedScreen()
}
#endif

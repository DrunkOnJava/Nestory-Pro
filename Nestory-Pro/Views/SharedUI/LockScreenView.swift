//
//  LockScreenView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// TASK 6.2.2: App Lock Flow
// ============================================================================
// Shows lock screen on app foreground if biometric lock is enabled.
//
// FEATURES:
// - Face ID / Touch ID / Optic ID authentication
// - Fallback to device passcode
// - Beautiful blur overlay with app icon
// - Respects lockAfterInactivity setting (future enhancement)
//
// SEE: TODO.md Task 6.2.2 | AppLockService.swift | SettingsManager.swift
// ============================================================================

import SwiftUI

struct LockScreenView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var isLocked: Bool
    
    @State private var isAuthenticating = false
    @State private var authError: String?
    @State private var biometricType: BiometricType = .none
    
    var body: some View {
        ZStack {
            // Blur background
            NestoryTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: NestoryTheme.Metrics.spacingXXLarge) {
                Spacer()

                // App icon
                Image(systemName: "house.fill")
                    .font(.system(size: NestoryTheme.Metrics.iconHero))
                    .foregroundStyle(NestoryTheme.Colors.accent)
                    .padding(NestoryTheme.Metrics.paddingMedium)
                    .background(NestoryTheme.Colors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusXLarge))
                    .accessibilityHidden(true)

                // Title
                VStack(spacing: NestoryTheme.Metrics.spacingSmall) {
                    Text("Nestory Pro")
                        .font(NestoryTheme.Typography.title)

                    Text("Unlock to access your inventory")
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Nestory Pro. Unlock to access your inventory.")

                Spacer()

                // Unlock button
                VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                    Button(action: authenticate) {
                        HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                            if isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: biometricIconName)
                                    .accessibilityIdentifier(AccessibilityIdentifiers.LockScreen.biometricIcon)
                            }
                            Text(unlockButtonText)
                        }
                        .font(NestoryTheme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(NestoryTheme.Metrics.paddingMedium)
                        .background(NestoryTheme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
                    }
                    .disabled(isAuthenticating)
                    .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
                    .accessibilityIdentifier(AccessibilityIdentifiers.LockScreen.unlockButton)
                    .accessibilityLabel(isAuthenticating ? "Authenticating" : unlockButtonText)
                    .accessibilityHint("Double-tap to unlock with \(biometricTypeDescription)")

                    if let error = authError {
                        Text(error)
                            .font(NestoryTheme.Typography.caption)
                            .foregroundStyle(NestoryTheme.Colors.error)
                            .accessibilityLabel("Error: \(error)")
                    }
                }
                .padding(.bottom, NestoryTheme.Metrics.spacingXXLarge)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.LockScreen.screen)
        .task {
            biometricType = await env.appLockService.biometricType
            // Auto-authenticate on appear
            await authenticateAsync()
        }
    }
    
    // MARK: - Computed Properties
    
    private var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
    
    private var unlockButtonText: String {
        switch biometricType {
        case .faceID:
            return "Unlock with Face ID"
        case .touchID:
            return "Unlock with Touch ID"
        case .opticID:
            return "Unlock with Optic ID"
        case .none:
            return "Unlock with Passcode"
        }
    }

    private var biometricTypeDescription: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "device passcode"
        }
    }
    
    // MARK: - Authentication
    
    private func authenticate() {
        Task {
            await authenticateAsync()
        }
    }
    
    private func authenticateAsync() async {
        guard !isAuthenticating else { return }
        
        isAuthenticating = true
        authError = nil
        
        let success = await env.appLockService.authenticate(reason: "Unlock Nestory Pro to access your inventory")
        
        isAuthenticating = false
        
        if success {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLocked = false
            }
        } else {
            authError = "Authentication failed. Please try again."
        }
    }
}

// MARK: - Preview

#Preview {
    LockScreenView(isLocked: .constant(true))
        .environment(AppEnvironment())
}

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
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App icon
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Title
                VStack(spacing: 8) {
                    Text("Nestory Pro")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unlock to access your inventory")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Unlock button
                VStack(spacing: 16) {
                    Button(action: authenticate) {
                        HStack(spacing: 12) {
                            if isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: biometricIconName)
                            }
                            Text(unlockButtonText)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isAuthenticating)
                    .padding(.horizontal, 48)
                    
                    if let error = authError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 60)
            }
        }
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

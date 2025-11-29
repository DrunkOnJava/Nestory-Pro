//
//  AppLockService.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import Foundation
import LocalAuthentication

/// Service for handling biometric authentication and app lock
/// Uses LocalAuthentication framework for Face ID / Touch ID / Optic ID
@MainActor
final class AppLockService: AppLockProviding, Sendable {
    
    // MARK: - Private State
    
    private let context: LAContext
    
    // MARK: - Initialization
    
    init() {
        self.context = LAContext()
    }
    
    // MARK: - AppLockProviding
    
    /// Check if biometric authentication is available on device
    var isBiometricAvailable: Bool {
        get async {
            var error: NSError?
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        }
    }
    
    /// Get the type of biometric authentication available
    var biometricType: BiometricType {
        get async {
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return .none
            }
            
            switch context.biometryType {
            case .none:
                return .none
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            case .opticID:
                return .opticID
            @unknown default:
                return .none
            }
        }
    }
    
    /// Request biometric authentication
    /// - Parameter reason: The reason shown to user in authentication prompt
    /// - Returns: True if authentication succeeded, false otherwise
    func authenticate(reason: String) async -> Bool {
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to device passcode if biometrics not available
            return await authenticateWithDevicePasscode(reason: reason)
        }
        
        do {
            // Attempt biometric authentication
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let authError as LAError {
            // Handle specific LocalAuthentication errors
            switch authError.code {
            case .userFallback:
                // User chose to use passcode instead
                return await authenticateWithDevicePasscode(reason: reason)
            case .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
                // Fall back to device passcode
                return await authenticateWithDevicePasscode(reason: reason)
            case .userCancel, .systemCancel, .appCancel:
                // User or system cancelled authentication
                return false
            case .authenticationFailed:
                // Biometric authentication failed (wrong face/finger)
                return false
            default:
                // Other errors - fail authentication
                return false
            }
        } catch {
            // Unexpected error
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    /// Fallback to device passcode authentication
    private func authenticateWithDevicePasscode(reason: String) async -> Bool {
        // Create new context for passcode authentication
        let passcodeContext = LAContext()
        
        do {
            let success = try await passcodeContext.evaluatePolicy(
                .deviceOwnerAuthentication, // Allows biometrics OR passcode
                localizedReason: reason
            )
            return success
        } catch {
            return false
        }
    }
}

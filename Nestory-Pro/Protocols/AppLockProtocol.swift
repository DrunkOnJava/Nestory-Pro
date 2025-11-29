//
//  AppLockProtocol.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import Foundation

/// Protocol for biometric authentication and app lock functionality
@MainActor
protocol AppLockProviding: Sendable {
    
    /// Check if biometric authentication is available on device
    var isBiometricAvailable: Bool { get async }
    
    /// Get the type of biometric authentication available (Face ID, Touch ID, etc.)
    var biometricType: BiometricType { get async }
    
    /// Request biometric authentication
    /// - Parameter reason: The reason shown to user in authentication prompt
    /// - Returns: True if authentication succeeded, false otherwise
    func authenticate(reason: String) async -> Bool
}

/// Types of biometric authentication available
enum BiometricType: Sendable {
    case none
    case faceID
    case touchID
    case opticID
    
    var displayName: String {
        switch self {
        case .none:
            return String(localized: "None", comment: "Biometric type: no biometric available")
        case .faceID:
            return String(localized: "Face ID", comment: "Biometric type: Face ID")
        case .touchID:
            return String(localized: "Touch ID", comment: "Biometric type: Touch ID")
        case .opticID:
            return String(localized: "Optic ID", comment: "Biometric type: Optic ID")
        }
    }
}

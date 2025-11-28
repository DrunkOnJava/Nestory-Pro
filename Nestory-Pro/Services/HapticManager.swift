//
//  HapticManager.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import UIKit

/// Manages haptic feedback across the app
/// Respects system haptic settings and provides consistent feedback patterns
@MainActor
enum HapticManager {

    // MARK: - Generator Instances

    private static var impactLight: UIImpactFeedbackGenerator?
    private static var impactMedium: UIImpactFeedbackGenerator?
    private static var impactHeavy: UIImpactFeedbackGenerator?
    private static var notificationGenerator: UINotificationFeedbackGenerator?
    private static var selectionGenerator: UISelectionFeedbackGenerator?

    // MARK: - Public Feedback Methods

    /// Triggers success haptic feedback
    /// Use for: successful saves, completed actions, confirmations
    static func success() {
        guard isHapticsEnabled else { return }
        prepareNotificationGenerator()
        notificationGenerator?.notificationOccurred(.success)
    }

    /// Triggers error haptic feedback
    /// Use for: validation errors, failed actions, alerts
    static func error() {
        guard isHapticsEnabled else { return }
        prepareNotificationGenerator()
        notificationGenerator?.notificationOccurred(.error)
    }

    /// Triggers warning haptic feedback
    /// Use for: warnings, confirmations before destructive actions
    static func warning() {
        guard isHapticsEnabled else { return }
        prepareNotificationGenerator()
        notificationGenerator?.notificationOccurred(.warning)
    }

    /// Triggers selection haptic feedback
    /// Use for: picking items from lists, segmented controls, toggles
    static func selection() {
        guard isHapticsEnabled else { return }
        prepareSelectionGenerator()
        selectionGenerator?.selectionChanged()
    }

    /// Triggers light impact haptic feedback
    /// Use for: button taps, minor interactions
    static func lightImpact() {
        guard isHapticsEnabled else { return }
        prepareImpactGenerator(.light)
        impactLight?.impactOccurred()
    }

    /// Triggers medium impact haptic feedback
    /// Use for: medium-weight buttons, swipe actions
    static func mediumImpact() {
        guard isHapticsEnabled else { return }
        prepareImpactGenerator(.medium)
        impactMedium?.impactOccurred()
    }

    /// Triggers heavy impact haptic feedback
    /// Use for: important actions, drag and drop
    static func heavyImpact() {
        guard isHapticsEnabled else { return }
        prepareImpactGenerator(.heavy)
        impactHeavy?.impactOccurred()
    }

    // MARK: - Specialized Feedback

    /// Triggers feedback for item deletion
    static func itemDeleted() {
        mediumImpact()
    }

    /// Triggers feedback for item creation
    static func itemCreated() {
        success()
    }

    /// Triggers feedback for item update
    static func itemUpdated() {
        lightImpact()
    }

    /// Triggers feedback for photo capture
    static func photoCaptured() {
        mediumImpact()
    }

    /// Triggers feedback for barcode scan
    static func barcodeScanned() {
        success()
    }

    /// Triggers feedback for report generation
    static func reportGenerated() {
        success()
    }

    // MARK: - Generator Preparation

    private static func prepareNotificationGenerator() {
        if notificationGenerator == nil {
            notificationGenerator = UINotificationFeedbackGenerator()
        }
        notificationGenerator?.prepare()
    }

    private static func prepareSelectionGenerator() {
        if selectionGenerator == nil {
            selectionGenerator = UISelectionFeedbackGenerator()
        }
        selectionGenerator?.prepare()
    }

    private static func prepareImpactGenerator(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            if impactLight == nil {
                impactLight = UIImpactFeedbackGenerator(style: .light)
            }
            impactLight?.prepare()
        case .medium:
            if impactMedium == nil {
                impactMedium = UIImpactFeedbackGenerator(style: .medium)
            }
            impactMedium?.prepare()
        case .heavy:
            if impactHeavy == nil {
                impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
            }
            impactHeavy?.prepare()
        case .rigid, .soft:
            break
        @unknown default:
            break
        }
    }

    // MARK: - System Settings

    /// Checks if haptics are enabled at the system level
    /// Returns true if the device supports haptics and they're not disabled
    private static var isHapticsEnabled: Bool {
        // Check if device supports haptic feedback
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return false
        }

        // On iOS, haptics are always enabled unless the device doesn't support them
        // There's no public API to check if user has disabled haptics system-wide
        return true
    }

    // MARK: - Resource Management

    /// Resets all haptic generators to free up resources
    /// Call this when the app enters background or during memory warnings
    static func reset() {
        impactLight = nil
        impactMedium = nil
        impactHeavy = nil
        notificationGenerator = nil
        selectionGenerator = nil
    }
}

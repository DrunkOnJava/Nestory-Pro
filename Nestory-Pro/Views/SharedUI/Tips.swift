//
//  Tips.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// CLAUDE CODE AGENT: TIPKIT TIPS
// ============================================================================
// Task 8.3.1-8.3.3: TipKit integration for user guidance
// - Documentation score tip: Shown on inventory with score < 70%
// - iCloud sync tip: Shown when user enables iCloud
// - Pro features tip: Shown when user hits a limit
//
// SEE: TODO.md Phase 8.3
// ============================================================================

import TipKit

// MARK: - Documentation Score Tip

/// Tip shown when user first visits inventory with documentation score < 70%
struct DocumentationScoreTip: Tip {
    // Show if user hasn't seen this tip and documentation is low
    @Parameter
    static var hasSeenDocumentationTip: Bool = false

    @Parameter
    static var documentationScoreIsLow: Bool = false

    var title: Text {
        Text("Improve Your Documentation")
    }

    var message: Text? {
        Text("Well-documented items get faster insurance claim approvals. Add photos, purchase prices, and receipts to reach 80%+ documentation score.")
    }

    var image: Image? {
        Image(systemName: "checkmark.shield.fill")
    }

    var actions: [Action] {
        Action(id: "learn-more", title: "Learn More")
    }

    var rules: [Rule] {
        #Rule(Self.$hasSeenDocumentationTip) { hasSeenTip in
            hasSeenTip == false
        }
        #Rule(Self.$documentationScoreIsLow) { isLow in
            isLow == true
        }
    }
}

// MARK: - iCloud Sync Tip

/// Tip shown when user enables iCloud sync
struct iCloudSyncTip: Tip {
    @Parameter
    static var iCloudSyncJustEnabled: Bool = false

    var title: Text {
        Text("iCloud Sync Enabled")
    }

    var message: Text? {
        Text("Your inventory will sync across all your devices signed into the same iCloud account. Changes may take a few moments to appear.")
    }

    var image: Image? {
        Image(systemName: "icloud.fill")
    }

    var rules: [Rule] {
        #Rule(Self.$iCloudSyncJustEnabled) { justEnabled in
            justEnabled == true
        }
    }
}

// MARK: - Pro Features Tip

/// Tip shown when user hits a free tier limit
struct ProFeaturesTip: Tip {
    @Parameter
    static var hasHitLimit: Bool = false

    var title: Text {
        Text("Unlock Nestory Pro")
    }

    var message: Text? {
        Text("Get unlimited items, photos in PDF reports, CSV export, and more with a one-time purchase.")
    }

    var image: Image? {
        Image(systemName: "star.fill")
    }

    var actions: [Action] {
        Action(id: "upgrade", title: "Learn More")
    }

    var rules: [Rule] {
        #Rule(Self.$hasHitLimit) { hitLimit in
            hitLimit == true
        }
    }
}

// MARK: - Quick Capture Tip

/// Tip shown on first visit to capture tab
struct QuickCaptureTip: Tip {
    var title: Text {
        Text("Quick Capture")
    }

    var message: Text? {
        Text("Quickly document items by snapping photos, scanning receipts, or reading barcodes. You can add more details later.")
    }

    var image: Image? {
        Image(systemName: "camera.fill")
    }
}

// MARK: - TipKit Configuration

/// Configure TipKit for the app
enum TipsConfiguration {
    /// Configure TipKit on app launch
    @MainActor
    static func configure() {
        do {
            // Configure tips with sensible defaults
            try Tips.configure([
                // Show tips at most once per day
                .displayFrequency(.daily),
                // Store tips data in the default location
                .datastoreLocation(.applicationDefault)
            ])
        } catch {
            // TipKit configuration failed - tips won't show, but app continues
            print("TipKit configuration failed: \(error)")
        }
    }

    #if DEBUG
    /// Reset all tips for testing (debug only)
    @MainActor
    static func resetAllTips() {
        do {
            try Tips.resetDatastore()
        } catch {
            print("Failed to reset tips: \(error)")
        }
    }

    /// Show all tips immediately for testing (debug only)
    @MainActor
    static func showAllTipsForTesting() {
        do {
            Tips.showAllTipsForTesting()
        }
    }
    #endif
}

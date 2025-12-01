//
//  NotificationDelegate.swift
//  Nestory-Pro
//
//  Created for v1.2 - Warranty Reminder Feature
//

// ============================================================================
// NOTIFICATION DELEGATE - Task F1
// ============================================================================
// Handles notification taps and actions for warranty reminders.
// - VIEW_ITEM action: Navigates to the item detail
// - DISMISS action: Dismisses the notification
//
// SEE: ReminderService.swift | TODO-FEATURES.md F1
// ============================================================================

import UserNotifications
import SwiftUI
import Combine
import OSLog

/// Delegate for handling notification responses and actions
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "NotificationDelegate")

    /// Navigation state published for observation by the app
    @Published var selectedItemId: UUID?
    @Published var shouldNavigateToItem: Bool = false

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when notification is received while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground for warranty reminders
        return [.banner, .sound, .badge]
    }

    /// Called when user interacts with a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        // Extract item ID from notification
        guard let itemIdString = userInfo["itemId"] as? String,
              let itemId = UUID(uuidString: itemIdString) else {
            await MainActor.run {
                logger.warning("[NotificationDelegate] No valid itemId in notification")
            }
            return
        }

        await MainActor.run {
            logger.info("[NotificationDelegate] Received action: \(actionIdentifier) for item: \(itemIdString)")

            switch actionIdentifier {
            case "VIEW_ITEM", UNNotificationDefaultActionIdentifier:
                // User tapped the notification or View Item button
                navigateToItem(id: itemId)

            case "DISMISS":
                // User dismissed - no action needed
                logger.info("[NotificationDelegate] User dismissed notification for item: \(itemIdString)")

            default:
                // Default action (tapped notification body)
                navigateToItem(id: itemId)
            }
        }
    }

    // MARK: - Navigation

    /// Triggers navigation to the item detail view
    private func navigateToItem(id: UUID) {
        selectedItemId = id
        shouldNavigateToItem = true
        logger.info("[NotificationDelegate] Navigating to item: \(id.uuidString)")
    }

    /// Resets navigation state after handling
    func clearNavigation() {
        selectedItemId = nil
        shouldNavigateToItem = false
    }
}

//
//  ReminderService.swift
//  Nestory-Pro
//
//  Created for v1.2 - P5-03
//

// ============================================================================
// REMINDER SERVICE
// ============================================================================
// Task P5-03: Quick actions: inventory tasks & reminders
// - Schedules local notifications for warranty expiry
// - Manages notification permissions
// - Provides reminder scheduling for items
//
// SEE: TODO.md P5-03 | WarrantyListView.swift | Item.warrantyExpiryDate
// ============================================================================

import UserNotifications
import SwiftData
import OSLog
import Observation

/// Types of reminders supported by the app
enum ReminderType: String, Codable, Sendable {
    case warrantyExpiring = "warranty_expiring"
    case warrantyExpired = "warranty_expired"
    case reviewItem = "review_item"
    
    var title: String {
        switch self {
        case .warrantyExpiring: return "Warranty Expiring Soon"
        case .warrantyExpired: return "Warranty Expired"
        case .reviewItem: return "Time to Review"
        }
    }
    
    var categoryIdentifier: String {
        "NESTORY_\(rawValue.uppercased())"
    }
}

/// Service for managing local notifications and reminders
@Observable
@MainActor
final class ReminderService {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "ReminderService")
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private(set) var isAuthorized = false
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Number of days before warranty expiry to send reminder
    static let warrantyReminderDays = 7
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Checks current notification authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
        
        logger.info("[ReminderService] Authorization status: \(String(describing: settings.authorizationStatus))")
    }
    
    /// Requests notification permissions from the user
    /// - Returns: Whether authorization was granted
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            
            if granted {
                await registerNotificationCategories()
                logger.info("[ReminderService] Authorization granted")
            } else {
                logger.info("[ReminderService] Authorization denied")
            }
            
            await checkAuthorizationStatus()
            return granted
        } catch {
            logger.error("[ReminderService] Authorization request failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Registers notification action categories
    private func registerNotificationCategories() async {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ITEM",
            title: "View Item",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )
        
        let warrantyCategory = UNNotificationCategory(
            identifier: ReminderType.warrantyExpiring.categoryIdentifier,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let expiredCategory = UNNotificationCategory(
            identifier: ReminderType.warrantyExpired.categoryIdentifier,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([warrantyCategory, expiredCategory])
    }
    
    // MARK: - Warranty Reminders
    
    /// Schedules a warranty expiry reminder for an item
    /// - Parameters:
    ///   - item: The item with warranty to remind about
    ///   - daysBefore: Days before expiry to send reminder (default: 7)
    /// - Returns: Whether the reminder was scheduled successfully
    func scheduleWarrantyReminder(for item: Item, daysBefore: Int = warrantyReminderDays) async -> Bool {
        guard isAuthorized else {
            logger.warning("[ReminderService] Cannot schedule reminder - not authorized")
            return false
        }
        
        guard let expiryDate = item.warrantyExpiryDate else {
            logger.info("[ReminderService] No warranty date for item: \(item.name)")
            return false
        }
        
        // Calculate reminder date
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiryDate) else {
            return false
        }
        
        // Don't schedule if reminder date is in the past
        guard reminderDate > Date() else {
            logger.info("[ReminderService] Reminder date already passed for: \(item.name)")
            return false
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = ReminderType.warrantyExpiring.title
        content.body = "\(item.name)'s warranty expires in \(daysBefore) days. Consider reviewing coverage options."
        content.sound = .default
        content.categoryIdentifier = ReminderType.warrantyExpiring.categoryIdentifier
        content.userInfo = [
            "itemId": item.id.uuidString,
            "reminderType": ReminderType.warrantyExpiring.rawValue
        ]
        
        // Create trigger for the reminder date at 9 AM
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create request with unique identifier
        let identifier = "warranty_\(item.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            logger.info("[ReminderService] Scheduled warranty reminder for: \(item.name) on \(reminderDate)")
            return true
        } catch {
            logger.error("[ReminderService] Failed to schedule reminder: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Cancels a warranty reminder for an item
    func cancelWarrantyReminder(for item: Item) {
        let identifier = "warranty_\(item.id.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.info("[ReminderService] Cancelled warranty reminder for: \(item.name)")
    }
    
    /// Schedules reminders for all items with upcoming warranty expiry
    /// - Parameter context: The model context to fetch items from
    /// - Returns: Number of reminders scheduled
    func scheduleAllWarrantyReminders(context: ModelContext) async -> Int {
        guard isAuthorized else { return 0 }
        
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: now) ?? now
        
        // Fetch items with warranty expiring in next 3 months
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { item in
                item.warrantyExpiryDate != nil
            }
        )
        
        do {
            let items = try context.fetch(descriptor)
            var scheduledCount = 0
            
            for item in items {
                guard let expiryDate = item.warrantyExpiryDate,
                      expiryDate > now && expiryDate <= futureDate else {
                    continue
                }
                
                if await scheduleWarrantyReminder(for: item) {
                    scheduledCount += 1
                }
            }
            
            logger.info("[ReminderService] Scheduled \(scheduledCount) warranty reminders")
            return scheduledCount
        } catch {
            logger.error("[ReminderService] Failed to fetch items: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Clears all pending notifications
    func clearAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("[ReminderService] Cleared all pending reminders")
    }
    
    // MARK: - Pending Reminders
    
    /// Gets count of pending reminders
    func getPendingRemindersCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }
    
    /// Gets all pending reminder identifiers
    func getPendingReminderIds() async -> [String] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.map { $0.identifier }
    }
}

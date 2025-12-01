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
    case warrantyExpiring30Day = "warranty_expiring_30day"
    case warrantyExpiring7Day = "warranty_expiring_7day"
    case warrantyExpiring = "warranty_expiring"  // Day-of expiry
    case warrantyExpired = "warranty_expired"
    case reviewItem = "review_item"

    var title: String {
        switch self {
        case .warrantyExpiring30Day: return "Warranty Expiring in 30 Days"
        case .warrantyExpiring7Day: return "Warranty Expiring Soon"
        case .warrantyExpiring: return "Warranty Expires Today"
        case .warrantyExpired: return "Warranty Expired"
        case .reviewItem: return "Time to Review"
        }
    }

    var categoryIdentifier: String {
        "NESTORY_\(rawValue.uppercased())"
    }

    /// Days before expiry for this reminder type (nil = day-of or expired)
    var daysBefore: Int? {
        switch self {
        case .warrantyExpiring30Day: return 30
        case .warrantyExpiring7Day: return 7
        case .warrantyExpiring: return 0  // Day-of
        case .warrantyExpired, .reviewItem: return nil
        }
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

        // Create categories for all warranty reminder types
        let warranty30DayCategory = UNNotificationCategory(
            identifier: ReminderType.warrantyExpiring30Day.categoryIdentifier,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let warranty7DayCategory = UNNotificationCategory(
            identifier: ReminderType.warrantyExpiring7Day.categoryIdentifier,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let warrantyDayOfCategory = UNNotificationCategory(
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

        notificationCenter.setNotificationCategories([
            warranty30DayCategory,
            warranty7DayCategory,
            warrantyDayOfCategory,
            expiredCategory
        ])
    }
    
    // MARK: - Warranty Reminders

    /// Reminder intervals for warranty expiry (30-day, 7-day, day-of)
    static let warrantyReminderIntervals: [ReminderType] = [
        .warrantyExpiring30Day,
        .warrantyExpiring7Day,
        .warrantyExpiring  // Day-of
    ]

    /// Schedules all warranty reminders for an item (30-day, 7-day, day-of)
    /// - Parameter item: The item with warranty to remind about
    /// - Returns: Number of reminders scheduled
    @discardableResult
    func scheduleAllWarrantyRemindersForItem(_ item: Item) async -> Int {
        guard isAuthorized else {
            logger.warning("[ReminderService] Cannot schedule reminders - not authorized")
            return 0
        }

        guard item.warrantyExpiryDate != nil else {
            logger.info("[ReminderService] No warranty date for item: \(item.name)")
            return 0
        }

        var scheduledCount = 0
        for reminderType in Self.warrantyReminderIntervals {
            if await scheduleWarrantyReminder(for: item, type: reminderType) {
                scheduledCount += 1
            }
        }

        logger.info("[ReminderService] Scheduled \(scheduledCount) reminders for: \(item.name)")
        return scheduledCount
    }

    /// Schedules a specific warranty reminder for an item
    /// - Parameters:
    ///   - item: The item with warranty to remind about
    ///   - type: The reminder type (30-day, 7-day, or day-of)
    /// - Returns: Whether the reminder was scheduled successfully
    func scheduleWarrantyReminder(for item: Item, type: ReminderType) async -> Bool {
        guard isAuthorized else {
            logger.warning("[ReminderService] Cannot schedule reminder - not authorized")
            return false
        }

        guard let expiryDate = item.warrantyExpiryDate else {
            logger.info("[ReminderService] No warranty date for item: \(item.name)")
            return false
        }

        guard let daysBefore = type.daysBefore else {
            logger.warning("[ReminderService] Invalid reminder type for warranty: \(type.rawValue)")
            return false
        }

        // Calculate reminder date
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiryDate) else {
            return false
        }

        // Don't schedule if reminder date is in the past
        guard reminderDate > Date() else {
            logger.info("[ReminderService] Reminder date already passed for \(type.rawValue): \(item.name)")
            return false
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = notificationBody(for: item, type: type, daysBefore: daysBefore)
        content.sound = .default
        content.categoryIdentifier = type.categoryIdentifier
        content.userInfo = [
            "itemId": item.id.uuidString,
            "reminderType": type.rawValue
        ]

        // Create trigger for the reminder date at 9 AM
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Create request with unique identifier per type
        let identifier = "warranty_\(type.rawValue)_\(item.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            logger.info("[ReminderService] Scheduled \(type.rawValue) reminder for: \(item.name) on \(reminderDate)")
            return true
        } catch {
            logger.error("[ReminderService] Failed to schedule reminder: \(error.localizedDescription)")
            return false
        }
    }

    /// Generates notification body text based on reminder type
    private func notificationBody(for item: Item, type: ReminderType, daysBefore: Int) -> String {
        let itemName = item.name
        switch daysBefore {
        case 30:
            return "\(itemName)'s warranty expires in 30 days. Review your coverage options."
        case 7:
            return "\(itemName)'s warranty expires in 7 days! Consider extended warranty options."
        case 0:
            return "\(itemName)'s warranty expires today. Take action before it's too late."
        default:
            return "\(itemName)'s warranty expires in \(daysBefore) days."
        }
    }

    /// Cancels all warranty reminders for an item (30-day, 7-day, day-of)
    func cancelAllWarrantyReminders(for item: Item) {
        let identifiers = Self.warrantyReminderIntervals.map { type in
            "warranty_\(type.rawValue)_\(item.id.uuidString)"
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        logger.info("[ReminderService] Cancelled all warranty reminders for: \(item.name)")
    }

    /// Legacy method - schedules single 7-day reminder (backward compatibility)
    /// - Parameters:
    ///   - item: The item with warranty to remind about
    ///   - daysBefore: Days before expiry to send reminder (default: 7)
    /// - Returns: Whether the reminder was scheduled successfully
    func scheduleWarrantyReminder(for item: Item, daysBefore: Int = warrantyReminderDays) async -> Bool {
        await scheduleWarrantyReminder(for: item, type: .warrantyExpiring7Day)
    }

    /// Legacy method - cancels single reminder (use cancelAllWarrantyReminders for new code)
    func cancelWarrantyReminder(for item: Item) {
        let identifier = "warranty_\(item.id.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        // Also cancel new-style identifiers
        cancelAllWarrantyReminders(for: item)
        logger.info("[ReminderService] Cancelled warranty reminder for: \(item.name)")
    }
    
    /// Schedules reminders for all items with upcoming warranty expiry
    /// Uses multi-day approach (30-day, 7-day, day-of) for each item
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

                // Schedule all reminder intervals for this item
                scheduledCount += await scheduleAllWarrantyRemindersForItem(item)
            }

            logger.info("[ReminderService] Scheduled \(scheduledCount) warranty reminders for \(items.count) items")
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

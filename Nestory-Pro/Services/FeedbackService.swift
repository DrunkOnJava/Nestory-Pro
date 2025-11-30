//
//  FeedbackService.swift
//  Nestory-Pro
//
//  Created for v1.2 - P4-07
//

// ============================================================================
// FEEDBACK SERVICE
// ============================================================================
// Task P4-07: In-app feedback & support
// - Generates device info for support emails
// - Creates pre-filled email URLs with app context
// - Tracks feedback categories for roadmap analysis
//
// SEE: TODO.md P4-07 | SettingsTab.swift
// ============================================================================

import UIKit
import SwiftData
import OSLog

/// Feedback category for tracking user feedback types
enum FeedbackCategory: String, CaseIterable, Sendable {
    case general = "General Feedback"
    case bug = "Bug Report"
    case feature = "Feature Request"
    case question = "Question"
    
    var emailSubject: String {
        "[Nestory] \(rawValue)"
    }

    var icon: String {
        switch self {
        case .general: return "bubble.left"
        case .bug: return "ladybug"
        case .feature: return "lightbulb"
        case .question: return "questionmark.circle"
        }
    }
}

/// Service for managing user feedback and support interactions
struct FeedbackService: Sendable {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "FeedbackService")

    /// Support email address
    static let supportEmail = "support@nestory.app"
    
    // MARK: - Device Info

    /// Generates comprehensive device and app information for support
    ///
    /// Returns a structured text block delimited by `---` markers containing:
    /// - App version and build number
    /// - iOS version and device model (human-readable)
    /// - Locale, timezone, available storage
    ///
    /// - Returns: Formatted string suitable for email body or support ticket systems
    @MainActor
    func generateDeviceInfo() -> String {
        let device = UIDevice.current
        let bundle = Bundle.main
        
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let systemVersion = device.systemVersion
        let deviceModel = getDeviceModel()
        let locale = Locale.current.identifier
        let timezone = TimeZone.current.identifier
        
        // Get available disk space
        let diskSpace = getAvailableDiskSpace()
        
        return """
        ---
        App: Nestory Pro v\(appVersion) (\(buildNumber))
        iOS: \(systemVersion)
        Device: \(deviceModel)
        Locale: \(locale)
        Timezone: \(timezone)
        Storage Available: \(diskSpace)
        ---
        """
    }
    
    /// Gets the device model name
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return mapDeviceIdentifier(identifier)
    }
    
    /// Maps device identifier to human-readable name
    ///
    /// - Parameter identifier: Machine identifier (e.g., "iPhone16,1")
    /// - Returns: Human-readable device name or original identifier if unknown
    /// - Note: Covers iPhone 15-16 series. Earlier models and iPads show technical identifier.
    private func mapDeviceIdentifier(_ identifier: String) -> String {
        // Known iPhone models (15-16 series)
        switch identifier {
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "x86_64", "arm64": return "Simulator"
        default:
            logger.info("[FeedbackService] Unknown device identifier: \(identifier)")
            return identifier
        }
    }
    
    /// Gets available disk space in human-readable format
    ///
    /// - Returns: Formatted byte count (e.g., "45.2 GB") or descriptive error message if unable to access volume info
    /// - Note: May return error on simulator or if document directory is inaccessible
    private func getAvailableDiskSpace() -> String {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("[FeedbackService] Failed to get documents directory URL")
            return "Unknown (Documents directory unavailable)"
        }

        do {
            let values = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            guard let capacity = values.volumeAvailableCapacityForImportantUsage else {
                logger.warning("[FeedbackService] volumeAvailableCapacityForImportantUsage is nil")
                return "Unknown (Capacity query returned nil)"
            }

            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useGB, .useMB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: capacity)

        } catch {
            logger.error("[FeedbackService] Failed to query disk space: \(error.localizedDescription)")
            return "Unknown (\(error.localizedDescription))"
        }
    }
    
    // MARK: - Email Generation

    /// Creates a mailto URL for feedback email with pre-filled device info
    ///
    /// - Parameters:
    ///   - category: Type of feedback to pre-fill subject line
    ///   - additionalContext: Optional context string (e.g., "Crash in Reports tab"). Keep under 500 chars to avoid URL length limits.
    /// - Returns: Mailto URL with pre-filled subject and device info, or `nil` if encoding fails
    /// - Note: Email body includes device diagnostics automatically
    func createFeedbackEmailURL(category: FeedbackCategory, additionalContext: String? = nil) -> URL? {
        let deviceInfo = generateDeviceInfo()
        var body = "\n\n\n\(deviceInfo)"

        if let context = additionalContext {
            body = "\n\n[Context: \(context)]\n\(body)"
        }

        let subject = category.emailSubject

        // Validate encoding succeeded
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("[FeedbackService] Failed to encode subject: \(subject)")
            return nil
        }

        guard let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("[FeedbackService] Failed to encode body (length: \(body.count))")
            return nil
        }

        let urlString = "mailto:\(Self.supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)"

        guard let url = URL(string: urlString) else {
            logger.error("[FeedbackService] Failed to create mailto URL. String length: \(urlString.count)")
            return nil
        }

        return url
    }
    
    /// Creates a simple support email URL
    func createSupportEmailURL() -> URL? {
        createFeedbackEmailURL(category: .question)
    }
    
    // MARK: - Feedback Actions

    /// Opens feedback email in system mail app
    ///
    /// - Parameters:
    ///   - category: Type of feedback
    ///   - completion: Called with success/failure result on main thread
    @MainActor
    func openFeedbackEmail(category: FeedbackCategory, completion: @escaping (Bool, String?) -> Void) {
        logFeedbackEvent(category: category)

        guard let url = createFeedbackEmailURL(category: category) else {
            completion(false, "Could not prepare feedback email. Please contact \(Self.supportEmail) directly.")
            return
        }

        UIApplication.shared.open(url) { success in
            Task { @MainActor in
                if success {
                    completion(true, nil)
                } else {
                    completion(false, "Could not open email app. Please ensure Mail is configured, or contact \(Self.supportEmail) directly.")
                }
            }
        }
    }

    // MARK: - Feedback Tracking

    /// Logs feedback event for local debugging
    ///
    /// - Parameter category: Type of feedback being submitted
    /// - Note: Currently logs to OSLog only. Future versions may add analytics with user consent.
    func logFeedbackEvent(category: FeedbackCategory) {
        logger.info("[FeedbackService] Feedback initiated: \(category.rawValue)")
    }
}

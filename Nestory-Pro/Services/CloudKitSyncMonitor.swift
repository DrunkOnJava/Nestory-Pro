//
//  CloudKitSyncMonitor.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// CLAUDE CODE AGENT: CLOUDKIT SYNC MONITOR
// ============================================================================
// Task 10.1.2: Sync stability monitoring plan (debug logging)
// - Monitors CloudKit sync events via NotificationCenter
// - Logs sync start/end, errors, and conflicts
// - Only logs in DEBUG builds (not production)
// - Provides sync status observable for UI feedback
//
// SEE: TODO.md Phase 10 | SwiftData CloudKit Integration
// ============================================================================

import Foundation
import OSLog
import SwiftData
import CoreData
import Combine
import UIKit

/// Monitors CloudKit sync events and logs them for debugging
@MainActor
@Observable
final class CloudKitSyncMonitor {

    // MARK: - Singleton

    static let shared = CloudKitSyncMonitor()

    // MARK: - Observable Properties

    /// Current sync status
    var syncStatus: SyncStatus = .idle

    /// Last successful sync timestamp
    var lastSyncDate: Date?

    /// Recent sync events for debugging (max 50)
    private(set) var recentEvents: [SyncEvent] = []

    /// Whether sync is currently in progress
    var isSyncing: Bool {
        syncStatus == .syncing
    }

    /// Human-readable sync status text
    var statusText: String {
        switch syncStatus {
        case .idle:
            if let lastSync = lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return "Synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            }
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .error(let message):
            return "Sync error: \(message)"
        case .disabled:
            return "iCloud sync disabled"
        case .notAvailable:
            return "iCloud not available"
        }
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "CloudKitSync")
    private var cancellables = Set<AnyCancellable>()
    private let maxEvents = 50

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
        checkCloudKitStatus()
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        #if DEBUG
        // Remote change notifications (main CloudKit sync indicator)
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRemoteChange(notification)
            }
            .store(in: &cancellables)

        // iCloud account status changes
        NotificationCenter.default.publisher(for: .NSUbiquityIdentityDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkCloudKitStatus()
            }
            .store(in: &cancellables)

        // Application lifecycle - sync often happens on these events
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)

        logger.info("[CloudKitSync] Monitoring started")
        logEvent(SyncEvent(type: .monitoringStarted))
        #endif
    }

    // MARK: - CloudKit Status

    private func checkCloudKitStatus() {
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                switch status {
                case .available:
                    if syncStatus == .notAvailable || syncStatus == .disabled {
                        syncStatus = .idle
                    }
                    logger.debug("[CloudKitSync] iCloud available")
                case .noAccount:
                    syncStatus = .notAvailable
                    logger.warning("[CloudKitSync] No iCloud account")
                    logEvent(SyncEvent(type: .iCloudNotAvailable(reason: "No account")))
                case .restricted:
                    syncStatus = .disabled
                    logger.warning("[CloudKitSync] iCloud restricted")
                    logEvent(SyncEvent(type: .iCloudNotAvailable(reason: "Restricted")))
                case .couldNotDetermine:
                    syncStatus = .notAvailable
                    logger.warning("[CloudKitSync] Could not determine iCloud status")
                    logEvent(SyncEvent(type: .iCloudNotAvailable(reason: "Could not determine")))
                case .temporarilyUnavailable:
                    syncStatus = .notAvailable
                    logger.warning("[CloudKitSync] iCloud temporarily unavailable")
                    logEvent(SyncEvent(type: .iCloudNotAvailable(reason: "Temporarily unavailable")))
                @unknown default:
                    syncStatus = .notAvailable
                    logger.warning("[CloudKitSync] Unknown iCloud status")
                }
            } catch {
                logger.error("[CloudKitSync] Failed to check account status: \(error.localizedDescription)")
                logEvent(SyncEvent(type: .error(message: error.localizedDescription)))
            }
        }
    }

    // MARK: - Notification Handlers

    private func handleRemoteChange(_ notification: Notification) {
        #if DEBUG
        // Extract transaction info if available
        let userInfo = notification.userInfo
        let storeUUID = userInfo?["NSStoreUUIDKey"] as? String

        logger.info("[CloudKitSync] Remote change detected. Store: \(storeUUID ?? "unknown")")

        // Mark as syncing briefly
        syncStatus = .syncing
        logEvent(SyncEvent(type: .remoteChangeReceived(storeUUID: storeUUID)))

        // Update sync date after processing
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            self.syncStatus = .idle
            self.lastSyncDate = Date()
            self.logEvent(SyncEvent(type: .syncCompleted))
        }
        #endif
    }

    private func handleAppWillEnterForeground() {
        #if DEBUG
        logger.debug("[CloudKitSync] App entering foreground - sync may occur")
        syncStatus = .syncing
        logEvent(SyncEvent(type: .syncStarted))
        #endif
    }

    private func handleAppDidEnterBackground() {
        #if DEBUG
        logger.debug("[CloudKitSync] App entering background - final sync")
        // CloudKit often syncs when app backgrounds
        if syncStatus == .syncing {
            syncStatus = .idle
            lastSyncDate = Date()
            logEvent(SyncEvent(type: .syncCompleted))
        }
        #endif
    }

    // MARK: - Event Logging

    private func logEvent(_ event: SyncEvent) {
        recentEvents.insert(event, at: 0)
        if recentEvents.count > maxEvents {
            recentEvents.removeLast()
        }

        #if DEBUG
        logger.debug("[CloudKitSync] Event: \(event.description)")
        #endif
    }

    /// Manually log a sync error
    func logSyncError(_ error: Error) {
        logger.error("[CloudKitSync] Error: \(error.localizedDescription)")
        syncStatus = .error(error.localizedDescription)
        logEvent(SyncEvent(type: .error(message: error.localizedDescription)))
    }

    /// Manually log a conflict
    func logConflict(entityType: String, id: String, resolution: String) {
        logger.warning("[CloudKitSync] Conflict - Entity: \(entityType), ID: \(id), Resolution: \(resolution)")
        logEvent(SyncEvent(type: .conflict(entityType: entityType, id: id, resolution: resolution)))
    }

    /// Clear all logged events
    func clearEvents() {
        recentEvents.removeAll()
    }

    /// Export events as JSON for debugging
    func exportEventsAsJSON() -> String {
        let exportData = recentEvents.map { event -> [String: Any] in
            [
                "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
                "type": event.typeDescription,
                "description": event.description
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }

        return jsonString
    }
}

// MARK: - Supporting Types

enum SyncStatus: Equatable {
    case idle
    case syncing
    case error(String)
    case disabled
    case notAvailable
}

struct SyncEvent: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let type: EventType

    enum EventType {
        case monitoringStarted
        case syncStarted
        case syncCompleted
        case remoteChangeReceived(storeUUID: String?)
        case iCloudNotAvailable(reason: String)
        case error(message: String)
        case conflict(entityType: String, id: String, resolution: String)
    }

    var typeDescription: String {
        switch type {
        case .monitoringStarted: return "monitoring_started"
        case .syncStarted: return "sync_started"
        case .syncCompleted: return "sync_completed"
        case .remoteChangeReceived: return "remote_change"
        case .iCloudNotAvailable: return "icloud_unavailable"
        case .error: return "error"
        case .conflict: return "conflict"
        }
    }

    var description: String {
        switch type {
        case .monitoringStarted:
            return "Sync monitoring started"
        case .syncStarted:
            return "Sync started"
        case .syncCompleted:
            return "Sync completed"
        case .remoteChangeReceived(let storeUUID):
            return "Remote change received\(storeUUID.map { " (store: \($0))" } ?? "")"
        case .iCloudNotAvailable(let reason):
            return "iCloud not available: \(reason)"
        case .error(let message):
            return "Error: \(message)"
        case .conflict(let entityType, let id, let resolution):
            return "Conflict - \(entityType) [\(id)]: \(resolution)"
        }
    }
}

// MARK: - Convenience Initializers

extension SyncEvent {
    static func monitoringStarted() -> SyncEvent {
        SyncEvent(type: .monitoringStarted)
    }

    static func syncStarted() -> SyncEvent {
        SyncEvent(type: .syncStarted)
    }

    static func syncCompleted() -> SyncEvent {
        SyncEvent(type: .syncCompleted)
    }

    static func remoteChangeReceived(storeUUID: String?) -> SyncEvent {
        SyncEvent(type: .remoteChangeReceived(storeUUID: storeUUID))
    }

    static func iCloudNotAvailable(reason: String) -> SyncEvent {
        SyncEvent(type: .iCloudNotAvailable(reason: reason))
    }

    static func error(message: String) -> SyncEvent {
        SyncEvent(type: .error(message: message))
    }

    static func conflict(entityType: String, id: String, resolution: String) -> SyncEvent {
        SyncEvent(type: .conflict(entityType: entityType, id: id, resolution: resolution))
    }
}

// MARK: - Required Import for CKContainer
import CloudKit

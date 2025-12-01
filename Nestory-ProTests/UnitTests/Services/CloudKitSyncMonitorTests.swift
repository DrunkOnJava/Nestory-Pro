//
//  CloudKitSyncMonitorTests.swift
//  Nestory-ProTests
//
//  F7-06: Unit tests for CloudKitSyncMonitor service
//

// ============================================================================
// F7-06: CloudKitSyncMonitor Unit Tests
// ============================================================================
// Tests for CloudKit sync monitoring service
// - SyncStatus enum values and properties
// - SyncEvent logging
// - Status text generation
//
// SEE: TODO.md F7-06 | CloudKitSyncMonitor.swift
// ============================================================================

import XCTest
@testable import Nestory_Pro

@MainActor
final class CloudKitSyncMonitorTests: XCTestCase {

    // MARK: - Properties

    var sut: CloudKitSyncMonitor!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = CloudKitSyncMonitor.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testShared_ReturnsSameInstance() {
        // Act
        let instance1 = CloudKitSyncMonitor.shared
        let instance2 = CloudKitSyncMonitor.shared

        // Assert
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - SyncStatus Tests

    func testSyncStatus_InitialState() {
        // Note: Actual initial state depends on iCloud availability
        // This test verifies the property is accessible
        let status = sut.syncStatus
        XCTAssertNotNil(status)
    }

    func testIsSyncing_WhenIdle_ReturnsFalse() {
        // Arrange
        sut.syncStatus = .idle

        // Act & Assert
        XCTAssertFalse(sut.isSyncing)
    }

    func testIsSyncing_WhenSyncing_ReturnsTrue() {
        // Arrange
        sut.syncStatus = .syncing

        // Act & Assert
        XCTAssertTrue(sut.isSyncing)
    }

    // MARK: - StatusText Tests

    func testStatusText_WhenIdle_WithNoLastSync_ReturnsReadyToSync() {
        // Arrange
        sut.syncStatus = .idle
        sut.lastSyncDate = nil

        // Act & Assert
        XCTAssertEqual(sut.statusText, "Ready to sync")
    }

    func testStatusText_WhenSyncing_ReturnsSyncing() {
        // Arrange
        sut.syncStatus = .syncing

        // Act & Assert
        XCTAssertEqual(sut.statusText, "Syncing...")
    }

    func testStatusText_WhenError_ReturnsErrorMessage() {
        // Arrange
        sut.syncStatus = .error("Test error")

        // Act & Assert
        XCTAssertEqual(sut.statusText, "Sync error: Test error")
    }

    func testStatusText_WhenDisabled_ReturnsDisabledMessage() {
        // Arrange
        sut.syncStatus = .disabled

        // Act & Assert
        XCTAssertEqual(sut.statusText, "iCloud sync disabled")
    }

    func testStatusText_WhenNotAvailable_ReturnsNotAvailableMessage() {
        // Arrange
        sut.syncStatus = .notAvailable

        // Act & Assert
        XCTAssertEqual(sut.statusText, "iCloud not available")
    }

    // MARK: - SyncStatus Equatable Tests

    func testSyncStatus_Equality_Idle() {
        XCTAssertEqual(SyncStatus.idle, SyncStatus.idle)
    }

    func testSyncStatus_Equality_Syncing() {
        XCTAssertEqual(SyncStatus.syncing, SyncStatus.syncing)
    }

    func testSyncStatus_Equality_Error_SameMessage() {
        XCTAssertEqual(SyncStatus.error("Test"), SyncStatus.error("Test"))
    }

    func testSyncStatus_Inequality_Error_DifferentMessage() {
        XCTAssertNotEqual(SyncStatus.error("Test1"), SyncStatus.error("Test2"))
    }

    func testSyncStatus_Inequality_DifferentStates() {
        XCTAssertNotEqual(SyncStatus.idle, SyncStatus.syncing)
        XCTAssertNotEqual(SyncStatus.syncing, SyncStatus.disabled)
        XCTAssertNotEqual(SyncStatus.disabled, SyncStatus.notAvailable)
    }

    // MARK: - SyncEvent Tests

    func testSyncEvent_MonitoringStarted_TypeDescription() {
        let event = SyncEvent(type: .monitoringStarted)
        XCTAssertEqual(event.typeDescription, "monitoring_started")
    }

    func testSyncEvent_SyncStarted_Description() {
        let event = SyncEvent(type: .syncStarted)
        XCTAssertEqual(event.description, "Sync started")
    }

    func testSyncEvent_SyncCompleted_Description() {
        let event = SyncEvent(type: .syncCompleted)
        XCTAssertEqual(event.description, "Sync completed")
    }

    func testSyncEvent_RemoteChangeReceived_Description() {
        let event = SyncEvent(type: .remoteChangeReceived(storeUUID: "test-uuid"))
        XCTAssertEqual(event.description, "Remote change received (store: test-uuid)")
    }

    func testSyncEvent_RemoteChangeReceived_NoUUID_Description() {
        let event = SyncEvent(type: .remoteChangeReceived(storeUUID: nil))
        XCTAssertEqual(event.description, "Remote change received")
    }

    func testSyncEvent_ICloudNotAvailable_Description() {
        let event = SyncEvent(type: .iCloudNotAvailable(reason: "No account"))
        XCTAssertEqual(event.description, "iCloud not available: No account")
    }

    func testSyncEvent_Error_Description() {
        let event = SyncEvent(type: .error(message: "Connection failed"))
        XCTAssertEqual(event.description, "Error: Connection failed")
    }

    func testSyncEvent_Conflict_Description() {
        let event = SyncEvent(type: .conflict(entityType: "Item", id: "123", resolution: "Server wins"))
        XCTAssertEqual(event.description, "Conflict - Item [123]: Server wins")
    }

    // MARK: - SyncEvent Convenience Initializers

    func testSyncEvent_ConvenienceInitializer_MonitoringStarted() {
        let event = SyncEvent.monitoringStarted()
        XCTAssertEqual(event.typeDescription, "monitoring_started")
    }

    func testSyncEvent_ConvenienceInitializer_SyncStarted() {
        let event = SyncEvent.syncStarted()
        XCTAssertEqual(event.typeDescription, "sync_started")
    }

    func testSyncEvent_ConvenienceInitializer_SyncCompleted() {
        let event = SyncEvent.syncCompleted()
        XCTAssertEqual(event.typeDescription, "sync_completed")
    }

    func testSyncEvent_ConvenienceInitializer_RemoteChangeReceived() {
        let event = SyncEvent.remoteChangeReceived(storeUUID: "abc-123")
        XCTAssertEqual(event.typeDescription, "remote_change")
    }

    func testSyncEvent_ConvenienceInitializer_Error() {
        let event = SyncEvent.error(message: "Test error")
        XCTAssertEqual(event.typeDescription, "error")
    }

    func testSyncEvent_ConvenienceInitializer_Conflict() {
        let event = SyncEvent.conflict(entityType: "Category", id: "456", resolution: "Local wins")
        XCTAssertEqual(event.typeDescription, "conflict")
    }

    // MARK: - Event Logging Tests

    func testLogSyncError_SetsErrorStatus() {
        // Arrange
        let testError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // Act
        sut.logSyncError(testError)

        // Assert
        if case .error(let message) = sut.syncStatus {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected error status")
        }
    }

    func testClearEvents_RemovesAllEvents() {
        // Arrange - Ensure there are some events
        sut.logSyncError(NSError(domain: "test", code: -1))

        // Act
        sut.clearEvents()

        // Assert
        XCTAssertTrue(sut.recentEvents.isEmpty)
    }

    func testExportEventsAsJSON_ReturnsValidJSON() {
        // Act
        let json = sut.exportEventsAsJSON()

        // Assert - Should return a valid JSON array (even if empty)
        XCTAssertTrue(json.hasPrefix("["))
        XCTAssertTrue(json.hasSuffix("]"))
    }

    // MARK: - LastSyncDate Tests

    func testLastSyncDate_CanBeSet() {
        // Arrange
        let testDate = Date()

        // Act
        sut.lastSyncDate = testDate

        // Assert
        XCTAssertEqual(sut.lastSyncDate, testDate)
    }

    func testLastSyncDate_WhenSet_StatusTextIncludesRelativeTime() {
        // Arrange
        let recentDate = Date().addingTimeInterval(-60) // 1 minute ago
        sut.syncStatus = .idle
        sut.lastSyncDate = recentDate

        // Act
        let statusText = sut.statusText

        // Assert - Should contain "Synced" and some relative time indicator
        XCTAssertTrue(statusText.hasPrefix("Synced"))
    }
}

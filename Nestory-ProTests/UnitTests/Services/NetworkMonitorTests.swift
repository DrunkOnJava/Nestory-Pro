//
//  NetworkMonitorTests.swift
//  Nestory-ProTests
//
//  F7-06: Unit tests for NetworkMonitor service
//

// ============================================================================
// F7-06: NetworkMonitor Unit Tests
// ============================================================================
// Tests for network connectivity monitoring service
// - Connection status properties
// - Connection type enum values
// - Mock implementation for testing
//
// SEE: TODO.md F7-06 | NetworkMonitor.swift
// ============================================================================

import XCTest
@testable import Nestory_Pro

@MainActor
final class NetworkMonitorTests: XCTestCase {

    // MARK: - Properties

    var sut: NetworkMonitor!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = NetworkMonitor.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Connection Status Tests

    func testIsConnected_ReturnsBoolean() {
        // Act
        let isConnected = sut.isConnected

        // Assert - Verify property returns a valid boolean
        XCTAssertNotNil(isConnected as Bool?)
    }

    func testConnectionType_ReturnsValidType() {
        // Act
        let connectionType = sut.connectionType

        // Assert - Verify we get a valid enum case
        let validTypes: [NetworkMonitor.ConnectionType] = [.wifi, .cellular, .wired, .none, .unknown]
        XCTAssertTrue(validTypes.contains(connectionType))
    }

    func testIsExpensive_ReturnsBoolean() {
        // Act & Assert
        XCTAssertNotNil(sut.isExpensive as Bool?)
    }

    func testIsConstrained_ReturnsBoolean() {
        // Act & Assert
        XCTAssertNotNil(sut.isConstrained as Bool?)
    }

    // MARK: - ConnectionType Enum Tests

    func testConnectionType_RawValue_WiFi() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wifi.rawValue, "WiFi")
    }

    func testConnectionType_RawValue_Cellular() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.cellular.rawValue, "Cellular")
    }

    func testConnectionType_RawValue_Wired() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wired.rawValue, "Wired")
    }

    func testConnectionType_RawValue_None() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.none.rawValue, "Offline")
    }

    func testConnectionType_RawValue_Unknown() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.unknown.rawValue, "Unknown")
    }

    // MARK: - SystemImage Tests

    func testConnectionType_SystemImage_WiFi() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wifi.systemImage, "wifi")
    }

    func testConnectionType_SystemImage_Cellular() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.cellular.systemImage, "antenna.radiowaves.left.and.right")
    }

    func testConnectionType_SystemImage_Wired() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wired.systemImage, "cable.connector")
    }

    func testConnectionType_SystemImage_None() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.none.systemImage, "wifi.slash")
    }

    func testConnectionType_SystemImage_Unknown() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.unknown.systemImage, "questionmark.circle")
    }

    // MARK: - StatusDescription Tests

    func testStatusDescription_ReturnsNonEmptyString() {
        // Note: We can't easily control network state in unit tests,
        // but we can test the property exists and returns a string
        let status = sut.statusDescription
        XCTAssertFalse(status.isEmpty)
    }

    // MARK: - Singleton Tests

    func testShared_ReturnsSameInstance() {
        // Act
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared

        // Assert
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Mock NetworkMonitor Tests

    #if DEBUG
    func testMockNetworkMonitor_DefaultState() {
        // Arrange
        let mock = MockNetworkMonitor()

        // Assert
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.connectionType, .wifi)
        XCTAssertFalse(mock.isExpensive)
        XCTAssertFalse(mock.isConstrained)
    }

    func testMockNetworkMonitor_GoOffline() {
        // Arrange
        let mock = MockNetworkMonitor()

        // Act
        mock.goOffline()

        // Assert
        XCTAssertFalse(mock.isConnected)
        XCTAssertEqual(mock.connectionType, .none)
    }

    func testMockNetworkMonitor_GoOnline_WiFi() {
        // Arrange
        let mock = MockNetworkMonitor()
        mock.goOffline()

        // Act
        mock.goOnline(type: .wifi)

        // Assert
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.connectionType, .wifi)
        XCTAssertFalse(mock.isExpensive)
    }

    func testMockNetworkMonitor_GoOnline_Cellular() {
        // Arrange
        let mock = MockNetworkMonitor()
        mock.goOffline()

        // Act
        mock.goOnline(type: .cellular)

        // Assert
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.connectionType, .cellular)
        XCTAssertTrue(mock.isExpensive)
    }

    func testMockNetworkMonitor_CustomInitialization() {
        // Arrange & Act
        let mock = MockNetworkMonitor(
            isConnected: false,
            connectionType: .cellular,
            isExpensive: true,
            isConstrained: true
        )

        // Assert
        XCTAssertFalse(mock.isConnected)
        XCTAssertEqual(mock.connectionType, .cellular)
        XCTAssertTrue(mock.isExpensive)
        XCTAssertTrue(mock.isConstrained)
    }
    #endif
}

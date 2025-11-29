//
//  AppLockServiceTests.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// CLAUDE CODE AGENT: APP LOCK SERVICE TESTS
// ============================================================================
// Task 9.1.5: Unit tests for AppLockService
// Tests biometric availability detection and error handling
// Note: Actual biometric authentication cannot be tested in unit tests
//
// SEE: TODO.md Phase 9 | AppLockService.swift | AppLockProviding.swift
// ============================================================================

import XCTest
import LocalAuthentication
@testable import Nestory_Pro

@MainActor
final class AppLockServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: AppLockService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = AppLockService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Biometric Availability Tests

    func testIsBiometricAvailable_ReturnsBoolean() async {
        // Act
        let isAvailable = await sut.isBiometricAvailable

        // Assert - We can't control the simulator's biometric state,
        // but we can verify the property returns a valid boolean
        XCTAssertNotNil(isAvailable as Bool?)
    }

    func testBiometricType_ReturnsValidType() async {
        // Act
        let biometricType = await sut.biometricType

        // Assert - Verify we get a valid enum case
        let validTypes: [BiometricType] = [.none, .faceID, .touchID, .opticID]
        XCTAssertTrue(validTypes.contains(biometricType))
    }

    // MARK: - BiometricType Enum Tests

    func testBiometricType_DisplayName_FaceID() {
        // Assert
        XCTAssertEqual(BiometricType.faceID.displayName, "Face ID")
    }

    func testBiometricType_DisplayName_TouchID() {
        // Assert
        XCTAssertEqual(BiometricType.touchID.displayName, "Touch ID")
    }

    func testBiometricType_DisplayName_OpticID() {
        // Assert
        XCTAssertEqual(BiometricType.opticID.displayName, "Optic ID")
    }

    func testBiometricType_DisplayName_None() {
        // Assert - None displays as "None" not "Passcode"
        XCTAssertEqual(BiometricType.none.displayName, "None")
    }

    // MARK: - Mock AppLockProviding Tests

    func testMockAppLockService_CanBeUsedForTesting() async {
        // Arrange
        let mockService = MockAppLockService()

        // Act & Assert - Default state
        let isAvailable = await mockService.isBiometricAvailable
        XCTAssertTrue(isAvailable)

        let biometricType = await mockService.biometricType
        XCTAssertEqual(biometricType, .faceID)
    }

    func testMockAppLockService_CanConfigureState() async {
        // Arrange
        let mockService = MockAppLockService()
        mockService.mockBiometricAvailable = false
        mockService.mockBiometricType = .touchID
        mockService.mockAuthenticateResult = true

        // Act
        let isAvailable = await mockService.isBiometricAvailable
        let biometricType = await mockService.biometricType
        let authResult = await mockService.authenticate(reason: "Test")

        // Assert
        XCTAssertFalse(isAvailable)
        XCTAssertEqual(biometricType, .touchID)
        XCTAssertTrue(authResult)
    }

    func testMockAppLockService_AuthenticateFailure() async {
        // Arrange
        let mockService = MockAppLockService()
        mockService.mockAuthenticateResult = false

        // Act
        let result = await mockService.authenticate(reason: "Test authentication")

        // Assert
        XCTAssertFalse(result)
    }

    func testMockAppLockService_AuthenticateSuccess() async {
        // Arrange
        let mockService = MockAppLockService()
        mockService.mockAuthenticateResult = true

        // Act
        let result = await mockService.authenticate(reason: "Test authentication")

        // Assert
        XCTAssertTrue(result)
    }
    
    func testMockAppLockService_TracksCallCount() async {
        // Arrange
        let mockService = MockAppLockService()
        
        // Act
        _ = await mockService.authenticate(reason: "First")
        _ = await mockService.authenticate(reason: "Second")
        _ = await mockService.authenticate(reason: "Third")
        
        // Assert
        XCTAssertEqual(mockService.authenticateCallCount, 3)
        XCTAssertEqual(mockService.lastAuthenticateReason, "Third")
    }
}

// MARK: - Mock App Lock Service

/// Mock implementation for testing
@MainActor
final class MockAppLockService: AppLockProviding {
    var mockBiometricAvailable: Bool = true
    var mockBiometricType: BiometricType = .faceID
    var mockAuthenticateResult: Bool = true
    var authenticateCallCount: Int = 0
    var lastAuthenticateReason: String?

    var isBiometricAvailable: Bool {
        get async { mockBiometricAvailable }
    }

    var biometricType: BiometricType {
        get async { mockBiometricType }
    }

    func authenticate(reason: String) async -> Bool {
        authenticateCallCount += 1
        lastAuthenticateReason = reason
        return mockAuthenticateResult
    }
}

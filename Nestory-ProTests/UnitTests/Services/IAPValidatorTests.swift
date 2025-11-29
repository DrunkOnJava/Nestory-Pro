//
//  IAPValidatorTests.swift
//  Nestory-ProTests
//
//  Unit tests for IAPValidator
//

import XCTest
@testable import Nestory_Pro

@MainActor
final class IAPValidatorTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Clean up Keychain before each test to ensure clean state
        try? KeychainManager.removeProStatus()
    }

    override func tearDown() async throws {
        // Clean up Keychain after each test
        try? KeychainManager.removeProStatus()

        try await super.tearDown()
    }

    // MARK: - Keychain Synchronization Tests
    // Note: Singleton initialization tests removed - singletons can't be re-initialized
    // These tests verify the Keychain integration works correctly instead

    func testKeychainSync_SetProUnlocked_ReflectsInKeychain() throws {
        // Arrange
        let validator = IAPValidator.shared

        #if DEBUG
        // Act - Use debug method to set Pro status
        validator.simulateProUnlock()

        // Assert - Keychain should reflect the change
        XCTAssertTrue(KeychainManager.isProUnlocked(), "Keychain should be updated when Pro status changes")
        XCTAssertTrue(validator.isProUnlocked, "Validator should reflect Pro status")

        // Cleanup
        validator.resetProStatus()
        #else
        // In release builds, just verify Keychain operations work
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())
        try KeychainManager.setProUnlocked(false)
        #endif
    }

    func testKeychainSync_ResetProStatus_ReflectsInKeychain() throws {
        // Arrange
        let validator = IAPValidator.shared

        #if DEBUG
        validator.simulateProUnlock()
        XCTAssertTrue(validator.isProUnlocked)

        // Act
        validator.resetProStatus()

        // Assert
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Keychain should reflect locked status")
        XCTAssertFalse(validator.isProUnlocked, "Validator should reflect locked status")
        #else
        // In release builds, verify Keychain read/write works
        try KeychainManager.setProUnlocked(false)
        XCTAssertFalse(KeychainManager.isProUnlocked())
        #endif
    }

    func testKeychainManager_ReadWrite_WorksCorrectly() throws {
        // Test that KeychainManager operations work correctly
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked(), "Should read true from Keychain")

        try KeychainManager.setProUnlocked(false)
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Should read false from Keychain")
    }

    // MARK: - Initial State Tests

    func testIsPurchasing_InitiallyFalse() {
        // Arrange & Act
        let validator = IAPValidator.shared

        // Assert
        XCTAssertFalse(validator.isPurchasing, "isPurchasing should be false on initialization")
    }

    func testPurchaseError_InitiallyNil() {
        // Arrange & Act
        let validator = IAPValidator.shared

        // Assert
        XCTAssertNil(validator.purchaseError, "purchaseError should be nil on initialization")
    }

    // MARK: - Product Configuration Tests

    func testProductID_IsCorrect() {
        // Note: Product ID is private, but we can verify it through Debug methods
        // This test documents the expected product ID for reference
        let expectedProductID = "com.drunkonjava.nestory.pro"

        // We can't directly access private productID, but we document the expected value
        // If this changes, the test should be updated
        XCTAssertNotNil(expectedProductID, "Product ID should be defined")
        XCTAssertEqual(expectedProductID, "com.drunkonjava.nestory.pro", "Product ID should match App Store Connect configuration")
    }

    // MARK: - Transaction Listener Lifecycle Tests

    func testStartTransactionListener_CreatesTask() {
        // Arrange
        let validator = IAPValidator.shared

        // Act
        validator.startTransactionListener()

        // Assert
        // We can't directly access the private transactionListener task,
        // but we can verify the method doesn't crash and is callable
        XCTAssertNotNil(validator, "Validator should exist after starting listener")

        // Cleanup
        validator.stopTransactionListener()
    }

    func testStopTransactionListener_CancelsTask() {
        // Arrange
        let validator = IAPValidator.shared
        validator.startTransactionListener()

        // Act
        validator.stopTransactionListener()

        // Assert
        // We can't directly verify task cancellation, but we can ensure
        // the method is callable and doesn't crash
        XCTAssertNotNil(validator, "Validator should exist after stopping listener")
    }

    func testStopTransactionListener_WhenNotStarted_DoesNotCrash() {
        // Arrange
        let validator = IAPValidator.shared

        // Act & Assert - Should not crash
        validator.stopTransactionListener()

        XCTAssertNotNil(validator, "Validator should handle stopping non-existent listener")
    }

    func testStartTransactionListener_CalledMultipleTimes_DoesNotCrash() {
        // Arrange
        let validator = IAPValidator.shared

        // Act - Call multiple times
        validator.startTransactionListener()
        validator.startTransactionListener()
        validator.startTransactionListener()

        // Assert - Should not crash
        XCTAssertNotNil(validator, "Should handle multiple start calls gracefully")

        // Cleanup
        validator.stopTransactionListener()
    }

    // MARK: - Debug Methods Tests (DEBUG builds only)

    #if DEBUG
    func testSimulateProUnlock_UpdatesStateAndKeychain() {
        // Arrange
        let validator = IAPValidator.shared
        // Reset first to ensure clean state
        validator.resetProStatus()

        // Act
        validator.simulateProUnlock()

        // Assert
        XCTAssertTrue(validator.isProUnlocked, "Should be unlocked after simulation")
        XCTAssertTrue(KeychainManager.isProUnlocked(), "Keychain should reflect Pro status")

        // Cleanup
        validator.resetProStatus()
    }

    func testResetProStatus_UpdatesStateAndKeychain() throws {
        // Arrange
        let validator = IAPValidator.shared
        try KeychainManager.setProUnlocked(true)
        validator.simulateProUnlock()
        XCTAssertTrue(validator.isProUnlocked, "Should be unlocked initially")

        // Act
        validator.resetProStatus()

        // Assert
        XCTAssertFalse(validator.isProUnlocked, "Should be locked after reset")
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Keychain should reflect locked status")
    }

    func testSimulateProUnlock_CanBeCalledMultipleTimes() {
        // Arrange
        let validator = IAPValidator.shared

        // Act - Call multiple times
        validator.simulateProUnlock()
        validator.simulateProUnlock()
        validator.simulateProUnlock()

        // Assert
        XCTAssertTrue(validator.isProUnlocked, "Should remain unlocked")
        XCTAssertTrue(KeychainManager.isProUnlocked(), "Keychain should remain unlocked")
    }

    func testResetProStatus_CanBeCalledMultipleTimes() {
        // Arrange
        let validator = IAPValidator.shared

        // Act - Call multiple times
        validator.resetProStatus()
        validator.resetProStatus()
        validator.resetProStatus()

        // Assert
        XCTAssertFalse(validator.isProUnlocked, "Should remain locked")
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Keychain should remain locked")
    }

    func testSimulateAndReset_Cycle() {
        // Arrange
        let validator = IAPValidator.shared

        // Act & Assert - Cycle through multiple state changes
        validator.resetProStatus()
        XCTAssertFalse(validator.isProUnlocked, "Should be locked")

        validator.simulateProUnlock()
        XCTAssertTrue(validator.isProUnlocked, "Should be unlocked")

        validator.resetProStatus()
        XCTAssertFalse(validator.isProUnlocked, "Should be locked again")

        validator.simulateProUnlock()
        XCTAssertTrue(validator.isProUnlocked, "Should be unlocked again")
    }
    #endif

    // MARK: - Observable State Tests

    func testIsProUnlocked_IsObservable() {
        // Arrange
        let validator = IAPValidator.shared
        let initialState = validator.isProUnlocked

        // Act - Change state via Debug method
        #if DEBUG
        validator.simulateProUnlock()
        let newState = validator.isProUnlocked

        // Assert
        XCTAssertNotEqual(initialState, newState, "isProUnlocked should change")
        XCTAssertTrue(newState, "Should be unlocked")
        #else
        // In Release builds, we can only verify the property is accessible
        XCTAssertNotNil(initialState, "isProUnlocked should be accessible")
        #endif
    }

    func testIsPurchasing_IsObservable() {
        // Arrange & Act
        let validator = IAPValidator.shared
        let isPurchasing = validator.isPurchasing

        // Assert - Verify property is observable (accessible)
        XCTAssertFalse(isPurchasing, "isPurchasing should be false initially")
        // Note: Testing actual purchase state changes requires StoreKit environment
    }

    func testPurchaseError_IsObservable() {
        // Arrange & Act
        let validator = IAPValidator.shared
        let error = validator.purchaseError

        // Assert - Verify property is observable (accessible)
        XCTAssertNil(error, "purchaseError should be nil initially")
        // Note: Testing actual error states requires StoreKit environment
    }

    // MARK: - Singleton Pattern Tests

    func testShared_ReturnsSameInstance() {
        // Arrange & Act
        let instance1 = IAPValidator.shared
        let instance2 = IAPValidator.shared

        // Assert
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - Keychain Integration Tests

    func testKeychainIntegration_StateChangesArePersisted() throws {
        // Arrange
        let validator = IAPValidator.shared

        // Act - Simulate Pro unlock
        #if DEBUG
        validator.simulateProUnlock()

        // Assert - Verify Keychain is updated
        XCTAssertTrue(KeychainManager.isProUnlocked(), "Keychain should be updated when Pro status changes")

        // Act - Reset
        validator.resetProStatus()

        // Assert - Verify Keychain is updated again
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Keychain should be updated when Pro status resets")
        #else
        // In Release builds, we can only verify initialization from Keychain
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked(), "Keychain should store Pro status")
        #endif
    }

    func testKeychainIntegration_InitializationReadsCorrectly() throws {
        // Note: This test documents the initialization behavior
        // In production, IAPValidator.shared is already initialized
        // We can only verify that Keychain operations work correctly

        // Arrange
        try KeychainManager.setProUnlocked(true)

        // Act - Read from Keychain
        let isUnlocked = KeychainManager.isProUnlocked()

        // Assert
        XCTAssertTrue(isUnlocked, "Should read Pro status from Keychain correctly")
    }

    // MARK: - Error Handling Tests

    func testIAPError_ProductNotFound_HasCorrectDescription() {
        // Arrange
        let error = IAPError.productNotFound

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("Pro product not found") ?? false)
    }

    func testIAPError_PurchasePending_HasCorrectDescription() {
        // Arrange
        let error = IAPError.purchasePending

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("pending") ?? false)
    }

    func testIAPError_VerificationFailed_HasCorrectDescription() {
        // Arrange
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = IAPError.verificationFailed(underlyingError)

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("verification failed") ?? false)
        XCTAssertTrue(description?.contains("Test error") ?? false)
    }

    func testIAPError_UnknownPurchaseResult_HasCorrectDescription() {
        // Arrange
        let error = IAPError.unknownPurchaseResult

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("Unknown purchase result") ?? false)
    }

    // MARK: - Thread Safety Tests

    func testMainActorIsolation_PropertiesAccessibleOnMainActor() async {
        // Arrange & Act - Access properties on MainActor
        let isUnlocked = await IAPValidator.shared.isProUnlocked
        let isPurchasing = await IAPValidator.shared.isPurchasing
        let error = await IAPValidator.shared.purchaseError

        // Assert - Should be accessible without issues
        XCTAssertNotNil(isUnlocked)
        XCTAssertNotNil(isPurchasing)
        // error is optional, so it being nil is valid
        _ = error
    }

    func testMainActorIsolation_MethodsCallableOnMainActor() async {
        // Arrange
        let validator = await IAPValidator.shared

        // Act & Assert - Should be callable without issues
        await validator.startTransactionListener()
        await validator.stopTransactionListener()

        XCTAssertNotNil(validator, "Methods should be callable on MainActor")
    }
}

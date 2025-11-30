//
//  KeychainManagerTests.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/28/25.
//

import XCTest
@testable import Nestory_Pro

final class KeychainManagerTests: XCTestCase {

    // MARK: - Test Keys

    private let testStringKey = "testKey"
    private let migrationTestKey = "keychainMigrationComplete"

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Clean Keychain before each test to ensure isolated state
        try? KeychainManager.removeProStatus()
        try? KeychainManager.removeValue(forKey: testStringKey)

        // Clean UserDefaults for migration tests
        UserDefaults.standard.removeObject(forKey: "isProUnlocked")
        UserDefaults.standard.removeObject(forKey: migrationTestKey)
    }

    override func tearDown() {
        // Clean up Keychain after each test to avoid pollution
        try? KeychainManager.removeProStatus()
        try? KeychainManager.removeValue(forKey: testStringKey)

        // Clean UserDefaults
        UserDefaults.standard.removeObject(forKey: "isProUnlocked")
        UserDefaults.standard.removeObject(forKey: migrationTestKey)

        super.tearDown()
    }

    // MARK: - Pro Status Tests

    func testSetProUnlocked_True_StoresInKeychain() async throws {
        // When: Setting Pro unlocked to true
        try KeychainManager.setProUnlocked(true)

        // Then: The value should be stored and retrievable
        let result = KeychainManager.isProUnlocked()
        XCTAssertTrue(result, "Pro status should be true after setting to true")
    }

    func testSetProUnlocked_False_StoresInKeychain() async throws {
        // Given: Pro status is initially true
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())

        // When: Setting Pro unlocked to false
        try KeychainManager.setProUnlocked(false)

        // Then: The value should be updated to false
        let result = KeychainManager.isProUnlocked()
        XCTAssertFalse(result, "Pro status should be false after setting to false")
    }

    func testIsProUnlocked_WhenNotSet_ReturnsFalse() async {
        // When: No Pro status has been set
        let result = KeychainManager.isProUnlocked()

        // Then: Should return false by default
        XCTAssertFalse(result, "Pro status should default to false when not set")
    }

    func testIsProUnlocked_AfterSettingTrue_ReturnsTrue() async throws {
        // Given: Pro status is set to true
        try KeychainManager.setProUnlocked(true)

        // When: Checking Pro status
        let result = KeychainManager.isProUnlocked()

        // Then: Should return true
        XCTAssertTrue(result, "Pro status should persist as true")
    }

    func testRemoveProStatus_RemovesValue() async throws {
        // Given: Pro status is set to true
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())

        // When: Removing Pro status
        try KeychainManager.removeProStatus()

        // Then: Should return to default false state
        let result = KeychainManager.isProUnlocked()
        XCTAssertFalse(result, "Pro status should be false after removal")
    }

    func testRemoveProStatus_WhenNotSet_DoesNotThrow() async {
        // When: Removing Pro status that was never set
        // Then: Should not throw an error
        XCTAssertNoThrow(try KeychainManager.removeProStatus(),
                        "Removing non-existent Pro status should not throw")
    }

    func testSetProUnlocked_MultipleUpdates_UpdatesCorrectly() async throws {
        // When: Setting Pro status multiple times
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())

        try KeychainManager.setProUnlocked(false)
        XCTAssertFalse(KeychainManager.isProUnlocked())

        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())

        // Then: Each update should be persisted correctly
        let finalResult = KeychainManager.isProUnlocked()
        XCTAssertTrue(finalResult, "Final Pro status should be true after multiple updates")
    }

    // MARK: - Generic String Storage Tests

    func testSetString_StoresValue() async throws {
        // Given: A test string
        let testValue = "testValue123"

        // When: Storing the string
        try KeychainManager.setString(testValue, forKey: testStringKey)

        // Then: The value should be retrievable
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, testValue, "Retrieved value should match stored value")
    }

    func testGetString_RetrievesStoredValue() async throws {
        // Given: A stored string
        let testValue = "anotherTestValue"
        try KeychainManager.setString(testValue, forKey: testStringKey)

        // When: Retrieving the string
        let result = KeychainManager.getString(forKey: testStringKey)

        // Then: Should return the correct value
        XCTAssertEqual(result, testValue, "Should retrieve the exact stored value")
    }

    func testGetString_WhenNotSet_ReturnsNil() async {
        // When: Getting a string that was never set
        let result = KeychainManager.getString(forKey: "nonExistentKey")

        // Then: Should return nil
        XCTAssertNil(result, "Getting non-existent key should return nil")
    }

    func testRemoveValue_RemovesStoredString() async throws {
        // Given: A stored string
        let testValue = "valueToRemove"
        try KeychainManager.setString(testValue, forKey: testStringKey)
        XCTAssertNotNil(KeychainManager.getString(forKey: testStringKey))

        // When: Removing the value
        try KeychainManager.removeValue(forKey: testStringKey)

        // Then: The value should no longer be retrievable
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertNil(result, "Value should be nil after removal")
    }

    func testRemoveValue_WhenNotSet_DoesNotThrow() async {
        // When: Removing a value that was never set
        // Then: Should not throw an error
        XCTAssertNoThrow(try KeychainManager.removeValue(forKey: "nonExistentKey"),
                        "Removing non-existent value should not throw")
    }

    func testSetString_UpdatesExistingValue() async throws {
        // Given: An existing stored value
        try KeychainManager.setString("oldValue", forKey: testStringKey)
        XCTAssertEqual(KeychainManager.getString(forKey: testStringKey), "oldValue")

        // When: Updating with a new value
        let newValue = "newValue"
        try KeychainManager.setString(newValue, forKey: testStringKey)

        // Then: Should retrieve the updated value
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, newValue, "Should retrieve updated value, not old value")
    }

    func testSetString_HandlesSpecialCharacters() async throws {
        // Given: A string with special characters
        let testValue = "Test!@#$%^&*()_+-=[]{}|;':\",./<>?`~"

        // When: Storing and retrieving
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)

        // Then: Should handle special characters correctly
        XCTAssertEqual(result, testValue, "Should preserve special characters")
    }

    func testSetString_HandlesUnicode() async throws {
        // Given: A string with Unicode characters
        let testValue = "Hello 世界 🌍 مرحبا"

        // When: Storing and retrieving
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)

        // Then: Should handle Unicode correctly
        XCTAssertEqual(result, testValue, "Should preserve Unicode characters")
    }

    func testSetString_HandlesEmptyString() async throws {
        // Given: An empty string
        let testValue = ""

        // When: Storing and retrieving
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)

        // Then: Should store and retrieve empty string
        XCTAssertEqual(result, testValue, "Should handle empty string")
    }

    func testSetString_HandlesLongString() async throws {
        // Given: A very long string
        let testValue = String(repeating: "A", count: 10_000)

        // When: Storing and retrieving
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)

        // Then: Should handle long strings
        XCTAssertEqual(result, testValue, "Should handle long strings")
    }

    // MARK: - Migration Tests

    func testMigration_WhenUserDefaultsHasValue_MigratesToKeychain() async {
        // Given: Pro status stored in UserDefaults
        UserDefaults.standard.set(true, forKey: "isProUnlocked")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isProUnlocked"))

        // When: Running migration
        KeychainManager.migrateProStatusFromUserDefaults()

        // Then: Value should be in Keychain
        XCTAssertTrue(KeychainManager.isProUnlocked(),
                     "Pro status should be migrated to Keychain")

        // And: UserDefaults should be cleaned up
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isProUnlocked"),
                      "UserDefaults value should be removed after migration")

        // And: Migration should be marked complete
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationTestKey),
                     "Migration should be marked complete")
    }

    func testMigration_WhenUserDefaultsIsFalse_DoesNotMigrate() async {
        // Given: Pro status is false in UserDefaults
        UserDefaults.standard.set(false, forKey: "isProUnlocked")

        // When: Running migration
        KeychainManager.migrateProStatusFromUserDefaults()

        // Then: Keychain should remain false (default)
        XCTAssertFalse(KeychainManager.isProUnlocked(),
                      "Should not migrate false value")

        // And: Migration should still be marked complete
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationTestKey),
                     "Migration should be marked complete even for false value")
    }

    func testMigration_WhenAlreadyMigrated_DoesNotMigrateAgain() async {
        // Given: Migration already completed
        UserDefaults.standard.set(true, forKey: migrationTestKey)
        UserDefaults.standard.set(true, forKey: "isProUnlocked")

        // When: Running migration again
        KeychainManager.migrateProStatusFromUserDefaults()

        // Then: Should not migrate (Keychain should remain false)
        XCTAssertFalse(KeychainManager.isProUnlocked(),
                      "Should not re-migrate when already complete")

        // And: UserDefaults value should remain (not cleaned up)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isProUnlocked"),
                     "Should not touch UserDefaults on subsequent migrations")
    }

    func testMigration_WhenUserDefaultsNotSet_CompletesWithoutError() async {
        // Given: No value in UserDefaults
        UserDefaults.standard.removeObject(forKey: "isProUnlocked")

        // When: Running migration
        KeychainManager.migrateProStatusFromUserDefaults()

        // Then: Should complete without error
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationTestKey),
                     "Migration should be marked complete")

        // And: Keychain should remain false
        XCTAssertFalse(KeychainManager.isProUnlocked(),
                      "Keychain should remain false when nothing to migrate")
    }

    // MARK: - Edge Cases & Error Handling

    func testKeyIsolation_DifferentKeys_DoNotInterfere() async throws {
        // Given: Multiple different keys with values
        try KeychainManager.setString("value1", forKey: "key1")
        try KeychainManager.setString("value2", forKey: "key2")
        try KeychainManager.setString("value3", forKey: "key3")

        // When: Retrieving each value
        let result1 = KeychainManager.getString(forKey: "key1")
        let result2 = KeychainManager.getString(forKey: "key2")
        let result3 = KeychainManager.getString(forKey: "key3")

        // Then: Each should return its own value
        XCTAssertEqual(result1, "value1")
        XCTAssertEqual(result2, "value2")
        XCTAssertEqual(result3, "value3")

        // Cleanup
        try KeychainManager.removeValue(forKey: "key1")
        try KeychainManager.removeValue(forKey: "key2")
        try KeychainManager.removeValue(forKey: "key3")
    }

    func testProStatus_IndependentFromGenericStrings() async throws {
        // Given: Generic string stored
        try KeychainManager.setString("testValue", forKey: testStringKey)

        // When: Setting Pro status
        try KeychainManager.setProUnlocked(true)

        // Then: Both should coexist independently
        XCTAssertTrue(KeychainManager.isProUnlocked())
        XCTAssertEqual(KeychainManager.getString(forKey: testStringKey), "testValue")

        // When: Removing Pro status
        try KeychainManager.removeProStatus()

        // Then: Generic string should remain
        XCTAssertFalse(KeychainManager.isProUnlocked())
        XCTAssertEqual(KeychainManager.getString(forKey: testStringKey), "testValue")
    }
}

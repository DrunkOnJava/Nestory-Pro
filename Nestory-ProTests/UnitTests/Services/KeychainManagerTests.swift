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

    override func setUp() async throws {
        try await super.setUp()
        let stringKey = testStringKey
        let migKey = migrationTestKey
        await MainActor.run {
            try? KeychainManager.removeProStatus()
            try? KeychainManager.removeValue(forKey: stringKey)
            UserDefaults.standard.removeObject(forKey: "isProUnlocked")
            UserDefaults.standard.removeObject(forKey: migKey)
        }
    }

    override func tearDown() async throws {
        let stringKey = testStringKey
        let migKey = migrationTestKey
        await MainActor.run {
            try? KeychainManager.removeProStatus()
            try? KeychainManager.removeValue(forKey: stringKey)
            UserDefaults.standard.removeObject(forKey: "isProUnlocked")
            UserDefaults.standard.removeObject(forKey: migKey)
        }
        try await super.tearDown()
    }

    // MARK: - Pro Status Tests

    @MainActor
    func testSetProUnlocked_True_StoresInKeychain() throws {
        try KeychainManager.setProUnlocked(true)
        let result = KeychainManager.isProUnlocked()
        XCTAssertTrue(result, "Pro status should be true after setting to true")
    }

    @MainActor
    func testSetProUnlocked_False_StoresInKeychain() throws {
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())
        try KeychainManager.setProUnlocked(false)
        let result = KeychainManager.isProUnlocked()
        XCTAssertFalse(result, "Pro status should be false after setting to false")
    }

    @MainActor
    func testIsProUnlocked_WhenNotSet_ReturnsFalse() {
        let result = KeychainManager.isProUnlocked()
        XCTAssertFalse(result, "Pro status should default to false when not set")
    }

    @MainActor
    func testRemoveProStatus_RemovesStoredValue() throws {
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())
        try KeychainManager.removeProStatus()
        let result = KeychainManager.isProUnlocked()
        XCTAssertFalse(result, "Pro status should be false after removal")
    }

    @MainActor
    func testRemoveProStatus_WhenNotSet_DoesNotThrow() {
        do {
            try KeychainManager.removeProStatus()
        } catch {
            XCTFail("Removing non-existent Pro status should not throw: \(error)")
        }
    }

    @MainActor
    func testSetProUnlocked_MultipleUpdates_UpdatesCorrectly() throws {
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())
        try KeychainManager.setProUnlocked(false)
        XCTAssertFalse(KeychainManager.isProUnlocked())
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())
    }

    // MARK: - Generic String Storage Tests

    @MainActor
    func testSetString_StoresValue() throws {
        let testValue = "TestValue123"
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, testValue, "Should retrieve the exact stored value")
    }

    @MainActor
    func testGetString_WhenNotSet_ReturnsNil() {
        let result = KeychainManager.getString(forKey: "nonExistentKey")
        XCTAssertNil(result, "Getting non-existent key should return nil")
    }

    @MainActor
    func testRemoveValue_RemovesStoredString() throws {
        let testValue = "valueToRemove"
        try KeychainManager.setString(testValue, forKey: testStringKey)
        XCTAssertNotNil(KeychainManager.getString(forKey: testStringKey))
        try KeychainManager.removeValue(forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertNil(result, "Value should be nil after removal")
    }

    @MainActor
    func testRemoveValue_WhenNotSet_DoesNotThrow() {
        do {
            try KeychainManager.removeValue(forKey: "nonExistentKey")
        } catch {
            XCTFail("Removing non-existent value should not throw: \(error)")
        }
    }

    @MainActor
    func testSetString_UpdatesExistingValue() throws {
        try KeychainManager.setString("oldValue", forKey: testStringKey)
        XCTAssertEqual(KeychainManager.getString(forKey: testStringKey), "oldValue")
        let newValue = "newValue"
        try KeychainManager.setString(newValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, newValue, "Should retrieve updated value")
    }

    @MainActor
    func testSetString_HandlesSpecialCharacters() throws {
        let testValue = "Test!@#$%^&*()_+-=[]{}|;':\",./<>?`~"
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, testValue, "Should preserve special characters")
    }

    @MainActor
    func testSetString_HandlesUnicode() throws {
        let testValue = "Hello 世界 🌍 مرحبا"
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, testValue, "Should preserve Unicode characters")
    }

    @MainActor
    func testSetString_HandlesEmptyString() throws {
        let testValue = ""
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, testValue, "Should handle empty string")
    }

    @MainActor
    func testSetString_HandlesLongString() throws {
        let testValue = String(repeating: "A", count: 10_000)
        try KeychainManager.setString(testValue, forKey: testStringKey)
        let result = KeychainManager.getString(forKey: testStringKey)
        XCTAssertEqual(result, testValue, "Should handle long strings")
    }

    // MARK: - Migration Tests

    @MainActor
    func testMigration_WhenUserDefaultsHasValue_MigratesToKeychain() {
        UserDefaults.standard.set(true, forKey: "isProUnlocked")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isProUnlocked"))
        KeychainManager.migrateProStatusFromUserDefaults()
        XCTAssertTrue(KeychainManager.isProUnlocked(), "Pro status should be migrated")
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isProUnlocked"), "UserDefaults should be cleaned")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationTestKey), "Migration should be marked complete")
    }

    @MainActor
    func testMigration_WhenUserDefaultsIsFalse_DoesNotMigrate() {
        UserDefaults.standard.set(false, forKey: "isProUnlocked")
        KeychainManager.migrateProStatusFromUserDefaults()
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Should not migrate false value")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationTestKey), "Migration should be marked complete")
    }

    @MainActor
    func testMigration_WhenAlreadyMigrated_DoesNotMigrateAgain() {
        UserDefaults.standard.set(true, forKey: migrationTestKey)
        UserDefaults.standard.set(true, forKey: "isProUnlocked")
        KeychainManager.migrateProStatusFromUserDefaults()
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Should not re-migrate")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isProUnlocked"), "Should not touch UserDefaults")
    }

    @MainActor
    func testMigration_WhenUserDefaultsNotSet_CompletesWithoutError() {
        UserDefaults.standard.removeObject(forKey: "isProUnlocked")
        KeychainManager.migrateProStatusFromUserDefaults()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationTestKey), "Migration should be marked complete")
        XCTAssertFalse(KeychainManager.isProUnlocked(), "Keychain should remain false")
    }

    // MARK: - Edge Cases

    @MainActor
    func testKeyIsolation_DifferentKeys_DoNotInterfere() throws {
        try KeychainManager.setString("value1", forKey: "key1")
        try KeychainManager.setString("value2", forKey: "key2")
        try KeychainManager.setString("value3", forKey: "key3")
        XCTAssertEqual(KeychainManager.getString(forKey: "key1"), "value1")
        XCTAssertEqual(KeychainManager.getString(forKey: "key2"), "value2")
        XCTAssertEqual(KeychainManager.getString(forKey: "key3"), "value3")
        try KeychainManager.removeValue(forKey: "key1")
        try KeychainManager.removeValue(forKey: "key2")
        try KeychainManager.removeValue(forKey: "key3")
    }

    @MainActor
    func testProStatus_IndependentFromGenericStrings() throws {
        try KeychainManager.setString("testValue", forKey: testStringKey)
        try KeychainManager.setProUnlocked(true)
        XCTAssertTrue(KeychainManager.isProUnlocked())
        XCTAssertEqual(KeychainManager.getString(forKey: testStringKey), "testValue")
        try KeychainManager.removeProStatus()
        XCTAssertFalse(KeychainManager.isProUnlocked())
        XCTAssertEqual(KeychainManager.getString(forKey: testStringKey), "testValue")
    }
}

//
//  KeychainManager.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import Security

/// Secure storage manager using iOS Keychain Services
// NOTE: Uses kSecAttrAccessibleAfterFirstUnlock for balance of security and usability
// TODO: Add unit tests for all Keychain operations
enum KeychainManager {
    private static let service = "com.drunkonjava.nestory"

    enum KeychainError: LocalizedError {
        case duplicateItem
        case itemNotFound
        case unexpectedData
        case unhandledError(status: OSStatus)

        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "Item already exists in Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .unexpectedData:
                return "Unexpected data format in Keychain"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            }
        }
    }

    // MARK: - Pro Status

    private static let proStatusKey = "proUnlockStatus"

    /// Securely stores the Pro unlock status in Keychain
    static func setProUnlocked(_ unlocked: Bool) throws {
        let data = Data([unlocked ? 1 : 0])

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: proStatusKey
        ]

        // First, try to delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add the new value
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Retrieves the Pro unlock status from Keychain
    static func isProUnlocked() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: proStatusKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let byte = data.first else {
            return false
        }

        return byte == 1
    }

    /// Removes the Pro status from Keychain (for testing/reset)
    static func removeProStatus() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: proStatusKey
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Migration from UserDefaults

    /// Migrates Pro status from UserDefaults to Keychain (call once on app launch)
    static func migrateProStatusFromUserDefaults() {
        let userDefaultsKey = "isProUnlocked"
        let defaults = UserDefaults.standard

        // Check if migration already happened
        let migrationKey = "keychainMigrationComplete"
        guard !defaults.bool(forKey: migrationKey) else { return }

        // Read from UserDefaults
        let wasProUnlocked = defaults.bool(forKey: userDefaultsKey)

        // Write to Keychain
        if wasProUnlocked {
            try? setProUnlocked(true)
        }

        // Clean up UserDefaults and mark migration complete
        defaults.removeObject(forKey: userDefaultsKey)
        defaults.set(true, forKey: migrationKey)
    }

    // MARK: - Generic Keychain Operations

    /// Stores a string value securely in Keychain
    static func setString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Retrieves a string value from Keychain
    static func getString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    /// Removes a value from Keychain
    static func removeValue(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

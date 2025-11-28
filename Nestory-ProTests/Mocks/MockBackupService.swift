//
//  MockBackupService.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/28/25.
//

import Foundation
@testable import Nestory_Pro

/// Mock implementation of BackupServiceProtocol for testing
@MainActor
final class MockBackupService: BackupServiceProtocol {
    // MARK: - Mock Configuration
    var shouldThrowError: Bool = false
    var errorToThrow: Error = BackupError.backupFailed
    var mockBackupURL: URL = URL(fileURLWithPath: "/tmp/mock-backup.json")
    var mockIsValid: Bool = true

    // MARK: - Call Tracking
    var createBackupCallCount = 0
    var restoreBackupCallCount = 0
    var exportDataCallCount = 0
    var validateBackupCallCount = 0
    var lastRestoredURL: URL?
    var lastExportFormat: ExportFormat?
    var lastValidatedURL: URL?

    // MARK: - BackupServiceProtocol
    func createBackup() async throws -> URL {
        createBackupCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return mockBackupURL
    }

    func restoreBackup(from url: URL) async throws {
        restoreBackupCallCount += 1
        lastRestoredURL = url

        if shouldThrowError {
            throw errorToThrow
        }
    }

    func exportData(format: ExportFormat) async throws -> URL {
        exportDataCallCount += 1
        lastExportFormat = format

        if shouldThrowError {
            throw errorToThrow
        }

        let fileName = "mock-export.\(format.fileExtension)"
        return URL(fileURLWithPath: "/tmp/\(fileName)")
    }

    func validateBackup(at url: URL) async throws -> Bool {
        validateBackupCallCount += 1
        lastValidatedURL = url

        if shouldThrowError {
            throw errorToThrow
        }

        return mockIsValid
    }

    // MARK: - Test Helpers
    func reset() {
        shouldThrowError = false
        errorToThrow = BackupError.backupFailed
        mockBackupURL = URL(fileURLWithPath: "/tmp/mock-backup.json")
        mockIsValid = true
        createBackupCallCount = 0
        restoreBackupCallCount = 0
        exportDataCallCount = 0
        validateBackupCallCount = 0
        lastRestoredURL = nil
        lastExportFormat = nil
        lastValidatedURL = nil
    }
}

// MARK: - Mock Errors
enum BackupError: Error, Sendable {
    case backupFailed
    case restoreFailed
    case exportFailed
    case invalidBackup
}

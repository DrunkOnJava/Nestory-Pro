//
//  BackupServiceProtocol.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation

/// Protocol for data backup and restore services
@MainActor
protocol BackupServiceProtocol {
    /// Creates a backup of all app data
    /// - Returns: URL to the backup file
    /// - Throws: Error if backup creation fails
    func createBackup() async throws -> URL

    /// Restores data from a backup file
    /// - Parameter url: URL of the backup file to restore
    /// - Throws: Error if restore fails
    func restoreBackup(from url: URL) async throws

    /// Exports data in a specific format
    /// - Parameter format: Export format (JSON, CSV)
    /// - Returns: URL to the exported file
    /// - Throws: Error if export fails
    func exportData(format: ExportFormat) async throws -> URL

    /// Validates a backup file
    /// - Parameter url: URL of the backup file to validate
    /// - Returns: True if backup is valid
    func validateBackup(at url: URL) async throws -> Bool
}

/// Supported export formats
enum ExportFormat: String, Sendable, CaseIterable {
    case json = "JSON"
    case csv = "CSV"

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }
}

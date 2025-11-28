//
//  PhotoStorageProtocol.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import UIKit

/// Protocol for photo storage management
protocol PhotoStorageProtocol: Sendable {
    /// Saves a photo to storage
    /// - Parameter image: UIImage to save
    /// - Returns: Unique identifier for the stored photo
    /// - Throws: Error if save fails
    func savePhoto(_ image: UIImage) async throws -> String

    /// Loads a photo from storage
    /// - Parameter identifier: Unique identifier of the photo
    /// - Returns: UIImage if found
    /// - Throws: Error if photo not found or load fails
    func loadPhoto(identifier: String) async throws -> UIImage

    /// Deletes a photo from storage
    /// - Parameter identifier: Unique identifier of the photo to delete
    /// - Throws: Error if deletion fails
    func deletePhoto(identifier: String) async throws

    /// Gets the file size of a stored photo
    /// - Parameter identifier: Unique identifier of the photo
    /// - Returns: Size in bytes
    /// - Throws: Error if photo not found
    func getPhotoSize(identifier: String) async throws -> Int64

    /// Gets total storage size used by all photos
    /// - Returns: Total size in bytes
    func getTotalStorageSize() async throws -> Int64

    /// Cleans up orphaned photo files (photos not referenced in database)
    /// - Returns: Number of files cleaned up
    func cleanupOrphanedPhotos() async throws -> Int
}

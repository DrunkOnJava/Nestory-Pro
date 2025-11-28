//
//  PhotoStorageService.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: PHOTO STORAGE SERVICE
// ============================================================================
// Task 2.1.1: Implements PhotoStorageProtocol for file-based photo storage
// - Saves to Documents/Photos/ directory
// - Resizes images to max 2048px (maintains aspect ratio)
// - JPEG compression at 0.8 quality
// - Thread-safe actor implementation
//
// SEE: TODO.md Phase 2 | PhotoStorageProtocol.swift | MockPhotoStorageService.swift
// ============================================================================

import Foundation
import UIKit
import OSLog

/// File-based photo storage service using the Documents directory
actor PhotoStorageService: PhotoStorageProtocol {
    static let shared = PhotoStorageService()

    // MARK: - Configuration

    /// Maximum dimension for resized images (maintains aspect ratio)
    private let maxImageDimension: CGFloat = 2048

    /// JPEG compression quality (0.0 = max compression, 1.0 = no compression)
    private let jpegQuality: CGFloat = 0.8

    /// Subdirectory name within Documents
    private let photoDirectoryName = "Photos"

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "PhotoStorage")
    private let fileManager = FileManager.default

    // MARK: - Initialization

    private init() {
        // Ensure photos directory exists on init
        Task {
            try? await createPhotosDirectoryIfNeeded()
        }
    }

    // MARK: - PhotoStorageProtocol Implementation

    func savePhoto(_ image: UIImage) async throws -> String {
        // Generate unique identifier
        let identifier = UUID().uuidString + ".jpg"

        // Resize image if needed
        let resizedImage = resizeImageIfNeeded(image)

        // Convert to JPEG data
        guard let imageData = resizedImage.jpegData(compressionQuality: jpegQuality) else {
            logger.error("Failed to convert image to JPEG data")
            throw PhotoStorageError.compressionFailed
        }

        // Ensure directory exists
        try await createPhotosDirectoryIfNeeded()

        // Get file URL
        let fileURL = try getPhotoURL(for: identifier)

        // Write to disk
        do {
            try imageData.write(to: fileURL, options: .atomic)
            logger.info("Saved photo: \(identifier), size: \(imageData.count) bytes")
            return identifier
        } catch {
            logger.error("Failed to save photo: \(error.localizedDescription)")
            throw PhotoStorageError.saveFailed(error)
        }
    }

    func loadPhoto(identifier: String) async throws -> UIImage {
        let fileURL = try getPhotoURL(for: identifier)

        // Check file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.warning("Photo not found: \(identifier)")
            throw PhotoStorageError.photoNotFound
        }

        // Load data
        do {
            let data = try Data(contentsOf: fileURL)

            guard let image = UIImage(data: data) else {
                logger.error("Failed to decode image data for: \(identifier)")
                throw PhotoStorageError.decodingFailed
            }

            logger.debug("Loaded photo: \(identifier)")
            return image
        } catch {
            logger.error("Failed to load photo: \(error.localizedDescription)")
            throw PhotoStorageError.loadFailed(error)
        }
    }

    func deletePhoto(identifier: String) async throws {
        let fileURL = try getPhotoURL(for: identifier)

        // Check file exists before attempting delete
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // Already deleted or never existed - not an error
            logger.debug("Photo already deleted or not found: \(identifier)")
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
            logger.info("Deleted photo: \(identifier)")
        } catch {
            logger.error("Failed to delete photo: \(error.localizedDescription)")
            throw PhotoStorageError.deleteFailed(error)
        }
    }

    func getPhotoSize(identifier: String) async throws -> Int64 {
        let fileURL = try getPhotoURL(for: identifier)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw PhotoStorageError.photoNotFound
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            return size
        } catch {
            logger.error("Failed to get photo size: \(error.localizedDescription)")
            throw PhotoStorageError.attributeReadFailed(error)
        }
    }

    func getTotalStorageSize() async throws -> Int64 {
        let directoryURL = try getPhotosDirectoryURL()

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return 0
        }

        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                // Skip files we can't read attributes for
                continue
            }
        }

        logger.debug("Total photo storage: \(totalSize) bytes")
        return totalSize
    }

    func cleanupOrphanedPhotos() async throws -> Int {
        // NOTE: This requires access to SwiftData context to check which photos are referenced
        // For now, this is a placeholder that returns 0
        // TODO: Implement full orphan cleanup with ModelContext injection
        // FIXME: Consider making this accept a Set<String> of valid identifiers from caller
        logger.info("Orphan cleanup called - requires ModelContext integration")
        return 0
    }

    // MARK: - Helper Methods

    /// Gets the Photos directory URL within Documents
    private func getPhotosDirectoryURL() throws -> URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PhotoStorageError.documentsDirectoryNotFound
        }
        return documentsURL.appendingPathComponent(photoDirectoryName, isDirectory: true)
    }

    /// Gets the full URL for a photo identifier
    private func getPhotoURL(for identifier: String) throws -> URL {
        let directoryURL = try getPhotosDirectoryURL()
        return directoryURL.appendingPathComponent(identifier)
    }

    /// Creates the Photos directory if it doesn't exist
    private func createPhotosDirectoryIfNeeded() throws {
        let directoryURL = try getPhotosDirectoryURL()

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            logger.info("Created photos directory at: \(directoryURL.path)")
        }
    }

    /// Resizes an image if it exceeds the maximum dimension
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size

        // Check if resize needed
        guard size.width > maxImageDimension || size.height > maxImageDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxImageDimension, height: maxImageDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxImageDimension * aspectRatio, height: maxImageDimension)
        }

        // OPTIMIZE: Consider using vImage for better performance on large images
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        logger.debug("Resized image from \(Int(size.width))x\(Int(size.height)) to \(Int(newSize.width))x\(Int(newSize.height))")
        return resizedImage
    }
}

// MARK: - Error Types

enum PhotoStorageError: LocalizedError {
    case documentsDirectoryNotFound
    case compressionFailed
    case saveFailed(Error)
    case loadFailed(Error)
    case decodingFailed
    case photoNotFound
    case deleteFailed(Error)
    case attributeReadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .documentsDirectoryNotFound:
            return String(localized: "Documents directory not found", comment: "Photo storage error")
        case .compressionFailed:
            return String(localized: "Failed to compress image", comment: "Photo storage error")
        case .saveFailed(let error):
            return String(localized: "Failed to save photo: \(error.localizedDescription)", comment: "Photo storage error")
        case .loadFailed(let error):
            return String(localized: "Failed to load photo: \(error.localizedDescription)", comment: "Photo storage error")
        case .decodingFailed:
            return String(localized: "Failed to decode image data", comment: "Photo storage error")
        case .photoNotFound:
            return String(localized: "Photo not found", comment: "Photo storage error")
        case .deleteFailed(let error):
            return String(localized: "Failed to delete photo: \(error.localizedDescription)", comment: "Photo storage error")
        case .attributeReadFailed(let error):
            return String(localized: "Failed to read file attributes: \(error.localizedDescription)", comment: "Photo storage error")
        }
    }
}

// MARK: - Cleanup Extension

extension PhotoStorageService {
    /// Cleans up photos not in the provided set of valid identifiers
    /// Call this with identifiers from all ItemPhoto records in the database
    func cleanupPhotos(keepingIdentifiers validIdentifiers: Set<String>) async throws -> Int {
        let directoryURL = try getPhotosDirectoryURL()

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return 0
        }

        var deletedCount = 0

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for fileURL in contents {
            let identifier = fileURL.lastPathComponent

            if !validIdentifiers.contains(identifier) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    deletedCount += 1
                    logger.info("Cleaned up orphaned photo: \(identifier)")
                } catch {
                    logger.warning("Failed to clean up orphaned photo: \(identifier)")
                }
            }
        }

        logger.info("Cleanup complete: removed \(deletedCount) orphaned photos")
        return deletedCount
    }
}

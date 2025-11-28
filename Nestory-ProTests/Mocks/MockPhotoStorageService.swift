//
//  MockPhotoStorageService.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import UIKit
@testable import Nestory_Pro

/// Mock implementation of PhotoStorageProtocol for testing
final class MockPhotoStorageService: PhotoStorageProtocol, @unchecked Sendable {
    // MARK: - Mock Configuration
    var shouldThrowError: Bool = false
    var errorToThrow: Error = MockPhotoStorageError.saveFailed
    var mockPhotoIdentifier: String = "mock-photo-id"
    var mockPhotoSize: Int64 = 1024 * 1024 // 1MB
    var mockTotalSize: Int64 = 10 * 1024 * 1024 // 10MB
    var mockCleanupCount: Int = 5

    // MARK: - Storage
    private var storedPhotos: [String: UIImage] = [:]

    // MARK: - Call Tracking
    var savePhotoCallCount = 0
    var loadPhotoCallCount = 0
    var deletePhotoCallCount = 0
    var getPhotoSizeCallCount = 0
    var getTotalStorageSizeCallCount = 0
    var cleanupOrphanedPhotosCallCount = 0
    var lastSavedImage: UIImage?
    var lastLoadedIdentifier: String?
    var lastDeletedIdentifier: String?

    // MARK: - PhotoStorageProtocol
    func savePhoto(_ image: UIImage) async throws -> String {
        savePhotoCallCount += 1
        lastSavedImage = image

        if shouldThrowError {
            throw errorToThrow
        }

        let identifier = mockPhotoIdentifier + "-\(savePhotoCallCount)"
        storedPhotos[identifier] = image
        return identifier
    }

    func loadPhoto(identifier: String) async throws -> UIImage {
        loadPhotoCallCount += 1
        lastLoadedIdentifier = identifier

        if shouldThrowError {
            throw errorToThrow
        }

        guard let photo = storedPhotos[identifier] else {
            throw MockPhotoStorageError.photoNotFound
        }

        return photo
    }

    func deletePhoto(identifier: String) async throws {
        deletePhotoCallCount += 1
        lastDeletedIdentifier = identifier

        if shouldThrowError {
            throw errorToThrow
        }

        storedPhotos.removeValue(forKey: identifier)
    }

    func getPhotoSize(identifier: String) async throws -> Int64 {
        getPhotoSizeCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard storedPhotos[identifier] != nil else {
            throw MockPhotoStorageError.photoNotFound
        }

        return mockPhotoSize
    }

    func getTotalStorageSize() async throws -> Int64 {
        getTotalStorageSizeCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return mockTotalSize
    }

    func cleanupOrphanedPhotos() async throws -> Int {
        cleanupOrphanedPhotosCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return mockCleanupCount
    }

    // MARK: - Test Helpers
    func reset() {
        shouldThrowError = false
        errorToThrow = MockPhotoStorageError.saveFailed
        mockPhotoIdentifier = "mock-photo-id"
        mockPhotoSize = 1024 * 1024
        mockTotalSize = 10 * 1024 * 1024
        mockCleanupCount = 5
        storedPhotos.removeAll()
        savePhotoCallCount = 0
        loadPhotoCallCount = 0
        deletePhotoCallCount = 0
        getPhotoSizeCallCount = 0
        getTotalStorageSizeCallCount = 0
        cleanupOrphanedPhotosCallCount = 0
        lastSavedImage = nil
        lastLoadedIdentifier = nil
        lastDeletedIdentifier = nil
    }

    func setStoredPhoto(_ image: UIImage, identifier: String) {
        storedPhotos[identifier] = image
    }
}

// MARK: - Mock Errors
enum MockPhotoStorageError: Error, Sendable {
    case saveFailed
    case loadFailed
    case photoNotFound
    case deleteFailed
}

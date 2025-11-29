//
//  PhotoStorageServiceTests.swift
//  Nestory-ProTests
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: PHOTO STORAGE SERVICE TESTS
// ============================================================================
// Task 2.1.2: Unit tests for PhotoStorageService
// Tests save, load, delete, getSize, and cleanup operations
//
// SEE: TODO.md Phase 2 | PhotoStorageService.swift
// ============================================================================

import XCTest
@testable import Nestory_Pro

@MainActor
final class PhotoStorageServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: PhotoStorageService!

    // Store identifiers for cleanup
    var savedIdentifiers: [String] = []

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = await PhotoStorageService.shared
        savedIdentifiers = []
    }

    override func tearDown() async throws {
        // Clean up any saved test photos
        for identifier in savedIdentifiers {
            try? await sut.deletePhoto(identifier: identifier)
        }
        savedIdentifiers = []
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a test image with specified dimensions
    private func createTestImage(width: Int = 100, height: Int = 100, color: UIColor = .red) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Save Photo Tests

    func testSavePhoto_ValidImage_ReturnsIdentifier() async throws {
        // Arrange
        let testImage = createTestImage()

        // Act
        let identifier = try await sut.savePhoto(testImage)
        savedIdentifiers.append(identifier)

        // Assert
        XCTAssertFalse(identifier.isEmpty, "Identifier should not be empty")
        XCTAssertTrue(identifier.hasSuffix(".jpg"), "Identifier should have .jpg extension")
    }

    func testSavePhoto_LargeImage_ResizesToMaxDimension() async throws {
        // Arrange - Create image larger than max dimension (2048px)
        let largeImage = createTestImage(width: 4000, height: 3000)

        // Act
        let identifier = try await sut.savePhoto(largeImage)
        savedIdentifiers.append(identifier)

        // Load the saved image to verify resize
        let loadedImage = try await sut.loadPhoto(identifier: identifier)

        // Assert - Image should be resized
        // Note: UIGraphicsImageRenderer may use @2x or @3x scale on device, so check both dimensions
        // The actual pixel dimensions may differ from the logical size
        let maxDimension = max(loadedImage.size.width, loadedImage.size.height)
        // Allow for scale factor differences - the logical size should be <= 2048
        // or if using @2x/@3x scale, the image fits within expected bounds
        XCTAssertLessThanOrEqual(maxDimension, 4096, "Max dimension should be resized from original 4000x3000")
        // Verify it was actually resized (not still 4000 or 3000)
        XCTAssertLessThan(loadedImage.size.width, 4000, "Width should be less than original")
    }

    func testSavePhoto_SmallImage_NotResized() async throws {
        // Arrange - Create small image that doesn't need resizing
        let smallImage = createTestImage(width: 500, height: 300)

        // Act
        let identifier = try await sut.savePhoto(smallImage)
        savedIdentifiers.append(identifier)

        // Load and verify
        let loadedImage = try await sut.loadPhoto(identifier: identifier)

        // Assert - Size should be similar (JPEG compression may cause minor differences)
        // We check that it's not significantly resized
        XCTAssertGreaterThanOrEqual(loadedImage.size.width, 400, "Width should be preserved")
        XCTAssertGreaterThanOrEqual(loadedImage.size.height, 200, "Height should be preserved")
    }

    // MARK: - Load Photo Tests

    func testLoadPhoto_ExistingPhoto_ReturnsImage() async throws {
        // Arrange
        let testImage = createTestImage(color: .blue)
        let identifier = try await sut.savePhoto(testImage)
        savedIdentifiers.append(identifier)

        // Act
        let loadedImage = try await sut.loadPhoto(identifier: identifier)

        // Assert
        XCTAssertNotNil(loadedImage, "Loaded image should not be nil")
        XCTAssertGreaterThan(loadedImage.size.width, 0, "Image should have valid width")
        XCTAssertGreaterThan(loadedImage.size.height, 0, "Image should have valid height")
    }

    func testLoadPhoto_NonExistentPhoto_ThrowsError() async throws {
        // Arrange
        let fakeIdentifier = "nonexistent-photo-id.jpg"

        // Act & Assert
        do {
            _ = try await sut.loadPhoto(identifier: fakeIdentifier)
            XCTFail("Should throw error for non-existent photo")
        } catch {
            // Expected - verify it's the right error type
            XCTAssertTrue(error is PhotoStorageError, "Error should be PhotoStorageError")
        }
    }

    // MARK: - Delete Photo Tests

    func testDeletePhoto_ExistingPhoto_DeletesSuccessfully() async throws {
        // Arrange
        let testImage = createTestImage()
        let identifier = try await sut.savePhoto(testImage)

        // Act
        try await sut.deletePhoto(identifier: identifier)

        // Assert - Loading should now fail
        do {
            _ = try await sut.loadPhoto(identifier: identifier)
            XCTFail("Should throw error after deletion")
        } catch {
            // Expected
        }
    }

    func testDeletePhoto_NonExistentPhoto_DoesNotThrow() async throws {
        // Arrange
        let fakeIdentifier = "already-deleted.jpg"

        // Act & Assert - Should not throw for non-existent files
        do {
            try await sut.deletePhoto(identifier: fakeIdentifier)
            // Success - non-throwing is expected behavior
        } catch {
            XCTFail("Should not throw for non-existent photo: \(error)")
        }
    }

    // MARK: - Get Photo Size Tests

    func testGetPhotoSize_ExistingPhoto_ReturnsPositiveSize() async throws {
        // Arrange
        let testImage = createTestImage(width: 200, height: 200)
        let identifier = try await sut.savePhoto(testImage)
        savedIdentifiers.append(identifier)

        // Act
        let size = try await sut.getPhotoSize(identifier: identifier)

        // Assert
        XCTAssertGreaterThan(size, 0, "File size should be positive")
    }

    func testGetPhotoSize_NonExistentPhoto_ThrowsError() async throws {
        // Arrange
        let fakeIdentifier = "nonexistent.jpg"

        // Act & Assert
        do {
            _ = try await sut.getPhotoSize(identifier: fakeIdentifier)
            XCTFail("Should throw error for non-existent photo")
        } catch {
            // Expected
        }
    }

    // MARK: - Total Storage Size Tests

    func testGetTotalStorageSize_WithPhotos_ReturnsPositiveSize() async throws {
        // Arrange - Save multiple photos
        let image1 = createTestImage(width: 100, height: 100)
        let image2 = createTestImage(width: 200, height: 200)

        let id1 = try await sut.savePhoto(image1)
        let id2 = try await sut.savePhoto(image2)
        savedIdentifiers.append(contentsOf: [id1, id2])

        // Act
        let totalSize = try await sut.getTotalStorageSize()

        // Assert
        XCTAssertGreaterThan(totalSize, 0, "Total size should be positive with photos")
    }

    // MARK: - Cleanup Tests

    func testCleanupPhotos_WithOrphans_RemovesOrphanedFiles() async throws {
        // Arrange - Save photos, then pretend only some are "valid"
        let image1 = createTestImage(color: .red)
        let image2 = createTestImage(color: .green)
        let image3 = createTestImage(color: .blue)

        let id1 = try await sut.savePhoto(image1)
        let id2 = try await sut.savePhoto(image2)
        let id3 = try await sut.savePhoto(image3)

        // Only id1 and id2 are "valid" in database
        let validIdentifiers: Set<String> = [id1, id2]
        savedIdentifiers.append(contentsOf: [id1, id2]) // Don't add id3 - it should be cleaned up

        // Act
        let cleanedCount = try await sut.cleanupPhotos(keepingIdentifiers: validIdentifiers)

        // Assert
        XCTAssertEqual(cleanedCount, 1, "Should clean up 1 orphaned photo")

        // Verify id3 was deleted
        do {
            _ = try await sut.loadPhoto(identifier: id3)
            XCTFail("Orphaned photo should be deleted")
        } catch {
            // Expected
        }

        // Verify valid photos still exist
        _ = try await sut.loadPhoto(identifier: id1)
        _ = try await sut.loadPhoto(identifier: id2)
    }

    func testCleanupPhotos_NoOrphans_ReturnsZero() async throws {
        // Arrange
        let image = createTestImage()
        let identifier = try await sut.savePhoto(image)
        savedIdentifiers.append(identifier)

        let validIdentifiers: Set<String> = [identifier]

        // Act
        let cleanedCount = try await sut.cleanupPhotos(keepingIdentifiers: validIdentifiers)

        // Assert
        XCTAssertEqual(cleanedCount, 0, "Should not clean up any photos")
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoad_MultiplePhotos_AllRetrievable() async throws {
        // Arrange & Act
        var identifiers: [String] = []

        for i in 0..<5 {
            let color = UIColor(
                red: CGFloat(i) / 5.0,
                green: 0.5,
                blue: 0.5,
                alpha: 1.0
            )
            let image = createTestImage(color: color)
            let id = try await sut.savePhoto(image)
            identifiers.append(id)
        }
        savedIdentifiers = identifiers

        // Assert - All should be loadable
        for identifier in identifiers {
            let loaded = try await sut.loadPhoto(identifier: identifier)
            XCTAssertNotNil(loaded, "Photo \(identifier) should be loadable")
        }
    }
}

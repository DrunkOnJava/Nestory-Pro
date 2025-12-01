//
//  PendingCaptureTests.swift
//  Nestory-ProTests
//
//  F8-10: Unit tests for PendingCapture model
//

import XCTest
import CoreLocation
@testable import Nestory_Pro

@MainActor
final class PendingCaptureTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_DefaultValues_HasCorrectDefaults() {
        // Arrange & Act
        let capture = PendingCapture(photoIdentifier: "test.jpg")

        // Assert
        XCTAssertFalse(capture.id.uuidString.isEmpty)
        XCTAssertEqual(capture.photoIdentifier, "test.jpg")
        XCTAssertEqual(capture.status, .pending)
        XCTAssertTrue(capture.itemName.isEmpty)
        XCTAssertNil(capture.roomID)
        XCTAssertNil(capture.categoryID)
        XCTAssertNil(capture.containerID)
        XCTAssertTrue(capture.notes.isEmpty)
        XCTAssertNil(capture.suggestions)
        XCTAssertNil(capture.location)
    }

    func testInit_WithAllParameters_SetsAllValues() {
        // Arrange
        let id = UUID()
        let date = Date()
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let location = CaptureLocation(coordinate: coordinate, accuracy: 10.0, timestamp: date)
        let roomID = UUID()
        let categoryID = UUID()
        let suggestions = CaptureSuggestions(suggestedNames: ["Test"])

        // Act
        let capture = PendingCapture(
            id: id,
            capturedAt: date,
            location: location,
            photoIdentifier: "photo.jpg",
            status: .processing,
            itemName: "Test Item",
            roomID: roomID,
            categoryID: categoryID,
            containerID: nil,
            notes: "Test notes",
            suggestions: suggestions
        )

        // Assert
        XCTAssertEqual(capture.id, id)
        XCTAssertEqual(capture.capturedAt, date)
        XCTAssertEqual(capture.location?.latitude, 37.7749)
        XCTAssertEqual(capture.photoIdentifier, "photo.jpg")
        XCTAssertEqual(capture.status, .processing)
        XCTAssertEqual(capture.itemName, "Test Item")
        XCTAssertEqual(capture.roomID, roomID)
        XCTAssertEqual(capture.categoryID, categoryID)
        XCTAssertEqual(capture.notes, "Test notes")
        XCTAssertEqual(capture.suggestions?.suggestedNames, ["Test"])
    }

    // MARK: - Computed Property Tests

    func testHasBeenEdited_EmptyCapture_ReturnsFalse() {
        // Arrange
        let capture = PendingCapture(photoIdentifier: "test.jpg")

        // Assert
        XCTAssertFalse(capture.hasBeenEdited)
    }

    func testHasBeenEdited_WithItemName_ReturnsTrue() {
        // Arrange
        var capture = PendingCapture(photoIdentifier: "test.jpg")
        capture.itemName = "My Item"

        // Assert
        XCTAssertTrue(capture.hasBeenEdited)
    }

    func testHasBeenEdited_WithRoomID_ReturnsTrue() {
        // Arrange
        var capture = PendingCapture(photoIdentifier: "test.jpg")
        capture.roomID = UUID()

        // Assert
        XCTAssertTrue(capture.hasBeenEdited)
    }

    func testHasBeenEdited_WithCategoryID_ReturnsTrue() {
        // Arrange
        var capture = PendingCapture(photoIdentifier: "test.jpg")
        capture.categoryID = UUID()

        // Assert
        XCTAssertTrue(capture.hasBeenEdited)
    }

    func testIsReadyToProcess_EmptyName_ReturnsFalse() {
        // Arrange
        let capture = PendingCapture(photoIdentifier: "test.jpg")

        // Assert
        XCTAssertFalse(capture.isReadyToProcess)
    }

    func testIsReadyToProcess_WithNameAndPendingStatus_ReturnsTrue() {
        // Arrange
        var capture = PendingCapture(photoIdentifier: "test.jpg")
        capture.itemName = "My Item"

        // Assert
        XCTAssertTrue(capture.isReadyToProcess)
    }

    func testIsReadyToProcess_WithNameButProcessingStatus_ReturnsFalse() {
        // Arrange
        var capture = PendingCapture(photoIdentifier: "test.jpg", status: .processing)
        capture.itemName = "My Item"

        // Assert
        XCTAssertFalse(capture.isReadyToProcess)
    }

    func testAge_RecentCapture_ReturnsSmallValue() {
        // Arrange
        let capture = PendingCapture(
            capturedAt: Date(),
            photoIdentifier: "test.jpg"
        )

        // Assert
        XCTAssertLessThan(capture.age, 1.0) // Less than 1 second
    }

    func testIsExpired_RecentCapture_ReturnsFalse() {
        // Arrange
        let capture = PendingCapture(photoIdentifier: "test.jpg")

        // Assert
        XCTAssertFalse(capture.isExpired)
    }

    func testIsExpired_OldCapture_ReturnsTrue() {
        // Arrange
        let oldDate = Date().addingTimeInterval(-31 * 24 * 60 * 60) // 31 days ago
        let capture = PendingCapture(
            capturedAt: oldDate,
            photoIdentifier: "test.jpg"
        )

        // Assert
        XCTAssertTrue(capture.isExpired)
    }

    // MARK: - Equatable Tests

    func testEquatable_SameID_ReturnsTrue() {
        // Arrange
        let id = UUID()
        let capture1 = PendingCapture(id: id, photoIdentifier: "1.jpg")
        let capture2 = PendingCapture(id: id, photoIdentifier: "2.jpg")

        // Assert
        XCTAssertEqual(capture1, capture2)
    }

    func testEquatable_DifferentID_ReturnsFalse() {
        // Arrange
        let capture1 = PendingCapture(photoIdentifier: "test.jpg")
        let capture2 = PendingCapture(photoIdentifier: "test.jpg")

        // Assert
        XCTAssertNotEqual(capture1, capture2)
    }

    // MARK: - Factory Method Tests

    func testFromCapture_CreatesCorrectCapture() {
        // Arrange
        let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)

        // Act
        let capture = PendingCapture.fromCapture(
            photoIdentifier: "photo123.jpg",
            location: coordinate,
            locationAccuracy: 5.0
        )

        // Assert
        XCTAssertEqual(capture.photoIdentifier, "photo123.jpg")
        XCTAssertEqual(capture.status, .pending)
        XCTAssertNotNil(capture.location)
        if let location = capture.location {
            XCTAssertEqual(location.latitude, 40.7128, accuracy: 0.0001)
            XCTAssertEqual(location.longitude, -74.0060, accuracy: 0.0001)
            XCTAssertEqual(location.accuracy, 5.0)
        }
    }

    func testFromCapture_NoLocation_CreatesWithoutLocation() {
        // Act
        let capture = PendingCapture.fromCapture(
            photoIdentifier: "photo.jpg",
            location: nil
        )

        // Assert
        XCTAssertNil(capture.location)
    }

    // MARK: - Codable Tests

    func testCodable_EncodesAndDecodes() throws {
        // Arrange
        let coordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        let location = CaptureLocation(coordinate: coordinate, accuracy: 15.0)
        var capture = PendingCapture(
            location: location,
            photoIdentifier: "test.jpg"
        )
        capture.itemName = "Test Item"
        capture.roomID = UUID()

        // Act
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(capture)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PendingCapture.self, from: data)

        // Assert
        XCTAssertEqual(decoded.id, capture.id)
        XCTAssertEqual(decoded.photoIdentifier, capture.photoIdentifier)
        XCTAssertEqual(decoded.itemName, capture.itemName)
        XCTAssertEqual(decoded.roomID, capture.roomID)
        XCTAssertEqual(decoded.location?.latitude, capture.location?.latitude)
    }
}

// MARK: - Processing Status Tests

@MainActor
final class ProcessingStatusTests: XCTestCase {

    func testDisplayName_ReturnsCorrectStrings() {
        XCTAssertEqual(ProcessingStatus.pending.displayName, "Pending")
        XCTAssertEqual(ProcessingStatus.processing.displayName, "Processing")
        XCTAssertEqual(ProcessingStatus.completed.displayName, "Completed")
        XCTAssertEqual(ProcessingStatus.failed.displayName, "Failed")
        XCTAssertEqual(ProcessingStatus.cancelled.displayName, "Cancelled")
    }

    func testSystemImage_ReturnsCorrectIcons() {
        XCTAssertEqual(ProcessingStatus.pending.systemImage, "clock")
        XCTAssertEqual(ProcessingStatus.processing.systemImage, "arrow.triangle.2.circlepath")
        XCTAssertEqual(ProcessingStatus.completed.systemImage, "checkmark.circle.fill")
        XCTAssertEqual(ProcessingStatus.failed.systemImage, "exclamationmark.triangle.fill")
        XCTAssertEqual(ProcessingStatus.cancelled.systemImage, "xmark.circle")
    }
}

// MARK: - Capture Location Tests

@MainActor
final class CaptureLocationTests: XCTestCase {

    func testInit_SetsAllProperties() {
        // Arrange
        let coordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let timestamp = Date()

        // Act
        let location = CaptureLocation(coordinate: coordinate, accuracy: 20.0, timestamp: timestamp)

        // Assert
        XCTAssertEqual(location.latitude, 48.8566)
        XCTAssertEqual(location.longitude, 2.3522)
        XCTAssertEqual(location.accuracy, 20.0)
        XCTAssertEqual(location.timestamp, timestamp)
    }

    func testCoordinate_ReturnsCLLocationCoordinate() {
        // Arrange
        let location = CaptureLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            accuracy: nil
        )

        // Act
        let coord = location.coordinate

        // Assert
        XCTAssertEqual(coord.latitude, 35.6762)
        XCTAssertEqual(coord.longitude, 139.6503)
    }
}

// MARK: - Capture Suggestions Tests

@MainActor
final class CaptureSuggestionsTests: XCTestCase {

    func testHasSuggestions_EmptySuggestions_ReturnsFalse() {
        // Arrange
        let suggestions = CaptureSuggestions()

        // Assert
        XCTAssertFalse(suggestions.hasSuggestions)
    }

    func testHasSuggestions_WithNames_ReturnsTrue() {
        // Arrange
        let suggestions = CaptureSuggestions(suggestedNames: ["Chair", "Table"])

        // Assert
        XCTAssertTrue(suggestions.hasSuggestions)
    }

    func testHasSuggestions_WithCategoryID_ReturnsTrue() {
        // Arrange
        let suggestions = CaptureSuggestions(suggestedCategoryID: UUID())

        // Assert
        XCTAssertTrue(suggestions.hasSuggestions)
    }

    func testHasSuggestions_WithDuplicateIDs_ReturnsTrue() {
        // Arrange
        let suggestions = CaptureSuggestions(potentialDuplicateIDs: [UUID()])

        // Assert
        XCTAssertTrue(suggestions.hasSuggestions)
    }
}

// MARK: - Array Extension Tests

@MainActor
final class PendingCaptureArrayTests: XCTestCase {

    func testFiltered_ReturnsCapturesWithMatchingStatus() {
        // Arrange
        var capture1 = PendingCapture(photoIdentifier: "1.jpg")
        var capture2 = PendingCapture(photoIdentifier: "2.jpg")
        var capture3 = PendingCapture(photoIdentifier: "3.jpg")
        capture1.status = .pending
        capture2.status = .completed
        capture3.status = .pending

        let captures = [capture1, capture2, capture3]

        // Act
        let pending = captures.filtered(by: .pending)

        // Assert
        XCTAssertEqual(pending.count, 2)
    }

    func testEdited_ReturnsOnlyEditedCaptures() {
        // Arrange
        var capture1 = PendingCapture(photoIdentifier: "1.jpg")
        var capture2 = PendingCapture(photoIdentifier: "2.jpg")
        capture1.itemName = "Edited"

        let captures = [capture1, capture2]

        // Assert
        XCTAssertEqual(captures.edited.count, 1)
        XCTAssertEqual(captures.edited.first?.itemName, "Edited")
    }

    func testReadyToProcess_ReturnsOnlyReadyCaptures() {
        // Arrange
        var capture1 = PendingCapture(photoIdentifier: "1.jpg")
        var capture2 = PendingCapture(photoIdentifier: "2.jpg")
        var capture3 = PendingCapture(photoIdentifier: "3.jpg", status: .completed)
        capture1.itemName = "Ready"
        capture3.itemName = "Not Ready - Wrong Status"

        let captures = [capture1, capture2, capture3]

        // Assert
        XCTAssertEqual(captures.readyToProcess.count, 1)
        XCTAssertEqual(captures.readyToProcess.first?.itemName, "Ready")
    }

    func testExpired_ReturnsOnlyExpiredCaptures() {
        // Arrange
        let capture1 = PendingCapture(photoIdentifier: "1.jpg")
        let capture2 = PendingCapture(
            capturedAt: Date().addingTimeInterval(-31 * 24 * 60 * 60),
            photoIdentifier: "2.jpg"
        )

        let captures = [capture1, capture2]

        // Assert
        XCTAssertEqual(captures.expired.count, 1)
    }

    func testPendingCount_ReturnsCorrectCount() {
        // Arrange
        var capture1 = PendingCapture(photoIdentifier: "1.jpg")
        var capture2 = PendingCapture(photoIdentifier: "2.jpg")
        capture2.status = .completed

        let captures = [capture1, capture2]

        // Assert
        XCTAssertEqual(captures.pendingCount, 1)
    }
}

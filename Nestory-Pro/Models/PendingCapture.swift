//
//  PendingCapture.swift
//  Nestory-Pro
//
//  F8-02: Temporary model for batch capture queue
//

// ============================================================================
// F8-02: PendingCapture Temporary Model
// ============================================================================
// Represents a captured photo awaiting processing in the batch capture queue.
// NOT persisted via SwiftData - stored in memory/disk by CaptureQueueService.
//
// Lifecycle:
// 1. Created when user takes a photo in BatchCaptureView
// 2. Stored in CaptureQueueService queue (memory + disk backup)
// 3. User edits via QuickEditSheet to add name/room/category
// 4. Processed into full Item when user confirms
// 5. Automatically cleaned up after 30 days if not processed
//
// SEE: TODO.md F8-02 | CaptureQueueService.swift | BatchCaptureView.swift
// ============================================================================

import Foundation
import UIKit
import CoreLocation

// MARK: - PendingCapture Model

/// Temporary model for photos awaiting processing in batch capture queue
struct PendingCapture: Identifiable, Equatable, Sendable {

    // MARK: - Properties

    /// Unique identifier for this pending capture
    let id: UUID

    /// Timestamp when photo was captured
    let capturedAt: Date

    /// Optional location where photo was taken
    let location: CaptureLocation?

    /// Reference to the stored photo (file identifier, not actual image data)
    /// The actual UIImage is stored via PendingCaptureStorage to a temp file
    let photoIdentifier: String

    /// Current processing status
    var status: ProcessingStatus

    /// User-assigned name for the item (empty until edited)
    var itemName: String

    /// User-assigned room ID (nil until edited)
    var roomID: UUID?

    /// User-assigned category ID (nil until edited)
    var categoryID: UUID?

    /// User-assigned container ID (nil until edited)
    var containerID: UUID?

    /// Optional notes from user
    var notes: String

    /// Smart suggestions from AI/ML processing (Silver+ feature - F8-08)
    var suggestions: CaptureSuggestions?

    // MARK: - Initialization (nonisolated for cross-actor creation)

    nonisolated init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        location: CaptureLocation? = nil,
        photoIdentifier: String,
        status: ProcessingStatus = .pending,
        itemName: String = "",
        roomID: UUID? = nil,
        categoryID: UUID? = nil,
        containerID: UUID? = nil,
        notes: String = "",
        suggestions: CaptureSuggestions? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.location = location
        self.photoIdentifier = photoIdentifier
        self.status = status
        self.itemName = itemName
        self.roomID = roomID
        self.categoryID = categoryID
        self.containerID = containerID
        self.notes = notes
        self.suggestions = suggestions
    }

    // MARK: - Computed Properties (nonisolated for cross-actor access)

    /// Whether this capture has been edited by user
    nonisolated var hasBeenEdited: Bool {
        !itemName.isEmpty || roomID != nil || categoryID != nil
    }

    /// Whether this capture is ready to be processed into an Item
    nonisolated var isReadyToProcess: Bool {
        !itemName.isEmpty && status == .pending
    }

    /// Age of this capture in seconds
    nonisolated var age: TimeInterval {
        Date().timeIntervalSince(capturedAt)
    }

    /// Whether this capture is older than 30 days (cleanup candidate)
    nonisolated var isExpired: Bool {
        age > 30 * 24 * 60 * 60 // 30 days in seconds
    }

    // MARK: - Equatable

    static func == (lhs: PendingCapture, rhs: PendingCapture) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Processing Status

/// Status of a pending capture in the queue
enum ProcessingStatus: String, Codable, Sendable, CaseIterable {
    /// Awaiting user edit and processing
    case pending

    /// Currently being processed into an Item
    case processing

    /// Successfully processed and Item created
    case completed

    /// Processing failed (will retry)
    case failed

    /// User cancelled/deleted from queue
    case cancelled

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - Capture Location

/// Location data captured with a photo
struct CaptureLocation: Equatable, Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let timestamp: Date

    nonisolated init(coordinate: CLLocationCoordinate2D, accuracy: Double? = nil, timestamp: Date = Date()) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.accuracy = accuracy
        self.timestamp = timestamp
    }

    nonisolated var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Capture Suggestions (F8-08)

/// AI/ML-generated suggestions for a pending capture (Silver+ feature)
struct CaptureSuggestions: Equatable, Codable, Sendable {
    /// Suggested item names based on image recognition
    var suggestedNames: [String]

    /// Suggested category ID based on image classification
    var suggestedCategoryID: UUID?

    /// Confidence score for category suggestion (0.0 - 1.0)
    var categoryConfidence: Double?

    /// Potential duplicate item IDs detected
    var potentialDuplicateIDs: [UUID]

    /// Suggested grouping with other pending captures
    var suggestedGroupID: UUID?

    init(
        suggestedNames: [String] = [],
        suggestedCategoryID: UUID? = nil,
        categoryConfidence: Double? = nil,
        potentialDuplicateIDs: [UUID] = [],
        suggestedGroupID: UUID? = nil
    ) {
        self.suggestedNames = suggestedNames
        self.suggestedCategoryID = suggestedCategoryID
        self.categoryConfidence = categoryConfidence
        self.potentialDuplicateIDs = potentialDuplicateIDs
        self.suggestedGroupID = suggestedGroupID
    }

    /// Whether any suggestions are available
    nonisolated var hasSuggestions: Bool {
        !suggestedNames.isEmpty || suggestedCategoryID != nil || !potentialDuplicateIDs.isEmpty
    }
}

// MARK: - Codable Conformance for Persistence

extension PendingCapture: Codable {
    enum CodingKeys: String, CodingKey {
        case id, capturedAt, location, photoIdentifier, status
        case itemName, roomID, categoryID, containerID, notes, suggestions
    }
}

// MARK: - Factory Methods

extension PendingCapture {
    /// Creates a new PendingCapture from a just-taken photo
    /// - Parameters:
    ///   - photoIdentifier: The identifier returned from PendingCaptureStorage
    ///   - location: Optional current device location
    /// - Returns: A new PendingCapture ready for the queue
    nonisolated static func fromCapture(
        photoIdentifier: String,
        location: CLLocationCoordinate2D? = nil,
        locationAccuracy: Double? = nil
    ) -> PendingCapture {
        let captureLocation: CaptureLocation? = location.map {
            CaptureLocation(coordinate: $0, accuracy: locationAccuracy)
        }
        return PendingCapture(
            location: captureLocation,
            photoIdentifier: photoIdentifier
        )
    }
}

// MARK: - Batch Operations Support (nonisolated for cross-actor access)

extension Array where Element == PendingCapture {
    /// Returns captures that match the given status
    nonisolated func filtered(by status: ProcessingStatus) -> [PendingCapture] {
        filter { $0.status == status }
    }

    /// Returns captures that have been edited
    nonisolated var edited: [PendingCapture] {
        filter { $0.hasBeenEdited }
    }

    /// Returns captures ready to process
    nonisolated var readyToProcess: [PendingCapture] {
        filter { $0.isReadyToProcess }
    }

    /// Returns expired captures (older than 30 days)
    nonisolated var expired: [PendingCapture] {
        filter { $0.isExpired }
    }

    /// Total count of pending captures
    nonisolated var pendingCount: Int {
        filtered(by: .pending).count
    }
}

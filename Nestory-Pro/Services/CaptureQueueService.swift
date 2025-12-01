//
//  CaptureQueueService.swift
//  Nestory-Pro
//
//  F8-03: Capture queue management service
//

// ============================================================================
// F8-03: CaptureQueueService
// ============================================================================
// Manages the batch capture queue for pending photos.
// - Queue management with in-memory + disk persistence
// - Background photo compression and storage
// - Crash recovery from disk backup
// - Auto-cleanup of expired captures (30 days)
// - Thread-safe actor implementation
//
// USAGE:
// 1. Add capture: await CaptureQueueService.shared.addCapture(image: photo)
// 2. Get queue: await CaptureQueueService.shared.pendingCaptures
// 3. Process: await CaptureQueueService.shared.processCapture(id:)
//
// SEE: TODO.md F8-03 | PendingCapture.swift | BatchCaptureView.swift
// ============================================================================

import Foundation
import UIKit
import CoreLocation
import OSLog
import os.signpost

// MARK: - CaptureQueueService

/// Actor-based service for managing the batch capture queue
actor CaptureQueueService {
    /// Shared singleton instance
    nonisolated static let shared = CaptureQueueService()

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "CaptureQueue")
    private let signpostLog = OSLog(subsystem: "com.drunkonjava.nestory", category: .pointsOfInterest)
    private let fileManager = FileManager.default

    /// In-memory queue of pending captures
    private var captures: [PendingCapture] = []

    /// Directory for storing pending capture photos
    private let pendingPhotosDirectoryName = "PendingCaptures"

    /// Filename for queue persistence
    private let queuePersistenceFilename = "capture_queue.json"

    /// JPEG compression quality for pending captures (lower than permanent storage)
    private let pendingJpegQuality: CGFloat = 0.7

    /// Maximum dimension for pending capture photos (faster processing)
    private let maxPendingPhotoDimension: CGFloat = 1600

    // MARK: - Initialization

    private init() {
        Task { [weak self] in
            await self?.loadPersistedQueue()
            await self?.cleanupExpiredCaptures()
        }
    }

    // MARK: - Public API: Queue Access

    /// Current count of pending captures
    var pendingCount: Int {
        captures.filtered(by: .pending).count
    }

    /// All pending captures in queue order
    var pendingCaptures: [PendingCapture] {
        captures.filter { $0.status == .pending }
    }

    /// All captures including processed/failed
    var allCaptures: [PendingCapture] {
        captures
    }

    /// Check if queue is empty
    var isEmpty: Bool {
        pendingCaptures.isEmpty
    }

    /// Get a specific capture by ID
    func capture(withID id: UUID) -> PendingCapture? {
        captures.first { $0.id == id }
    }

    // MARK: - Public API: Add Captures

    /// Adds a new photo to the capture queue
    /// - Parameters:
    ///   - image: The captured UIImage
    ///   - location: Optional device location at capture time
    ///   - locationAccuracy: Accuracy of the location
    /// - Returns: The created PendingCapture
    @discardableResult
    func addCapture(
        image: UIImage,
        location: CLLocationCoordinate2D? = nil,
        locationAccuracy: Double? = nil
    ) async throws -> PendingCapture {
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "Add Capture", signpostID: signpostID)
        defer { os_signpost(.end, log: signpostLog, name: "Add Capture", signpostID: signpostID) }

        logger.info("Adding new capture to queue")

        // Save photo to pending storage
        let photoIdentifier = try await savePendingPhoto(image)

        // Create capture model
        let capture = PendingCapture.fromCapture(
            photoIdentifier: photoIdentifier,
            location: location,
            locationAccuracy: locationAccuracy
        )

        // Add to queue
        captures.append(capture)

        // Persist queue to disk
        await persistQueue()

        logger.info("Added capture \(capture.id) to queue. Total pending: \(self.pendingCount)")
        return capture
    }

    /// Adds multiple photos to the queue in batch
    /// - Parameters:
    ///   - images: Array of captured UIImages
    ///   - location: Optional shared location for all captures
    /// - Returns: Array of created PendingCaptures
    func addCaptures(
        images: [UIImage],
        location: CLLocationCoordinate2D? = nil
    ) async throws -> [PendingCapture] {
        logger.info("Adding batch of \(images.count) captures to queue")

        var newCaptures: [PendingCapture] = []

        for image in images {
            let capture = try await addCapture(image: image, location: location)
            newCaptures.append(capture)
        }

        return newCaptures
    }

    // MARK: - Public API: Update Captures

    /// Updates a pending capture with user edits
    /// - Parameters:
    ///   - id: The capture ID to update
    ///   - itemName: User-assigned name
    ///   - roomID: User-assigned room
    ///   - categoryID: User-assigned category
    ///   - containerID: User-assigned container
    ///   - notes: User notes
    func updateCapture(
        id: UUID,
        itemName: String? = nil,
        roomID: UUID? = nil,
        categoryID: UUID? = nil,
        containerID: UUID? = nil,
        notes: String? = nil
    ) async {
        guard let index = captures.firstIndex(where: { $0.id == id }) else {
            logger.warning("Attempted to update non-existent capture: \(id)")
            return
        }

        if let itemName = itemName {
            captures[index].itemName = itemName
        }
        if let roomID = roomID {
            captures[index].roomID = roomID
        }
        if let categoryID = categoryID {
            captures[index].categoryID = categoryID
        }
        if let containerID = containerID {
            captures[index].containerID = containerID
        }
        if let notes = notes {
            captures[index].notes = notes
        }

        await persistQueue()
        logger.debug("Updated capture \(id)")
    }

    /// Applies room assignment to multiple captures
    func assignRoom(_ roomID: UUID, to captureIDs: [UUID]) async {
        for id in captureIDs {
            if let index = captures.firstIndex(where: { $0.id == id }) {
                captures[index].roomID = roomID
            }
        }
        await persistQueue()
        logger.info("Assigned room \(roomID) to \(captureIDs.count) captures")
    }

    /// Applies category assignment to multiple captures
    func assignCategory(_ categoryID: UUID, to captureIDs: [UUID]) async {
        for id in captureIDs {
            if let index = captures.firstIndex(where: { $0.id == id }) {
                captures[index].categoryID = categoryID
            }
        }
        await persistQueue()
        logger.info("Assigned category \(categoryID) to \(captureIDs.count) captures")
    }

    // MARK: - Public API: Process Captures

    /// Marks a capture as processing (preparing to create Item)
    func markProcessing(_ id: UUID) async {
        guard let index = captures.firstIndex(where: { $0.id == id }) else { return }
        captures[index].status = .processing
        await persistQueue()
    }

    /// Marks a capture as completed (Item created successfully)
    func markCompleted(_ id: UUID) async {
        guard let index = captures.firstIndex(where: { $0.id == id }) else { return }
        captures[index].status = .completed
        await persistQueue()
        logger.info("Capture \(id) marked completed")
    }

    /// Marks a capture as failed (will retry)
    func markFailed(_ id: UUID) async {
        guard let index = captures.firstIndex(where: { $0.id == id }) else { return }
        captures[index].status = .failed
        await persistQueue()
        logger.warning("Capture \(id) marked failed")
    }

    /// Retries failed captures by resetting status to pending
    func retryFailed() async {
        for index in captures.indices where captures[index].status == .failed {
            captures[index].status = .pending
        }
        await persistQueue()
        logger.info("Reset failed captures to pending")
    }

    // MARK: - Public API: Delete Captures

    /// Removes a capture from the queue and deletes its photo
    func removeCapture(_ id: UUID) async {
        guard let index = captures.firstIndex(where: { $0.id == id }) else {
            logger.warning("Attempted to remove non-existent capture: \(id)")
            return
        }

        let capture = captures[index]

        // Delete the photo file
        await deletePendingPhoto(identifier: capture.photoIdentifier)

        // Remove from queue
        captures.remove(at: index)

        await persistQueue()
        logger.info("Removed capture \(id) from queue. Remaining: \(self.captures.count)")
    }

    /// Removes multiple captures from the queue
    func removeCaptures(_ ids: [UUID]) async {
        for id in ids {
            await removeCapture(id)
        }
    }

    /// Removes all completed captures and their photos
    func clearCompleted() async {
        let completedCaptures = captures.filter { $0.status == .completed }

        for capture in completedCaptures {
            await deletePendingPhoto(identifier: capture.photoIdentifier)
        }

        captures.removeAll { $0.status == .completed }
        await persistQueue()
        logger.info("Cleared \(completedCaptures.count) completed captures")
    }

    /// Removes all captures from the queue
    func clearAll() async {
        for capture in captures {
            await deletePendingPhoto(identifier: capture.photoIdentifier)
        }

        captures.removeAll()
        await persistQueue()
        logger.info("Cleared all captures from queue")
    }

    // MARK: - Photo Storage

    /// Loads a pending capture's photo
    func loadPhoto(for capture: PendingCapture) async -> UIImage? {
        await loadPendingPhoto(identifier: capture.photoIdentifier)
    }

    /// Loads a pending capture's photo by identifier
    func loadPhoto(identifier: String) async -> UIImage? {
        await loadPendingPhoto(identifier: identifier)
    }

    // MARK: - Private: Photo Storage

    private func getPendingPhotosDirectory() throws -> URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CaptureQueueError.directoryNotFound
        }
        let directoryURL = documentsURL.appendingPathComponent(pendingPhotosDirectoryName, isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            logger.info("Created pending photos directory")
        }

        return directoryURL
    }

    private func savePendingPhoto(_ image: UIImage) async throws -> String {
        let identifier = UUID().uuidString + ".jpg"

        // Resize if needed
        let resizedImage = resizeImageIfNeeded(image)

        guard let imageData = resizedImage.jpegData(compressionQuality: pendingJpegQuality) else {
            logger.error("Failed to compress pending photo")
            throw CaptureQueueError.compressionFailed
        }

        let directoryURL = try getPendingPhotosDirectory()
        let fileURL = directoryURL.appendingPathComponent(identifier)

        try imageData.write(to: fileURL, options: .atomic)
        logger.debug("Saved pending photo: \(identifier), size: \(imageData.count) bytes")

        return identifier
    }

    private func loadPendingPhoto(identifier: String) async -> UIImage? {
        do {
            let directoryURL = try getPendingPhotosDirectory()
            let fileURL = directoryURL.appendingPathComponent(identifier)

            guard fileManager.fileExists(atPath: fileURL.path) else {
                logger.warning("Pending photo not found: \(identifier)")
                return nil
            }

            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            logger.error("Failed to load pending photo: \(error.localizedDescription)")
            return nil
        }
    }

    private func deletePendingPhoto(identifier: String) async {
        do {
            let directoryURL = try getPendingPhotosDirectory()
            let fileURL = directoryURL.appendingPathComponent(identifier)

            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                logger.debug("Deleted pending photo: \(identifier)")
            }
        } catch {
            logger.warning("Failed to delete pending photo \(identifier): \(error.localizedDescription)")
        }
    }

    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size

        guard size.width > maxPendingPhotoDimension || size.height > maxPendingPhotoDimension else {
            return image
        }

        let aspectRatio = size.width / size.height
        var newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxPendingPhotoDimension, height: maxPendingPhotoDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxPendingPhotoDimension * aspectRatio, height: maxPendingPhotoDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Private: Queue Persistence

    private func getQueuePersistenceURL() throws -> URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CaptureQueueError.directoryNotFound
        }
        return documentsURL.appendingPathComponent(queuePersistenceFilename)
    }

    private func persistQueue() async {
        do {
            let fileURL = try getQueuePersistenceURL()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(captures)
            try data.write(to: fileURL, options: .atomic)
            logger.debug("Persisted queue with \(self.captures.count) captures")
        } catch {
            logger.error("Failed to persist queue: \(error.localizedDescription)")
        }
    }

    private func loadPersistedQueue() async {
        do {
            let fileURL = try getQueuePersistenceURL()

            guard fileManager.fileExists(atPath: fileURL.path) else {
                logger.info("No persisted queue found")
                return
            }

            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            captures = try decoder.decode([PendingCapture].self, from: data)
            logger.info("Loaded persisted queue with \(self.captures.count) captures")
        } catch {
            logger.error("Failed to load persisted queue: \(error.localizedDescription)")
            captures = []
        }
    }

    // MARK: - Private: Cleanup

    private func cleanupExpiredCaptures() async {
        let expiredCaptures = captures.expired

        guard !expiredCaptures.isEmpty else { return }

        logger.info("Cleaning up \(expiredCaptures.count) expired captures")

        for capture in expiredCaptures {
            await deletePendingPhoto(identifier: capture.photoIdentifier)
        }

        captures.removeAll { $0.isExpired }
        await persistQueue()
    }

    /// Public method to trigger cleanup (e.g., on app launch)
    func performCleanup() async {
        await cleanupExpiredCaptures()
    }
}

// MARK: - CaptureQueueError

enum CaptureQueueError: LocalizedError {
    case directoryNotFound
    case compressionFailed
    case saveFailed(Error)
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return String(localized: "Documents directory not found", comment: "Capture queue error")
        case .compressionFailed:
            return String(localized: "Failed to compress photo", comment: "Capture queue error")
        case .saveFailed(let error):
            return String(localized: "Failed to save photo: \(error.localizedDescription)", comment: "Capture queue error")
        case .loadFailed(let error):
            return String(localized: "Failed to load photo: \(error.localizedDescription)", comment: "Capture queue error")
        }
    }
}

// MARK: - Queue Statistics

extension CaptureQueueService {
    /// Statistics about the current queue state
    struct QueueStatistics: Sendable {
        let totalCount: Int
        let pendingCount: Int
        let processingCount: Int
        let completedCount: Int
        let failedCount: Int
        let editedCount: Int
        let readyToProcessCount: Int
        let oldestCaptureAge: TimeInterval?
    }

    /// Gets current queue statistics
    func getStatistics() -> QueueStatistics {
        QueueStatistics(
            totalCount: captures.count,
            pendingCount: captures.filtered(by: .pending).count,
            processingCount: captures.filtered(by: .processing).count,
            completedCount: captures.filtered(by: .completed).count,
            failedCount: captures.filtered(by: .failed).count,
            editedCount: captures.edited.count,
            readyToProcessCount: captures.readyToProcess.count,
            oldestCaptureAge: captures.map(\.age).max()
        )
    }
}

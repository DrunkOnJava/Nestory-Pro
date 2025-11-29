import UIKit
import os.log

/// Manages background task execution for long-running operations
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "BackgroundTask")
    private var currentTaskID: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    /// Begin a background task for a long-running operation
    /// - Parameter name: Description of the task for debugging
    /// - Returns: Task identifier
    @discardableResult
    func beginBackgroundTask(named name: String) -> UIBackgroundTaskIdentifier {
        logger.info("Beginning background task: \(name)")

        currentTaskID = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            self?.logger.warning("Background task \(name) expired")
            self?.endBackgroundTask()
        }

        return currentTaskID
    }

    /// End the current background task
    func endBackgroundTask() {
        guard currentTaskID != .invalid else { return }

        logger.info("Ending background task")
        UIApplication.shared.endBackgroundTask(currentTaskID)
        currentTaskID = .invalid
    }

    /// Execute an async operation with background task protection
    func executeWithBackground<T>(
        named name: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        beginBackgroundTask(named: name)
        defer { endBackgroundTask() }
        return try await operation()
    }
}

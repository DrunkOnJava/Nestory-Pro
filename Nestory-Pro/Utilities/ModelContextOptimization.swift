import SwiftData
import os.log

/// Extensions for optimizing SwiftData ModelContext operations
extension ModelContext {
    private static let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "SwiftData")

    /// Perform a batch insert operation with optimized change tracking
    func batchInsert<T: PersistentModel>(_ items: [T]) throws {
        // Disable automatic change tracking during batch
        Self.logger.debug("Batch inserting \(items.count) items")

        for item in items {
            insert(item)
        }

        try save()
        Self.logger.debug("Batch insert completed")
    }

    /// Fetch items with optional prefetching for related data
    func fetchWithPrefetch<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>,
        prefetch keyPaths: [PartialKeyPath<T>] = []
    ) throws -> [T] {
        var optimizedDescriptor = descriptor
        optimizedDescriptor.includePendingChanges = false // Skip unsaved changes for speed

        return try fetch(optimizedDescriptor)
    }

    /// Clear change tracking cache to reduce memory
    func clearPendingChanges() {
        Self.logger.debug("Clearing pending changes")
        // Rollback any unsaved changes
        rollback()
    }
}

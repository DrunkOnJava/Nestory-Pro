//
//  ImageCache.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import UIKit
import OSLog

/// Thread-safe image caching system using NSCache with automatic memory management
actor ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "ImageCache")

    private init() {
        // Configure cache limits
        // OPTIMIZE: Adjust limits based on device memory (iPad vs iPhone)
        // NOTE: 50MB is conservative; consider 100MB for modern devices
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        // Set up memory warning observer
        Task { @MainActor in
            NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleMemoryWarning()
                }
            }
        }
    }

    // MARK: - Cache Operations

    /// Retrieves an image from cache, or loads it from disk if not cached
    func image(for identifier: String) async -> UIImage? {
        let key = identifier as NSString

        // Check cache first
        if let cachedImage = cache.object(forKey: key) {
            logger.debug("Cache hit for identifier: \(identifier)")
            return cachedImage
        }

        // Load from disk
        logger.debug("Cache miss for identifier: \(identifier), loading from disk")
        guard let image = await loadImageFromDisk(identifier: identifier) else {
            logger.warning("Failed to load image from disk: \(identifier)")
            return nil
        }

        // Store in cache with cost based on image size
        let cost = calculateImageCost(image)
        cache.setObject(image, forKey: key, cost: cost)
        logger.debug("Cached image: \(identifier), cost: \(cost) bytes")

        return image
    }

    /// Stores an image in the cache
    func cacheImage(_ image: UIImage, for identifier: String) {
        let key = identifier as NSString
        let cost = calculateImageCost(image)
        cache.setObject(image, forKey: key, cost: cost)
        logger.debug("Manually cached image: \(identifier), cost: \(cost) bytes")
    }

    /// Removes a specific image from the cache
    func removeImage(for identifier: String) {
        let key = identifier as NSString
        cache.removeObject(forKey: key)
        logger.debug("Removed image from cache: \(identifier)")
    }

    /// Clears all cached images
    func clearCache() {
        cache.removeAllObjects()
        logger.info("Cleared all cached images")
    }

    // MARK: - Private Helpers

    /// Loads an image from the app's Documents directory
    private func loadImageFromDisk(identifier: String) async -> UIImage? {
        let fileManager = FileManager.default

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let imageURL = documentsURL.appendingPathComponent(identifier)

        guard fileManager.fileExists(atPath: imageURL.path) else {
            return nil
        }

        // Load image data on a background thread
        return await Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: imageURL),
                  let image = UIImage(data: data) else {
                return nil
            }
            return image
        }.value
    }

    /// Calculates the memory cost of an image in bytes
    private func calculateImageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let width = cgImage.width
        let height = cgImage.height

        return width * height * bytesPerPixel
    }

    /// Handles memory warnings by clearing the cache
    private func handleMemoryWarning() {
        logger.warning("Memory warning received, clearing image cache")
        clearCache()
    }
}

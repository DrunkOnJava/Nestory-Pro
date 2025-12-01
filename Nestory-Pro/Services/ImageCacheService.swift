//
//  ImageCacheService.swift
//  Nestory-Pro
//
//  Created by Griffin on 12/1/25.
//

// ============================================================================
// Task P2-17-1: Image Caching Strategy
// In-memory cache for frequently accessed images using NSCache
// Complements PhotoStorageService's disk-based thumbnail storage
// ============================================================================

import Foundation
import UIKit
import OSLog

/// In-memory image cache service for fast repeated access
/// Uses NSCache for automatic memory management under pressure
@MainActor
final class ImageCacheService {
    /// Shared singleton instance
    static let shared = ImageCacheService()

    // MARK: - Configuration

    /// Maximum number of images to cache (NSCache handles this automatically under memory pressure)
    private let maxCacheCount = 100

    /// Maximum total cost (approximate bytes) - 50MB default
    private let maxCacheCost = 50 * 1024 * 1024

    // MARK: - Private Properties

    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let fullImageCache = NSCache<NSString, UIImage>()
    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "ImageCache")

    // MARK: - Initialization

    private init() {
        configureCache()
        setupMemoryWarningObserver()
    }

    private func configureCache() {
        thumbnailCache.countLimit = maxCacheCount
        thumbnailCache.totalCostLimit = maxCacheCost

        // Full images are larger, so fewer in cache
        fullImageCache.countLimit = maxCacheCount / 2
        fullImageCache.totalCostLimit = maxCacheCost * 2
    }

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }
    }

    // MARK: - Public Interface

    /// Loads a thumbnail image with in-memory caching
    /// - Parameter identifier: The photo identifier
    /// - Returns: Cached or freshly loaded thumbnail image
    func loadThumbnail(identifier: String) async -> UIImage? {
        let key = identifier as NSString

        // Check in-memory cache first
        if let cached = thumbnailCache.object(forKey: key) {
            logger.debug("Thumbnail cache hit: \(identifier)")
            return cached
        }

        // Load from disk via PhotoStorageService
        let thumbnail = await PhotoStorageService.shared.loadThumbnail(for: identifier)

        if let thumbnail {
            // Cache for future access
            let cost = estimateImageCost(thumbnail)
            thumbnailCache.setObject(thumbnail, forKey: key, cost: cost)
            logger.debug("Thumbnail cached: \(identifier), cost: \(cost)")
        }

        return thumbnail
    }

    /// Loads a full-resolution image with in-memory caching
    /// - Parameter identifier: The photo identifier
    /// - Returns: Cached or freshly loaded full image
    func loadFullImage(identifier: String) async -> UIImage? {
        let key = identifier as NSString

        // Check in-memory cache first
        if let cached = fullImageCache.object(forKey: key) {
            logger.debug("Full image cache hit: \(identifier)")
            return cached
        }

        // Load from disk via PhotoStorageService
        do {
            let image = try await PhotoStorageService.shared.loadPhoto(identifier: identifier)

            // Cache for future access
            let cost = estimateImageCost(image)
            fullImageCache.setObject(image, forKey: key, cost: cost)
            logger.debug("Full image cached: \(identifier), cost: \(cost)")

            return image
        } catch {
            logger.error("Failed to load full image: \(identifier) - \(error.localizedDescription)")
            return nil
        }
    }

    /// Prefetches thumbnails for a list of identifiers
    /// Call this when about to display a list of items
    func prefetchThumbnails(identifiers: [String]) {
        Task {
            for identifier in identifiers {
                _ = await loadThumbnail(identifier: identifier)
            }
        }
    }

    /// Removes a specific image from cache (call when photo is deleted)
    func removeFromCache(identifier: String) {
        let key = identifier as NSString
        thumbnailCache.removeObject(forKey: key)
        fullImageCache.removeObject(forKey: key)
        logger.debug("Removed from cache: \(identifier)")
    }

    /// Clears all cached images
    func clearCache() {
        thumbnailCache.removeAllObjects()
        fullImageCache.removeAllObjects()
        logger.info("Image cache cleared")
    }

    // MARK: - Memory Management

    private func handleMemoryWarning() {
        // NSCache handles eviction automatically, but we can be proactive
        logger.warning("Memory warning received, clearing full image cache")
        fullImageCache.removeAllObjects()
        // Keep thumbnails since they're smaller and more frequently needed
    }

    /// Estimates the memory cost of an image in bytes
    private func estimateImageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            return 0
        }
        return cgImage.bytesPerRow * cgImage.height
    }
}

// MARK: - AsyncImage-like View for Cached Photos

import SwiftUI

/// A view that displays a cached photo thumbnail with loading state
struct CachedThumbnailView: View {
    let identifier: String
    let size: CGFloat

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(NestoryTheme.Colors.chipBackground)
                    .overlay {
                        ProgressView()
                    }
            } else {
                Rectangle()
                    .fill(NestoryTheme.Colors.chipBackground)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(NestoryTheme.Colors.muted)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoading = true
        image = await ImageCacheService.shared.loadThumbnail(identifier: identifier)
        isLoading = false
    }
}

/// A view that displays a cached full-resolution photo
struct CachedPhotoView: View {
    let identifier: String

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                Rectangle()
                    .fill(NestoryTheme.Colors.chipBackground)
                    .overlay {
                        ProgressView()
                    }
            } else {
                Rectangle()
                    .fill(NestoryTheme.Colors.chipBackground)
                    .overlay {
                        VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                            Text("Unable to load photo")
                                .font(NestoryTheme.Typography.caption)
                        }
                        .foregroundStyle(NestoryTheme.Colors.muted)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoading = true
        image = await ImageCacheService.shared.loadFullImage(identifier: identifier)
        isLoading = false
    }
}

// MARK: - Preview

#Preview("Cached Thumbnail") {
    CachedThumbnailView(
        identifier: "preview-image",
        size: NestoryTheme.Metrics.thumbnailLarge
    )
    .padding()
}

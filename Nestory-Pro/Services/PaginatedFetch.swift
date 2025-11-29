//
//  PaginatedFetch.swift
//  Nestory-Pro
//
//  Performance optimization: Pagination for large SwiftData queries
//

import Foundation
import SwiftData

/// Configuration for paginated fetching
struct PaginationConfig {
    let pageSize: Int
    let prefetchDistance: Int

    static let `default` = PaginationConfig(pageSize: 50, prefetchDistance: 10)
    static let small = PaginationConfig(pageSize: 20, prefetchDistance: 5)
    static let large = PaginationConfig(pageSize: 100, prefetchDistance: 20)
}

/// Manages paginated fetching of SwiftData models
@Observable
@MainActor
final class PaginatedFetch<T: PersistentModel> {
    private let modelContext: ModelContext
    private let config: PaginationConfig
    private let sortDescriptors: [SortDescriptor<T>]
    private let predicate: Predicate<T>?

    private(set) var items: [T] = []
    private(set) var isLoading = false
    private(set) var hasMorePages = true
    private var currentPage = 0

    init(
        modelContext: ModelContext,
        sortDescriptors: [SortDescriptor<T>],
        predicate: Predicate<T>? = nil,
        config: PaginationConfig = .default
    ) {
        self.modelContext = modelContext
        self.sortDescriptors = sortDescriptors
        self.predicate = predicate
        self.config = config
    }

    /// Loads the first page
    func loadInitialPage() async {
        currentPage = 0
        items = []
        hasMorePages = true
        await loadNextPage()
    }

    /// Loads the next page if available
    func loadNextPage() async {
        guard !isLoading, hasMorePages else { return }

        isLoading = true
        defer { isLoading = false }

        var descriptor = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: sortDescriptors
        )
        descriptor.fetchLimit = config.pageSize
        descriptor.fetchOffset = currentPage * config.pageSize

        do {
            let newItems = try modelContext.fetch(descriptor)
            items.append(contentsOf: newItems)
            hasMorePages = newItems.count == config.pageSize
            currentPage += 1
        } catch {
            hasMorePages = false
        }
    }

    /// Called when an item becomes visible to trigger prefetching
    func onItemAppear(_ item: T) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        if index >= items.count - config.prefetchDistance {
            await loadNextPage()
        }
    }

    /// Resets and reloads from the beginning
    func refresh() async {
        await loadInitialPage()
    }
}

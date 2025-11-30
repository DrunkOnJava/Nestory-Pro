//
//  ViewSnapshotTests.swift
//  Nestory-ProTests
//
//  Snapshot tests for main app views
//  Created for v1.1 - Tasks 9.3.1-9.3.4
//

// ============================================================================
// SNAPSHOT TESTS
// ============================================================================
// These tests capture baseline images of key views to detect unintended
// visual regressions. Run with recording=true to generate new baselines.
//
// TASKS:
// - 9.3.1: Inventory list snapshot
// - 9.3.2: Item detail snapshot
// - 9.3.3: Paywall snapshot
// - 9.3.4: Reports tab snapshot
//
// SEE: TODO.md v1.1 | SnapshotHelpers.swift
// ============================================================================

import XCTest
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import Nestory_Pro

// MARK: - 9.3.1: Inventory List Snapshots

final class InventorySnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Set to true to record new baselines, false to compare
        // isRecording = false
    }

    /// 9.3.1a - Empty inventory state
    @MainActor func testInventoryList_Empty() {            let container = PreviewContainer.emptyInventory()

            assertViewSnapshot(
                matching: InventoryTab(),
                container: container,
                named: "empty"
            )
    }

    /// 9.3.1b - Inventory with sample items
    @MainActor func testInventoryList_WithItems() {            let container = PreviewContainer.withSampleData()

            assertViewSnapshot(
                matching: InventoryTab(),
                container: container,
                named: "with_items"
            )
    }

    /// 9.3.1c - Inventory with many items (stress test)
    @MainActor func testInventoryList_ManyItems() {            let container = PreviewContainer.withManyItems(count: 20)

            assertViewSnapshot(
                matching: InventoryTab(),
                container: container,
                named: "many_items"
            )
    }

    /// 9.3.1d - Multiple device sizes
    @MainActor func testInventoryList_MultiDevice() {            let container = PreviewContainer.withSampleData()

            assertMultiDeviceSnapshot(
                matching: InventoryTab(),
                container: container
            )
    }
}

// MARK: - 9.3.2: Item Detail Snapshots

final class ItemDetailSnapshotTests: XCTestCase {

    /// 9.3.2a - Item with full details
    @MainActor func testItemDetail_FullyDocumented() {            let container = PreviewContainer.withSampleData()
            let context = container.mainContext

            // Get first item from sample data
            let descriptor = FetchDescriptor<Item>()
            guard let item = try? context.fetch(descriptor).first else {
                XCTFail("No items in sample data")
                return
            }

            assertViewSnapshot(
                matching: ItemDetailView(item: item),
                container: container,
                named: "fully_documented"
            )
    }

    /// 9.3.2b - Item with minimal data
    @MainActor func testItemDetail_MinimalData() {            let container = PreviewContainer.withBasicData()
            let context = container.mainContext

            // Create minimal item
            let item = Item(
                name: "Basic Item",
                condition: .good
            )
            context.insert(item)
            try? context.save()

            assertViewSnapshot(
                matching: ItemDetailView(item: item),
                container: container,
                named: "minimal_data"
            )
    }

    /// 9.3.2c - Multiple device sizes
    @MainActor func testItemDetail_MultiDevice() {            let container = PreviewContainer.withSampleData()
            let context = container.mainContext

            let descriptor = FetchDescriptor<Item>()
            guard let item = try? context.fetch(descriptor).first else {
                XCTFail("No items in sample data")
                return
            }

            assertMultiDeviceSnapshot(
                matching: ItemDetailView(item: item),
                container: container
            )
    }
}

// MARK: - 9.3.3: Paywall Snapshots

final class PaywallSnapshotTests: XCTestCase {

    /// 9.3.3a - Item limit paywall (Free user)
    @MainActor func testPaywall_ItemLimit_Free() {            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .itemLimit),
                container: container,
                named: "item_limit_free",
                isProUnlocked: false
            )
    }

    /// 9.3.3b - Loss list limit paywall
    @MainActor func testPaywall_LossListLimit() {            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .lossListLimit),
                container: container,
                named: "loss_list_limit",
                isProUnlocked: false
            )
    }

    /// 9.3.3c - Photos in PDF paywall
    @MainActor func testPaywall_PhotosInPDF() {            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .photosInPDF),
                container: container,
                named: "photos_in_pdf",
                isProUnlocked: false
            )
    }

    /// 9.3.3d - CSV export paywall
    @MainActor func testPaywall_CSVExport() {            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .csvExport),
                container: container,
                named: "csv_export",
                isProUnlocked: false
            )
    }

    /// 9.3.3e - Already Pro state
    @MainActor func testPaywall_AlreadyPro() {            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .itemLimit),
                container: container,
                named: "already_pro",
                isProUnlocked: true
            )
    }

    /// 9.3.3f - Multiple device sizes
    @MainActor func testPaywall_MultiDevice() {            let container = PreviewContainer.empty()

            assertMultiDeviceSnapshot(
                matching: ContextualPaywallSheet(context: .itemLimit),
                container: container,
                isProUnlocked: false
            )
    }
}

// MARK: - 9.3.4: Reports Tab Snapshots

final class ReportsSnapshotTests: XCTestCase {

    /// 9.3.4a - Reports with items
    @MainActor func testReportsTab_WithItems() {            let container = PreviewContainer.withSampleData()

            assertViewSnapshot(
                matching: ReportsTab(),
                container: container,
                named: "with_items"
            )
    }

    /// 9.3.4b - Reports empty inventory
    @MainActor func testReportsTab_Empty() {            let container = PreviewContainer.emptyInventory()

            assertViewSnapshot(
                matching: ReportsTab(),
                container: container,
                named: "empty"
            )
    }

    /// 9.3.4c - Multiple device sizes
    @MainActor func testReportsTab_MultiDevice() {            let container = PreviewContainer.withSampleData()

            assertMultiDeviceSnapshot(
                matching: ReportsTab(),
                container: container
            )
    }
}

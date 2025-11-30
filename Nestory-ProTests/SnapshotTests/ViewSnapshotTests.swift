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
    func testInventoryList_Empty() async {
        await MainActor.run {
            let container = PreviewContainer.emptyInventory()

            assertViewSnapshot(
                matching: InventoryTab(),
                container: container,
                named: "empty"
            )
        }
    }

    /// 9.3.1b - Inventory with sample items
    func testInventoryList_WithItems() async {
        await MainActor.run {
            let container = PreviewContainer.withSampleData()

            assertViewSnapshot(
                matching: InventoryTab(),
                container: container,
                named: "with_items"
            )
        }
    }

    /// 9.3.1c - Inventory with many items (stress test)
    func testInventoryList_ManyItems() async {
        await MainActor.run {
            let container = PreviewContainer.withManyItems(count: 20)

            assertViewSnapshot(
                matching: InventoryTab(),
                container: container,
                named: "many_items"
            )
        }
    }

    /// 9.3.1d - Multiple device sizes
    func testInventoryList_MultiDevice() async {
        await MainActor.run {
            let container = PreviewContainer.withSampleData()

            assertMultiDeviceSnapshot(
                matching: InventoryTab(),
                container: container
            )
        }
    }
}

// MARK: - 9.3.2: Item Detail Snapshots

final class ItemDetailSnapshotTests: XCTestCase {

    /// 9.3.2a - Item with full details
    func testItemDetail_FullyDocumented() async {
        await MainActor.run {
            let container = PreviewContainer.withSampleData()
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
    }

    /// 9.3.2b - Item with minimal data
    func testItemDetail_MinimalData() async {
        await MainActor.run {
            let container = PreviewContainer.withBasicData()
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
    }

    /// 9.3.2c - Multiple device sizes
    func testItemDetail_MultiDevice() async {
        await MainActor.run {
            let container = PreviewContainer.withSampleData()
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
}

// MARK: - 9.3.3: Paywall Snapshots

final class PaywallSnapshotTests: XCTestCase {

    /// 9.3.3a - Item limit paywall (Free user)
    func testPaywall_ItemLimit_Free() async {
        await MainActor.run {
            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .itemLimit),
                container: container,
                named: "item_limit_free",
                isProUnlocked: false
            )
        }
    }

    /// 9.3.3b - Loss list limit paywall
    func testPaywall_LossListLimit() async {
        await MainActor.run {
            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .lossListLimit),
                container: container,
                named: "loss_list_limit",
                isProUnlocked: false
            )
        }
    }

    /// 9.3.3c - Photos in PDF paywall
    func testPaywall_PhotosInPDF() async {
        await MainActor.run {
            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .photosInPDF),
                container: container,
                named: "photos_in_pdf",
                isProUnlocked: false
            )
        }
    }

    /// 9.3.3d - CSV export paywall
    func testPaywall_CSVExport() async {
        await MainActor.run {
            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .csvExport),
                container: container,
                named: "csv_export",
                isProUnlocked: false
            )
        }
    }

    /// 9.3.3e - Already Pro state
    func testPaywall_AlreadyPro() async {
        await MainActor.run {
            let container = PreviewContainer.empty()

            assertViewSnapshot(
                matching: ContextualPaywallSheet(context: .itemLimit),
                container: container,
                named: "already_pro",
                isProUnlocked: true
            )
        }
    }

    /// 9.3.3f - Multiple device sizes
    func testPaywall_MultiDevice() async {
        await MainActor.run {
            let container = PreviewContainer.empty()

            assertMultiDeviceSnapshot(
                matching: ContextualPaywallSheet(context: .itemLimit),
                container: container,
                isProUnlocked: false
            )
        }
    }
}

// MARK: - 9.3.4: Reports Tab Snapshots

final class ReportsSnapshotTests: XCTestCase {

    /// 9.3.4a - Reports with items
    func testReportsTab_WithItems() async {
        await MainActor.run {
            let container = PreviewContainer.withSampleData()

            assertViewSnapshot(
                matching: ReportsTab(),
                container: container,
                named: "with_items"
            )
        }
    }

    /// 9.3.4b - Reports empty inventory
    func testReportsTab_Empty() async {
        await MainActor.run {
            let container = PreviewContainer.emptyInventory()

            assertViewSnapshot(
                matching: ReportsTab(),
                container: container,
                named: "empty"
            )
        }
    }

    /// 9.3.4c - Multiple device sizes
    func testReportsTab_MultiDevice() async {
        await MainActor.run {
            let container = PreviewContainer.withSampleData()

            assertMultiDeviceSnapshot(
                matching: ReportsTab(),
                container: container
            )
        }
    }
}

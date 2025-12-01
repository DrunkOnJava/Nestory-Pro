//
//  SnapshotHelpers.swift
//  Nestory-ProTests
//
//  Created for v1.1 - P1-00
//

// ============================================================================
// SNAPSHOT TESTING SETUP
// ============================================================================
// Helpers for swift-snapshot-testing integration.
// Package added via project.yml (XcodeGen).
//
// USAGE:
// - Snapshots are stored in __Snapshots__ directories next to test files
// - Run tests once to record baselines (set isRecording = true)
// - CI will fail if snapshots change unexpectedly
//
// SEE: TODO.md P1-00 | CLAUDE.md Snapshot Testing section
// ============================================================================

import SwiftUI
import SwiftData
import XCTest
import SnapshotTesting
@testable import Nestory_Pro

// MARK: - Snapshot Configuration

/// Standard device configurations for snapshot testing
enum SnapshotDevice: CaseIterable {
    case iPhone17ProMax
    case iPhone17Pro
    case iPhoneSE3
    case iPadPro12_9

    var config: ViewImageConfig {
        switch self {
        case .iPhone17ProMax:
            return .iPhone13ProMax  // Closest available config
        case .iPhone17Pro:
            return .iPhone13Pro
        case .iPhoneSE3:
            return .iPhoneSe
        case .iPadPro12_9:
            return .iPadPro12_9
        }
    }

    var name: String {
        switch self {
        case .iPhone17ProMax: return "iPhone17ProMax"
        case .iPhone17Pro: return "iPhone17Pro"
        case .iPhoneSE3: return "iPhoneSE3"
        case .iPadPro12_9: return "iPadPro12_9"
        }
    }
}

// MARK: - Test Helpers

/// Creates a hosting controller for SwiftUI view snapshot testing
@MainActor
func snapshotController<V: View>(for view: V) -> UIViewController {
    let hostingController = UIHostingController(rootView: view)
    hostingController.view.frame = UIScreen.main.bounds
    return hostingController
}

/// Creates a configured view for snapshot testing with mock environment
@MainActor
func snapshotView<V: View>(
    _ view: V,
    container: ModelContainer,
    isProUnlocked: Bool = true
) -> some View {
    view
        .modelContainer(container)
        .environment(AppEnvironment.mock(isProUnlocked: isProUnlocked))
}

// MARK: - XCTestCase Extension

extension XCTestCase {

    /// Asserts a SwiftUI view matches its snapshot
    /// - Parameters:
    ///   - view: The SwiftUI view to snapshot
    ///   - container: The ModelContainer for SwiftData
    ///   - device: The device configuration to use
    ///   - name: Optional name suffix for the snapshot
    ///   - isProUnlocked: Whether Pro features are unlocked
    ///   - record: Set to true to record a new baseline
    @MainActor
    func assertViewSnapshot<V: View>(
        matching view: V,
        container: ModelContainer,
        on device: SnapshotDevice = .iPhone17ProMax,
        named name: String? = nil,
        isProUnlocked: Bool = true,
        record recording: Bool = false,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let configuredView = snapshotView(view, container: container, isProUnlocked: isProUnlocked)
        let controller = snapshotController(for: configuredView)

        assertSnapshot(
            of: controller,
            as: .image(on: device.config),
            named: name,
            record: recording,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Asserts a SwiftUI view matches snapshots on multiple devices
    /// - Parameters:
    ///   - view: The SwiftUI view to snapshot
    ///   - container: The ModelContainer for SwiftData
    ///   - devices: Array of device configurations to test
    ///   - isProUnlocked: Whether Pro features are unlocked
    ///   - record: Set to true to record new baselines
    @MainActor
    func assertMultiDeviceSnapshot<V: View>(
        matching view: V,
        container: ModelContainer,
        on devices: [SnapshotDevice] = [.iPhone17ProMax, .iPhoneSE3],
        isProUnlocked: Bool = true,
        record recording: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        for device in devices {
            assertViewSnapshot(
                matching: view,
                container: container,
                on: device,
                named: device.name,
                isProUnlocked: isProUnlocked,
                record: recording,
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}

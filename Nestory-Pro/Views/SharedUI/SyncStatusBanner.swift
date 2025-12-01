//
//  SyncStatusBanner.swift
//  Nestory-Pro
//
//  F7-03: Sync Status Banner UI Component
//

// ============================================================================
// F7-03: Sync Status Banner
// ============================================================================
// Displays current network/sync status as a banner at top of screen
// - Hidden when synced and online (normal state)
// - Yellow when syncing in progress
// - Green flash when sync just completed
// - Red when offline or sync error
// - Auto-dismisses success state after 3 seconds
//
// USAGE:
// Add to your view hierarchy:
//   VStack {
//       SyncStatusBanner()
//       // ... rest of content
//   }
//
// SEE: TODO.md F7-03 | CLAUDE.md
// ============================================================================

import SwiftUI

/// Banner states for sync/network status display
enum SyncBannerState: Equatable {
    case hidden
    case syncing
    case synced
    case offline
    case error(String)

    var isVisible: Bool {
        self != .hidden
    }

    var backgroundColor: Color {
        switch self {
        case .hidden:
            return .clear
        case .syncing:
            return NestoryTheme.Colors.warning.opacity(0.15)
        case .synced:
            return NestoryTheme.Colors.success.opacity(0.15)
        case .offline:
            return NestoryTheme.Colors.muted.opacity(0.15)
        case .error:
            return NestoryTheme.Colors.error.opacity(0.15)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .hidden:
            return .clear
        case .syncing:
            return NestoryTheme.Colors.warning
        case .synced:
            return NestoryTheme.Colors.success
        case .offline:
            return .secondary
        case .error:
            return NestoryTheme.Colors.error
        }
    }

    var systemImage: String {
        switch self {
        case .hidden:
            return ""
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud"
        case .offline:
            return "wifi.slash"
        case .error:
            return "exclamationmark.icloud"
        }
    }

    var message: String {
        switch self {
        case .hidden:
            return ""
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .offline:
            return "Offline - Changes will sync when connected"
        case .error(let msg):
            return "Sync error: \(msg)"
        }
    }
}

/// Displays current sync/network status as a dismissable banner
struct SyncStatusBanner: View {

    // MARK: - State

    @State private var bannerState: SyncBannerState = .hidden
    @State private var autoDismissTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let networkMonitor = NetworkMonitor.shared
    private let syncMonitor = CloudKitSyncMonitor.shared

    // MARK: - Body

    var body: some View {
        if bannerState.isVisible {
            bannerContent
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(NestoryTheme.Animation.quick, value: bannerState)
        }
    }

    @ViewBuilder
    private var bannerContent: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
            // Icon
            if bannerState == .syncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: bannerState.foregroundColor))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: bannerState.systemImage)
                    .font(.system(size: NestoryTheme.Metrics.iconSmall, weight: .medium))
                    .foregroundStyle(bannerState.foregroundColor)
            }

            // Message
            Text(bannerState.message)
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(bannerState.foregroundColor)

            Spacer()

            // Dismiss button for persistent states
            if bannerState == .offline || bannerState != .hidden {
                Button {
                    dismissBanner()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(bannerState.foregroundColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
        .padding(.vertical, NestoryTheme.Metrics.paddingSmall)
        .background(bannerState.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
        .padding(.top, NestoryTheme.Metrics.paddingXSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sync status: \(bannerState.message)")
        .accessibilityAddTraits(bannerState == .error("") ? .isStaticText : [])
    }

    // MARK: - State Management

    private func updateBannerState() {
        // Cancel any pending auto-dismiss
        autoDismissTask?.cancel()

        // Check network first
        if !networkMonitor.isConnected {
            bannerState = .offline
            return
        }

        // Check sync status
        switch syncMonitor.syncStatus {
        case .idle:
            // Check if we just synced (within last 5 seconds)
            if let lastSync = syncMonitor.lastSyncDate,
               Date().timeIntervalSince(lastSync) < 5 {
                bannerState = .synced
                scheduleAutoDismiss()
            } else {
                bannerState = .hidden
            }

        case .syncing:
            bannerState = .syncing

        case .error(let message):
            bannerState = .error(message)

        case .disabled, .notAvailable:
            bannerState = .hidden
        }
    }

    private func scheduleAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                withAnimation(NestoryTheme.Animation.quick) {
                    bannerState = .hidden
                }
            }
        }
    }

    private func dismissBanner() {
        withAnimation(NestoryTheme.Animation.quick) {
            bannerState = .hidden
        }
    }
}

// MARK: - Auto-Updating Version

/// A version that automatically updates based on network/sync state changes
struct AutoSyncStatusBanner: View {

    @State private var bannerState: SyncBannerState = .hidden
    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        Group {
            if bannerState.isVisible {
                SyncStatusBannerContent(state: bannerState) {
                    dismissBanner()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(NestoryTheme.Animation.quick, value: bannerState)
        .onAppear { updateState() }
        .onChange(of: NetworkMonitor.shared.isConnected) { _, _ in updateState() }
        .onChange(of: CloudKitSyncMonitor.shared.syncStatus) { _, _ in updateState() }
    }

    private func updateState() {
        autoDismissTask?.cancel()

        // Check network first
        if !NetworkMonitor.shared.isConnected {
            bannerState = .offline
            return
        }

        // Check sync status
        switch CloudKitSyncMonitor.shared.syncStatus {
        case .idle:
            if let lastSync = CloudKitSyncMonitor.shared.lastSyncDate,
               Date().timeIntervalSince(lastSync) < 5 {
                bannerState = .synced
                scheduleAutoDismiss()
            } else {
                bannerState = .hidden
            }
        case .syncing:
            bannerState = .syncing
        case .error(let message):
            bannerState = .error(message)
        case .disabled, .notAvailable:
            bannerState = .hidden
        }
    }

    private func scheduleAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                withAnimation(NestoryTheme.Animation.quick) {
                    bannerState = .hidden
                }
            }
        }
    }

    private func dismissBanner() {
        withAnimation(NestoryTheme.Animation.quick) {
            bannerState = .hidden
        }
    }
}

// MARK: - Internal Banner Content

private struct SyncStatusBannerContent: View {
    let state: SyncBannerState
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: NestoryTheme.Metrics.spacingSmall) {
            if state == .syncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: state.foregroundColor))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: state.systemImage)
                    .font(.system(size: NestoryTheme.Metrics.iconSmall, weight: .medium))
                    .foregroundStyle(state.foregroundColor)
            }

            Text(state.message)
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(state.foregroundColor)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(state.foregroundColor.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
        .padding(.vertical, NestoryTheme.Metrics.paddingSmall)
        .background(state.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusSmall))
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
        .padding(.top, NestoryTheme.Metrics.paddingXSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sync status: \(state.message)")
    }
}

// MARK: - Previews

#Preview("All States") {
    VStack(spacing: 20) {
        ForEach([
            SyncBannerState.syncing,
            SyncBannerState.synced,
            SyncBannerState.offline,
            SyncBannerState.error("Network timeout")
        ], id: \.message) { state in
            SyncStatusBannerContent(state: state) {}
        }
    }
    .padding()
    .background(NestoryTheme.Colors.background)
}

#Preview("Auto Banner") {
    VStack {
        AutoSyncStatusBanner()
        Spacer()
        Text("Main Content")
        Spacer()
    }
}

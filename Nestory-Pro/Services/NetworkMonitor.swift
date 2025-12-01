//
//  NetworkMonitor.swift
//  Nestory-Pro
//
//  F7-01: Network Monitor Service for offline mode indicator
//

// ============================================================================
// F7-01: Network Monitor Service
// ============================================================================
// Monitors network connectivity using NWPathMonitor
// - Publishes real-time online/offline state
// - Detects WiFi vs cellular connection type
// - Tracks expensive/constrained connections for user awareness
//
// USAGE:
// 1. Access via shared instance: NetworkMonitor.shared.isConnected
// 2. Observe changes: onChange(of: NetworkMonitor.shared.isConnected)
//
// SEE: TODO.md F7-01 | CLAUDE.md
// ============================================================================

import Foundation
import Combine
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    /// Whether device has network connectivity
    var isConnected: Bool = true

    /// Current connection type (WiFi, cellular, etc.)
    var connectionType: ConnectionType = .unknown

    /// Whether connection is "expensive" (e.g., cellular data)
    var isExpensive: Bool = false

    /// Whether connection is constrained (Low Data Mode enabled)
    var isConstrained: Bool = false

    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wired = "Wired"
        case none = "Offline"
        case unknown = "Unknown"

        /// SF Symbol for connection type
        var systemImage: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wired: return "cable.connector"
            case .none: return "wifi.slash"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        if path.status == .unsatisfied {
            connectionType = .none
        } else if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }

    /// Human-readable status description
    var statusDescription: String {
        if !isConnected {
            return "Offline"
        }

        var parts: [String] = [connectionType.rawValue]

        if isExpensive {
            parts.append("(metered)")
        }
        if isConstrained {
            parts.append("(low data)")
        }

        return parts.joined(separator: " ")
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Mock for Testing

#if DEBUG
/// Mock network monitor for previews and tests
@MainActor
final class MockNetworkMonitor {
    var isConnected: Bool
    var connectionType: NetworkMonitor.ConnectionType
    var isExpensive: Bool
    var isConstrained: Bool

    init(
        isConnected: Bool = true,
        connectionType: NetworkMonitor.ConnectionType = .wifi,
        isExpensive: Bool = false,
        isConstrained: Bool = false
    ) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    /// Simulate going offline
    func goOffline() {
        isConnected = false
        connectionType = .none
    }

    /// Simulate going online with WiFi
    func goOnline(type: NetworkMonitor.ConnectionType = .wifi) {
        isConnected = true
        connectionType = type
        isExpensive = (type == .cellular)
    }
}
#endif

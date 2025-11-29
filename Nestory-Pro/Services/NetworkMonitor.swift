//
//  NetworkMonitor.swift
//  Nestory-Pro
//
//  Performance optimization: Network status for CloudKit sync feedback
//

import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wired = "Wired"
        case unknown = "Unknown"
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

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }

    deinit {
        monitor.cancel()
    }
}

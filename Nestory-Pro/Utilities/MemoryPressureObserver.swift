//
//  MemoryPressureObserver.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import OSLog

/// Observes system memory pressure and triggers cache cleanup
final class MemoryPressureObserver {
    static let shared = MemoryPressureObserver()

    private let source: DispatchSourceMemoryPressure
    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "MemoryPressure")

    private init() {
        source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])
        source.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
        source.resume()
    }

    private func handleMemoryPressure() {
        let level = source.data
        if level.contains(.critical) {
            logger.warning("Critical memory pressure - clearing all caches")
            NotificationCenter.default.post(name: .didReceiveMemoryWarning, object: nil)
            Task {
                await ImageCache.shared.clearCache()
            }
        } else if level.contains(.warning) {
            logger.info("Memory pressure warning - reducing caches")
            Task {
                await ImageCache.shared.reduceCache()
            }
        }
    }
}

extension Notification.Name {
    static let didReceiveMemoryWarning = Notification.Name("didReceiveMemoryWarning")
}

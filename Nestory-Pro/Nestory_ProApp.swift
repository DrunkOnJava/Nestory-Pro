//
//  Nestory_ProApp.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: READ BEFORE MODIFYING
// ============================================================================
// This is the app entry point. Key architecture notes:
//
// ARCHITECTURE (Task 5.2.1 - COMPLETED):
// - AppEnvironment DI container holds all services
// - Injected at root via .environment(appEnv)
// - Views access via @Environment(AppEnvironment.self)
//
// WHEN ADDING NEW SERVICES:
// 1. Create the service conforming to its protocol
// 2. Add to AppEnvironment container
// 3. Inject via @Environment, not .shared
//
// SEEDING BEHAVIOR:
// - Default categories and rooms are seeded on first launch
//
// SEE: AppEnvironment.swift | TODO.md Task 5.2.1 | WARP.md Architecture
// ============================================================================

import SwiftUI
import SwiftData
import TipKit

@main
struct Nestory_ProApp: App {
    // Dependency injection container with all services
    let appEnv = AppEnvironment()

    init() {
        // Migrate Pro status from UserDefaults to Keychain (one-time migration)
        KeychainManager.migrateProStatusFromUserDefaults()

        // Start listening for IAP transactions
        // Capture validator before Task to avoid capturing self
        let validator = appEnv.iapValidator
        Task { @MainActor in
            validator.startTransactionListener()
            await validator.updateProStatus()
        }
        
        // Configure TipKit
        Task { @MainActor in
            TipsConfiguration.configure()
        }
    }

    // Task 1.3.2: Use versioned schema for proper migrations
    // Task 10.1.1: CloudKit disabled for v1.0 (local-only storage)
    var sharedModelContainer: ModelContainer = {
        do {
            return try NestoryModelContainer.createForProduction()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appEnv)
                .onAppear {
                    seedDefaultDataIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func seedDefaultDataIfNeeded() {
        let context = sharedModelContainer.mainContext
        
        // Check if categories exist
        let categoryDescriptor = FetchDescriptor<Category>()
        let existingCategories = (try? context.fetch(categoryDescriptor)) ?? []
        
        if existingCategories.isEmpty {
            // Seed default categories
            for (index, cat) in Category.defaultCategories.enumerated() {
                let category = Category(
                    name: cat.name,
                    iconName: cat.icon,
                    colorHex: cat.color,
                    isCustom: false,
                    sortOrder: index
                )
                context.insert(category)
            }
        }
        
        // Check if rooms exist
        let roomDescriptor = FetchDescriptor<Room>()
        let existingRooms = (try? context.fetch(roomDescriptor)) ?? []
        
        if existingRooms.isEmpty {
            // Seed default rooms
            for (index, room) in Room.defaultRooms.enumerated() {
                let newRoom = Room(
                    name: room.name,
                    iconName: room.icon,
                    sortOrder: index,
                    isDefault: true  // Mark as system-provided so users can't delete
                )
                context.insert(newRoom)
            }
        }
        
        try? context.save()
    }
}

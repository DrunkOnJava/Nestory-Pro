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
// CURRENT STATE (Needs Refactoring - See TODO.md Phase 5):
// - SettingsManager.shared and IAPValidator.shared are SINGLETONS
// - These should be replaced with AppEnvironment DI (Task 5.2.1)
// - DO NOT add more singletons - this pattern is being phased out
//
// WHEN ADDING NEW SERVICES:
// 1. Create the service conforming to its protocol
// 2. Add to future AppEnvironment container (not as singleton)
// 3. Inject via @Environment, not .shared
//
// SEEDING BEHAVIOR:
// - Default categories and rooms are seeded on first launch
// - When adding Room.isDefault (Task 1.1.3), update seeding here
//
// SEE: TODO.md for task details | CLAUDE.md for development guidelines
// ============================================================================

import SwiftUI
import SwiftData

@main
struct Nestory_ProApp: App {
    let settings = SettingsManager.shared
    let iapValidator = IAPValidator.shared

    init() {
        // Migrate Pro status from UserDefaults to Keychain (one-time migration)
        KeychainManager.migrateProStatusFromUserDefaults()

        // Start listening for IAP transactions
        let validator = iapValidator
        Task { @MainActor in
            validator.startTransactionListener()
            await validator.updateProStatus()
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            ItemPhoto.self,
            Receipt.self,
            Category.self,
            Room.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(settings.themePreference.colorScheme)
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

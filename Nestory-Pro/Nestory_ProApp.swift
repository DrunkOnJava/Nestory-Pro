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
                .sheet(isPresented: .init(
                    get: { !appEnv.settings.hasCompletedOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView()
                        .environment(appEnv)
                        .interactiveDismissDisabled()
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

        #if DEBUG
        // Seed sample items for development/testing
        seedDebugItemsIfNeeded(context: context)
        #endif
    }

    #if DEBUG
    /// Seeds sample items for development/testing. Only runs on DEBUG builds.
    /// Provides realistic inventory data to test all features:
    /// - Reports (Full Inventory, Loss List)
    /// - Warranty tracking
    /// - Search and filtering
    /// - Value calculations
    private func seedDebugItemsIfNeeded(context: ModelContext) {
        // Check if items already exist
        let itemDescriptor = FetchDescriptor<Item>()
        let existingItems = (try? context.fetch(itemDescriptor)) ?? []

        guard existingItems.isEmpty else { return }

        // Fetch seeded categories and rooms
        let categoryDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        let roomDescriptor = FetchDescriptor<Room>(sortBy: [SortDescriptor(\.sortOrder)])

        let categories = (try? context.fetch(categoryDescriptor)) ?? []
        let rooms = (try? context.fetch(roomDescriptor)) ?? []

        guard !categories.isEmpty, !rooms.isEmpty else { return }

        // Helper to find category/room by name
        func category(_ name: String) -> Category? {
            categories.first { $0.name.lowercased().contains(name.lowercased()) }
        }
        func room(_ name: String) -> Room? {
            rooms.first { $0.name.lowercased().contains(name.lowercased()) }
        }

        // Calendar for date calculations
        let calendar = Calendar.current
        let now = Date()

        // Sample items with varied properties
        let sampleItems: [(
            name: String,
            brand: String?,
            price: Decimal,
            categoryName: String,
            roomName: String,
            condition: ItemCondition,
            warrantyDays: Int?, // Days from now (negative = expired)
            tags: [String]
        )] = [
            // Living Room - Electronics
            ("65\" OLED Smart TV", "LG", 1899.99, "Electronics", "Living Room", .new, 365, ["insured", "high-value"]),
            ("Soundbar System", "Sonos", 799.99, "Electronics", "Living Room", .likeNew, 180, ["insured"]),
            ("Apple TV 4K", "Apple", 179.99, "Electronics", "Living Room", .good, 90, []),

            // Living Room - Furniture
            ("Sectional Sofa", "West Elm", 3499.99, "Furniture", "Living Room", .good, nil, ["insured", "high-value"]),
            ("Coffee Table", "IKEA", 249.99, "Furniture", "Living Room", .good, nil, []),
            ("Floor Lamp", "Target", 89.99, "Furniture", "Living Room", .fair, nil, []),

            // Kitchen - Appliances
            ("French Door Refrigerator", "Samsung", 2199.99, "Appliances", "Kitchen", .new, 730, ["insured", "high-value"]),
            ("Dishwasher", "Bosch", 849.99, "Appliances", "Kitchen", .good, -30, ["insured"]), // Expired warranty
            ("Stand Mixer", "KitchenAid", 449.99, "Appliances", "Kitchen", .likeNew, 545, []),
            ("Coffee Maker", "Breville", 299.99, "Appliances", "Kitchen", .good, 15, []), // Expiring soon
            ("Microwave", "Panasonic", 179.99, "Appliances", "Kitchen", .fair, -90, []), // Expired

            // Bedroom - Furniture
            ("King Bed Frame", "Article", 1299.99, "Furniture", "Bedroom", .new, nil, ["insured"]),
            ("Mattress", "Casper", 1099.99, "Furniture", "Bedroom", .good, 3650, ["insured"]), // 10-year warranty
            ("Nightstand Set", "West Elm", 598.99, "Furniture", "Bedroom", .good, nil, []),
            ("Dresser", "IKEA", 349.99, "Furniture", "Bedroom", .fair, nil, []),

            // Office - Electronics
            ("MacBook Pro 16\"", "Apple", 2499.99, "Electronics", "Office", .new, 365, ["insured", "high-value", "work"]),
            ("27\" Monitor", "Dell", 449.99, "Electronics", "Office", .good, 60, ["work"]),
            ("Mechanical Keyboard", "Keychron", 99.99, "Electronics", "Office", .new, 365, []),
            ("Desk Chair", "Herman Miller", 1499.99, "Furniture", "Office", .likeNew, 4380, ["insured", "high-value"]), // 12-year warranty
            ("Standing Desk", "Uplift", 799.99, "Furniture", "Office", .good, 25, ["work"]), // Expiring soon

            // Garage - Tools
            ("Power Drill Set", "DeWalt", 299.99, "Tools", "Garage", .good, 180, []),
            ("Circular Saw", "Makita", 199.99, "Tools", "Garage", .fair, -180, []), // Expired warranty
            ("Tool Chest", "Craftsman", 449.99, "Tools", "Garage", .good, nil, []),
            ("Lawn Mower", "Honda", 699.99, "Outdoor", "Garage", .good, 730, ["insured"]),

            // Bathroom
            ("Dyson Hair Dryer", "Dyson", 429.99, "Appliances", "Bathroom", .new, 730, []),

            // Outdoor
            ("Patio Furniture Set", "Pottery Barn", 1899.99, "Furniture", "Outdoor", .good, nil, ["insured"]),
            ("Gas Grill", "Weber", 799.99, "Outdoor", "Outdoor", .likeNew, 365, []),
        ]

        for item in sampleItems {
            let newItem = Item(
                name: item.name,
                brand: item.brand,
                purchasePrice: item.price,
                purchaseDate: calendar.date(byAdding: .month, value: -Int.random(in: 1...24), to: now),
                category: category(item.categoryName),
                room: room(item.roomName),
                condition: item.condition,
                warrantyExpiryDate: item.warrantyDays.map { calendar.date(byAdding: .day, value: $0, to: now) } ?? nil,
                tags: item.tags
            )
            context.insert(newItem)
        }

        try? context.save()
        print("[DEBUG] Seeded \(sampleItems.count) sample items for testing")
    }
    #endif
}

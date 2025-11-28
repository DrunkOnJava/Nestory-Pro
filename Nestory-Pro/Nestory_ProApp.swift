//
//  Nestory_ProApp.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import SwiftData

@main
struct Nestory_ProApp: App {
    let settings = SettingsManager.shared
    
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
                    sortOrder: index
                )
                context.insert(newRoom)
            }
        }
        
        try? context.save()
    }
}

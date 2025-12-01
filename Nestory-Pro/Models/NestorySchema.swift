//
//  NestorySchema.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: SWIFTDATA VERSIONED SCHEMA
// ============================================================================
// Task 1.3.2: VersionedSchema scaffolding for future migrations
// Task P2-02: Added V1_2 schema with Property and Container models
//
// VERSIONED SCHEMA APPROACH:
// - V1 (1.0.0): Original release - Item, ItemPhoto, Receipt, Category, Room, Tag
// - V1_2 (1.2.0): Information Architecture - adds Property, Container
//
// MIGRATION STRATEGY:
// - V1 → V1_2: Custom migration to add new models and optional relationships
// - New relationships are optional (nil by default) for backward compatibility
//
// BEST PRACTICES:
// - Never modify a shipped schema version
// - Create new schema version for any model changes
// - Use custom migration for complex changes
// - Test migrations with production-like data before release
//
// SEE: TODO.md Task 1.3.2, P2-02 | Apple's SwiftData migration docs
// ============================================================================

import Foundation
import Combine
import SwiftData

// MARK: - Schema V1 (v1.0 Release) - FROZEN

/// Schema version 1.0.0 - Initial release schema (FROZEN - DO NOT MODIFY)
/// This schema represents the v1.0 shipped version.
/// Models: Item, ItemPhoto, Receipt, Category, Room, Tag
enum NestorySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Item.self,
            ItemPhoto.self,
            Receipt.self,
            Category.self,
            Room.self,
            Tag.self
        ]
    }
}

// MARK: - Schema V1.2 (P2-02: Information Architecture)

/// Schema version 1.2.0 - Information Architecture
/// Adds: Property, Container models
/// Updates: Room gains optional `property` relationship
///          Item gains optional `container` relationship
/// All new relationships are optional for backward compatibility
enum NestorySchemaV1_2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 2, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Item.self,
            ItemPhoto.self,
            Receipt.self,
            Category.self,
            Room.self,
            Tag.self,
            Property.self,
            Container.self
        ]
    }
}

// MARK: - Migration Plan

/// Migration plan for Nestory Pro schema versions
/// Handles upgrades from any previous version to the current version
enum NestoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            NestorySchemaV1.self,
            NestorySchemaV1_2.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            migrateV1toV1_2
        ]
    }

    // MARK: - Migration V1 → V1.2
    
    /// Custom migration from v1.0 to v1.2
    /// - Adds Property and Container tables
    /// - Existing Room.property and Item.container remain nil (optional)
    /// - No data transformation needed since new relationships are optional
    static let migrateV1toV1_2 = MigrationStage.custom(
        fromVersion: NestorySchemaV1.self,
        toVersion: NestorySchemaV1_2.self,
        willMigrate: { context in
            // Pre-migration: Nothing needed
            // New tables (Property, Container) will be created automatically
            // Existing data remains unchanged
        },
        didMigrate: { context in
            // Post-migration: Optionally create a default property
            // This runs after the schema has been updated
            
            // Check if any properties exist
            let propertyDescriptor = FetchDescriptor<Property>()
            let existingProperties = try? context.fetch(propertyDescriptor)
            
            // If no properties exist and there are rooms, create a default property
            if existingProperties?.isEmpty ?? true {
                let roomDescriptor = FetchDescriptor<Room>()
                let existingRooms = try? context.fetch(roomDescriptor)
                
                if let rooms = existingRooms, !rooms.isEmpty {
                    // Create default property and assign existing rooms to it
                    let defaultProperty = Property(
                        name: "My Home",
                        iconName: "house.fill",
                        colorHex: "#007AFF",
                        sortOrder: 0,
                        isDefault: true
                    )
                    context.insert(defaultProperty)
                    
                    // Link existing rooms to the default property
                    for room in rooms {
                        room.property = defaultProperty
                    }
                    
                    try? context.save()
                }
            }
        }
    )
}

// MARK: - Schema Factory

/// Factory for creating ModelContainer with proper schema versioning
@MainActor
enum NestoryModelContainer {

    /// Creates the production ModelContainer with versioned schema
    /// - Parameters:
    ///   - inMemory: Whether to use in-memory storage (for testing)
    ///   - cloudKit: Whether to enable CloudKit sync
    /// - Returns: Configured ModelContainer
    static func create(
        inMemory: Bool = false,
        cloudKit: Bool = false
    ) throws -> ModelContainer {
        // Use the latest schema version
        let schema = Schema(versionedSchema: NestorySchemaV1_2.self)

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: cloudKit ? .automatic : .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: NestoryMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// Creates an in-memory container for testing
    static func createForTesting() throws -> ModelContainer {
        try create(inMemory: true, cloudKit: false)
    }

    /// Creates the production container
    /// CloudKit disabled per Task 10.1.1 decision
    static func createForProduction() throws -> ModelContainer {
        try create(inMemory: false, cloudKit: false)
    }
}

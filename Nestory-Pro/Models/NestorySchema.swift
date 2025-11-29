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
//
// USAGE:
// - ModelContainer uses NestorySchemaV1 for v1.0
// - When adding schema changes in v1.1, create NestorySchemaV1_1
// - Add migration stages to NestoryMigrationPlan
//
// MIGRATION RULES:
// - Never remove properties without migration
// - Add new optional properties with defaults
// - Use lightweight migration when possible
//
// SEE: TODO.md Task 1.3.2 | Apple's SwiftData migration docs
// ============================================================================

import Foundation
import SwiftData

// MARK: - Schema V1 (v1.0 Release)

/// Schema version 1.0 - Initial release schema
/// Contains: Item, ItemPhoto, Receipt, Category, Room
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
            Room.self
        ]
    }
}

// MARK: - Migration Plan

/// Migration plan for Nestory Pro schema versions
/// Add new migration stages as schema evolves
enum NestoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            NestorySchemaV1.self
            // Future: NestorySchemaV1_1.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            // Future migrations go here
            // migrateV1toV1_1
        ]
    }

    // MARK: - Future Migration Stages (Placeholder)

    // Example migration stage for v1.1:
    // static let migrateV1toV1_1 = MigrationStage.lightweight(
    //     fromVersion: NestorySchemaV1.self,
    //     toVersion: NestorySchemaV1_1.self
    // )
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
        let schema = Schema(versionedSchema: NestorySchemaV1.self)

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

    /// Creates the production container for v1.0
    /// CloudKit disabled per Task 10.1.1 decision
    static func createForProduction() throws -> ModelContainer {
        try create(inMemory: false, cloudKit: false)
    }
}

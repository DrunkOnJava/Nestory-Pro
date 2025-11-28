//
//  SchemaVersioning.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: SCHEMA VERSIONING
// ============================================================================
// This file handles SwiftData schema migrations.
//
// WHEN TO UPDATE:
// - Adding new properties to @Model classes
// - Removing properties from @Model classes
// - Changing property types
// - Adding new @Model classes
//
// HOW TO ADD A NEW VERSION:
// 1. Create a new SchemaVX enum with static typeAliases for ALL models
// 2. Add a new VersionedSchema conformance
// 3. Update SchemaMigrationPlan.stages with migration
// 4. Update currentSchema in Nestory_ProApp.swift
//
// SEE: https://developer.apple.com/documentation/swiftdata/migratingyourappsdatamodel
// ============================================================================

import Foundation
import SwiftData

// MARK: - Schema Version 1 (Initial Release)
// Original schema before any migrations

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, ItemPhoto.self, Receipt.self, Category.self, Room.self]
    }
}

// MARK: - Schema Version 2 (November 2025)
// Added: Item.notes, ItemPhoto.sortOrder, ItemPhoto.isPrimary, Room.isDefault

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, ItemPhoto.self, Receipt.self, Category.self, Room.self]
    }
}

// MARK: - Migration Plan

enum NestoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // Lightweight migration from V1 to V2
    // New optional properties with defaults don't require custom migration
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}

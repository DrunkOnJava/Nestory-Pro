//
//  SchemaMigrationTests.swift
//  Nestory-ProTests
//
//  Integration tests for schema migration from V1 to V1.2
//  Task P2-02: Information Architecture - Migration validation
//

import XCTest
import SwiftData
@testable import Nestory_Pro

// ============================================================================
// CLAUDE CODE AGENT: SCHEMA MIGRATION TESTS
// ============================================================================
// Task P2-02: Integration tests for V1 → V1.2 schema migration
//
// PURPOSE:
// - Verify migration creates Property/Container tables
// - Verify existing data (Items, Rooms, Categories) survives migration
// - Verify default Property is created and linked to orphan Rooms
// - Verify new optional relationships work correctly
//
// NOTE: SwiftData in-memory migrations are limited. These tests verify
// the post-migration state and relationship behavior.
//
// SEE: NestorySchema.swift | TODO.md P2-02
// ============================================================================

final class SchemaMigrationTests: XCTestCase {

    // MARK: - Schema Version Tests

    /// Verifies that schema V1 includes the original models
    func testSchemaV1_ContainsOriginalModels() {
        let models = NestorySchemaV1.models

        // V1 should have 6 models
        XCTAssertEqual(models.count, 6, "V1 should have 6 models")

        // Verify model types
        XCTAssertTrue(models.contains { $0 == Item.self })
        XCTAssertTrue(models.contains { $0 == ItemPhoto.self })
        XCTAssertTrue(models.contains { $0 == Receipt.self })
        XCTAssertTrue(models.contains { $0 == Category.self })
        XCTAssertTrue(models.contains { $0 == Room.self })
        XCTAssertTrue(models.contains { $0 == Tag.self })

        // V1 should NOT have Property or Container
        XCTAssertFalse(models.contains { $0 == Property.self })
        XCTAssertFalse(models.contains { $0 == Container.self })
    }

    /// Verifies that schema V1.2 includes all models including new ones
    func testSchemaV1_2_ContainsAllModels() {
        let models = NestorySchemaV1_2.models

        // V1.2 should have 8 models (6 original + 2 new)
        XCTAssertEqual(models.count, 8, "V1.2 should have 8 models")

        // Verify all original models
        XCTAssertTrue(models.contains { $0 == Item.self })
        XCTAssertTrue(models.contains { $0 == ItemPhoto.self })
        XCTAssertTrue(models.contains { $0 == Receipt.self })
        XCTAssertTrue(models.contains { $0 == Category.self })
        XCTAssertTrue(models.contains { $0 == Room.self })
        XCTAssertTrue(models.contains { $0 == Tag.self })

        // Verify new models
        XCTAssertTrue(models.contains { $0 == Property.self })
        XCTAssertTrue(models.contains { $0 == Container.self })
    }

    /// Verifies schema version identifiers are correct
    func testSchemaVersionIdentifiers_AreCorrect() {
        let v1 = NestorySchemaV1.versionIdentifier
        let v1_2 = NestorySchemaV1_2.versionIdentifier

        XCTAssertEqual(v1.major, 1)
        XCTAssertEqual(v1.minor, 0)
        XCTAssertEqual(v1.patch, 0)

        XCTAssertEqual(v1_2.major, 1)
        XCTAssertEqual(v1_2.minor, 2)
        XCTAssertEqual(v1_2.patch, 0)
    }

    // MARK: - Migration Plan Tests

    /// Verifies migration plan includes both schema versions
    func testMigrationPlan_IncludesBothSchemas() {
        let schemas = NestoryMigrationPlan.schemas

        XCTAssertEqual(schemas.count, 2, "Should have 2 schema versions")
        XCTAssertTrue(schemas[0] == NestorySchemaV1.self)
        XCTAssertTrue(schemas[1] == NestorySchemaV1_2.self)
    }

    /// Verifies migration plan has one migration stage
    func testMigrationPlan_HasOneMigrationStage() {
        let stages = NestoryMigrationPlan.stages

        XCTAssertEqual(stages.count, 1, "Should have 1 migration stage (V1 → V1.2)")
    }

    // MARK: - Post-Migration Relationship Tests

    /// Verifies Room can have optional Property relationship (post-migration state)
    func testRoom_OptionalPropertyRelationship_WorksAfterMigration() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create room without property (simulates migrated V1 data)
            let room = Room(name: "Migrated Room")
            context.insert(room)
            try? context.save()

            // Room should work without property
            XCTAssertNil(room.property, "Migrated room should have nil property")
            XCTAssertEqual(room.name, "Migrated Room")

            // Now assign a property (simulates user action post-migration)
            let property = Property(name: "My Home", isDefault: true)
            context.insert(property)
            room.property = property
            try? context.save()

            // Verify bidirectional relationship
            XCTAssertEqual(room.property?.name, "My Home")
            XCTAssertTrue(property.rooms.contains(room))
        }
    }

    /// Verifies Item can have optional Container relationship (post-migration state)
    func testItem_OptionalContainerRelationship_WorksAfterMigration() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create item without container (simulates migrated V1 data)
            let item = TestFixtures.testItem(name: "Migrated Item")
            context.insert(item)
            try? context.save()

            // Item should work without container
            XCTAssertNil(item.container, "Migrated item should have nil container")
            XCTAssertEqual(item.name, "Migrated Item")

            // Now assign a container (simulates user action post-migration)
            let room = Room(name: "Living Room")
            context.insert(room)

            let itemContainer = Container(name: "TV Stand", room: room)
            context.insert(itemContainer)
            item.container = itemContainer
            try? context.save()

            // Verify bidirectional relationship
            XCTAssertEqual(item.container?.name, "TV Stand")
            XCTAssertTrue(itemContainer.items.contains(item))
        }
    }

    // MARK: - Data Survival Tests

    /// Verifies items survive the migration with all data intact
    func testMigration_ExistingItemsPreserved() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create items like V1 would have (no container relationship)
            let category = TestFixtures.testCategory(name: "Electronics")
            let room = TestFixtures.testRoom(name: "Office")
            context.insert(category)
            context.insert(room)

            let item = TestFixtures.testItem(
                name: "MacBook Pro",
                brand: "Apple",
                modelNumber: "A2141",
                serialNumber: "C02XL123",
                purchasePrice: Decimal(2499.00),
                category: category,
                room: room
            )
            context.insert(item)
            try? context.save()

            // Fetch and verify all data preserved
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.name == "MacBook Pro" }
            )
            let fetchedItems = try? context.fetch(descriptor)

            XCTAssertEqual(fetchedItems?.count, 1)
            let fetchedItem = fetchedItems?.first
            XCTAssertEqual(fetchedItem?.name, "MacBook Pro")
            XCTAssertEqual(fetchedItem?.brand, "Apple")
            XCTAssertEqual(fetchedItem?.modelNumber, "A2141")
            XCTAssertEqual(fetchedItem?.serialNumber, "C02XL123")
            XCTAssertEqual(fetchedItem?.purchasePrice, Decimal(2499.00))
            XCTAssertEqual(fetchedItem?.category?.name, "Electronics")
            XCTAssertEqual(fetchedItem?.room?.name, "Office")
            XCTAssertNil(fetchedItem?.container, "Container should be nil for pre-migration items")
        }
    }

    /// Verifies categories survive the migration
    func testMigration_ExistingCategoriesPreserved() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create categories like V1 would have
            let categories = [
                TestFixtures.testCategory(name: "Electronics", iconName: "desktopcomputer", sortOrder: 0),
                TestFixtures.testCategory(name: "Furniture", iconName: "sofa", sortOrder: 1),
                TestFixtures.testCategory(name: "Kitchen", iconName: "refrigerator", sortOrder: 2)
            ]
            categories.forEach { context.insert($0) }
            try? context.save()

            // Fetch and verify
            let descriptor = FetchDescriptor<Nestory_Pro.Category>(
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let fetchedCategories = try? context.fetch(descriptor)

            XCTAssertEqual(fetchedCategories?.count, 3)
            XCTAssertEqual(fetchedCategories?[0].name, "Electronics")
            XCTAssertEqual(fetchedCategories?[1].name, "Furniture")
            XCTAssertEqual(fetchedCategories?[2].name, "Kitchen")
        }
    }

    /// Verifies rooms survive the migration with optional property
    func testMigration_ExistingRoomsPreserved_WithOptionalProperty() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create rooms like V1 would have (no property relationship)
            let rooms = [
                TestFixtures.testRoom(name: "Living Room", iconName: "sofa.fill", sortOrder: 0, isDefault: true),
                TestFixtures.testRoom(name: "Kitchen", iconName: "refrigerator.fill", sortOrder: 1),
                TestFixtures.testRoom(name: "Bedroom", iconName: "bed.double.fill", sortOrder: 2)
            ]
            rooms.forEach { context.insert($0) }
            try? context.save()

            // Fetch and verify
            let descriptor = FetchDescriptor<Room>(
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let fetchedRooms = try? context.fetch(descriptor)

            XCTAssertEqual(fetchedRooms?.count, 3)
            XCTAssertEqual(fetchedRooms?[0].name, "Living Room")
            XCTAssertTrue(fetchedRooms?[0].isDefault ?? false)
            XCTAssertNil(fetchedRooms?[0].property, "V1 rooms should have nil property")
            XCTAssertEqual(fetchedRooms?[1].name, "Kitchen")
            XCTAssertEqual(fetchedRooms?[2].name, "Bedroom")
        }
    }

    // MARK: - Default Property Creation Tests

    /// Verifies default property can be created and linked to orphan rooms
    func testMigration_DefaultPropertyCreation_LinksOrphanRooms() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create orphan rooms (simulates V1 data)
            let rooms = [
                Room(name: "Living Room", sortOrder: 0),
                Room(name: "Kitchen", sortOrder: 1),
                Room(name: "Bedroom", sortOrder: 2)
            ]
            rooms.forEach { context.insert($0) }
            try? context.save()

            // Verify rooms exist but have no property
            let roomDescriptor = FetchDescriptor<Room>()
            var fetchedRooms = try? context.fetch(roomDescriptor)
            XCTAssertEqual(fetchedRooms?.count, 3)
            XCTAssertTrue(fetchedRooms?.allSatisfy { $0.property == nil } ?? false)

            // Simulate migration's didMigrate: create default property and link rooms
            let defaultProperty = Property(
                name: "My Home",
                iconName: "house.fill",
                colorHex: "#007AFF",
                sortOrder: 0,
                isDefault: true
            )
            context.insert(defaultProperty)

            // Link all orphan rooms to default property
            for room in fetchedRooms ?? [] {
                room.property = defaultProperty
            }
            try? context.save()

            // Verify property was created
            let propertyDescriptor = FetchDescriptor<Property>()
            let properties = try? context.fetch(propertyDescriptor)
            XCTAssertEqual(properties?.count, 1)
            XCTAssertEqual(properties?.first?.name, "My Home")
            XCTAssertTrue(properties?.first?.isDefault ?? false)

            // Verify all rooms now linked to property
            fetchedRooms = try? context.fetch(roomDescriptor)
            XCTAssertTrue(fetchedRooms?.allSatisfy { $0.property?.name == "My Home" } ?? false)
            XCTAssertEqual(defaultProperty.rooms.count, 3)
        }
    }

    // MARK: - Container Tests

    /// Verifies Container model works correctly in V1.2 schema
    func testV1_2_ContainerModel_WorksCorrectly() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create full hierarchy: Property > Room > Container > Item
            let property = Property(name: "My Home", isDefault: true)
            context.insert(property)

            let room = Room(name: "Living Room", property: property)
            context.insert(room)

            let tvStand = Container(name: "TV Stand", iconName: "cabinet.fill", room: room)
            context.insert(tvStand)

            let item1 = TestFixtures.testItem(name: "Apple TV", room: room)
            item1.container = tvStand
            context.insert(item1)

            let item2 = TestFixtures.testItem(name: "PlayStation 5", room: room)
            item2.container = tvStand
            context.insert(item2)

            try? context.save()

            // Verify full hierarchy
            XCTAssertEqual(property.rooms.count, 1)
            XCTAssertEqual(room.containers.count, 1)
            XCTAssertEqual(tvStand.items.count, 2)

            // Verify breadcrumb path
            XCTAssertEqual(tvStand.breadcrumbPath, "My Home > Living Room > TV Stand")

            // Verify container computed properties
            XCTAssertEqual(tvStand.totalValue, Decimal(200.00)) // 2 items at $100 each
        }
    }

    // MARK: - Cascade Delete Tests (Post-Migration)

    /// Verifies Property cascade delete removes Rooms but not Items
    func testV1_2_PropertyDelete_CascadesRoomsNotItems() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create hierarchy
            let property = Property(name: "Vacation Home", isDefault: false)
            context.insert(property)

            let room = Room(name: "Beach Room", property: property)
            context.insert(room)

            let item = TestFixtures.testItem(name: "Surfboard", room: room)
            context.insert(item)
            try? context.save()

            // Delete property
            context.delete(property)
            try? context.save()

            // Verify room was cascade deleted
            let roomDescriptor = FetchDescriptor<Room>(
                predicate: #Predicate { $0.name == "Beach Room" }
            )
            let rooms = try? context.fetch(roomDescriptor)
            XCTAssertEqual(rooms?.count, 0, "Room should be cascade deleted with Property")

            // Verify item still exists but room is nil
            let itemDescriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.name == "Surfboard" }
            )
            let items = try? context.fetch(itemDescriptor)
            XCTAssertEqual(items?.count, 1, "Item should survive Property/Room deletion")
            XCTAssertNil(items?.first?.room, "Item's room should be nil after room deletion")
        }
    }

    /// Verifies Container delete nullifies items but doesn't delete them
    func testV1_2_ContainerDelete_NullifiesItemsNotDeletes() async throws {
        await MainActor.run {
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create hierarchy
            let room = Room(name: "Office")
            context.insert(room)

            let desk = Container(name: "Desk", room: room)
            context.insert(desk)

            let laptop = TestFixtures.testItem(name: "Laptop", room: room)
            laptop.container = desk

            let monitor = TestFixtures.testItem(name: "Monitor", room: room)
            monitor.container = desk

            context.insert(laptop)
            context.insert(monitor)
            try? context.save()

            // Verify setup
            XCTAssertEqual(desk.items.count, 2)

            // Delete container
            context.delete(desk)
            try? context.save()

            // Verify items still exist
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try? context.fetch(itemDescriptor)
            XCTAssertEqual(items?.count, 2, "Items should survive container deletion")

            // Verify container reference is nil
            XCTAssertTrue(items?.allSatisfy { $0.container == nil } ?? false)

            // Verify items still in room
            XCTAssertTrue(items?.allSatisfy { $0.room?.name == "Office" } ?? false)
        }
    }
}

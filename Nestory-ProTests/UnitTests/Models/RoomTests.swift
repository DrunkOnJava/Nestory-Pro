//
//  RoomTests.swift
//  Nestory-ProTests
//
//  Unit tests for Room model
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class RoomTests: XCTestCase {

    // MARK: - Test Tags

    override var tags: Set<TestTag> {
        [.fast, .unit, .model]
    }

    // MARK: - Initialization Tests

    func testRoom_InitWithAllFields_SetsCorrectly() async {
        await MainActor.run {
            // Arrange & Act
            let room = Room(
                name: "Living Room",
                iconName: "sofa",
                sortOrder: 0
            )

            // Assert
            XCTAssertEqual(room.name, "Living Room")
            XCTAssertEqual(room.iconName, "sofa")
            XCTAssertEqual(room.sortOrder, 0)
            XCTAssertNotNil(room.id)
            XCTAssertTrue(room.items.isEmpty)
        }
    }

    // MARK: - Default Rooms Tests

    func testRoom_DefaultRooms_ExistAndAreValid() async {
        await MainActor.run {
            // Arrange & Act
            let defaults = Room.defaultRooms

            // Assert
            XCTAssertGreaterThan(defaults.count, 0, "Should have default rooms")

            for defaultRoom in defaults {
                XCTAssertFalse(defaultRoom.name.isEmpty, "Room name should not be empty")
                XCTAssertFalse(defaultRoom.icon.isEmpty, "Room icon should not be empty")
            }
        }
    }

    func testRoom_DefaultRooms_HaveUniqueNames() async {
        await MainActor.run {
            // Arrange
            let defaults = Room.defaultRooms
            let names = defaults.map { $0.name }

            // Act
            let uniqueNames = Set(names)

            // Assert
            XCTAssertEqual(names.count, uniqueNames.count, "Default room names should be unique")
        }
    }

    func testRoom_DefaultRooms_IncludeCommonRooms() async {
        await MainActor.run {
            // Arrange
            let defaults = Room.defaultRooms
            let names = defaults.map { $0.name }

            // Assert - At minimum should have these common rooms
            let expectedRooms = ["Living Room", "Bedroom", "Kitchen"]
            for expectedRoom in expectedRooms {
                XCTAssertTrue(
                    names.contains { $0.lowercased().contains(expectedRoom.lowercased()) },
                    "Should have a room like '\(expectedRoom)'"
                )
            }
        }
    }

    // MARK: - Icon Name Tests

    func testRoom_SFSymbolIconNames_AreAccepted() async {
        await MainActor.run {
            // Arrange
            let iconNames = ["sofa", "bed.double", "fork.knife", "shower", "car.fill"]

            for iconName in iconNames {
                // Act
                let room = Room(
                    name: "Icon Test Room",
                    iconName: iconName,
                    sortOrder: 0
                )

                // Assert
                XCTAssertEqual(room.iconName, iconName)
            }
        }
    }

    // MARK: - Relationship Tests

    func testRoom_ItemsRelationship_IsInitiallyEmpty() async {
        await MainActor.run {
            // Arrange & Act
            let room = TestFixtures.testRoom()

            // Assert
            XCTAssertTrue(room.items.isEmpty)
        }
    }

    func testRoom_AddItem_UpdatesItemsArray() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let room = TestFixtures.testRoom()
            context.insert(room)

            let item = TestFixtures.testItem(room: room)
            context.insert(item)

            try context.save()

            // Assert
            XCTAssertEqual(room.items.count, 1)
            XCTAssertTrue(room.items.contains(item))
        }
    }

    func testRoom_MultipleItems_AllLinked() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let room = TestFixtures.testRoom()
            context.insert(room)

            let items = (0..<5).map { i in
                TestFixtures.testItem(name: "Item \(i)", room: room)
            }
            items.forEach { context.insert($0) }

            try context.save()

            // Assert
            XCTAssertEqual(room.items.count, 5)
            for item in items {
                XCTAssertTrue(room.items.contains(item))
            }
        }
    }

    func testRoom_RemoveItem_UpdatesItemsArray() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let room = TestFixtures.testRoom()
            context.insert(room)

            let item = TestFixtures.testItem(room: room)
            context.insert(item)

            try context.save()

            XCTAssertEqual(room.items.count, 1)

            // Act - Remove item from room
            item.room = nil
            try context.save()

            // Assert
            XCTAssertTrue(room.items.isEmpty)
        }
    }

    // MARK: - Sort Order Tests

    func testRoom_SortOrder_CanBeNegative() async {
        await MainActor.run {
            // Arrange & Act
            let room = Room(
                name: "Negative Sort Room",
                iconName: "house",
                sortOrder: -5
            )

            // Assert
            XCTAssertEqual(room.sortOrder, -5)
        }
    }

    func testRoom_SortOrder_CanBeVeryLarge() async {
        await MainActor.run {
            // Arrange & Act
            let room = Room(
                name: "Large Sort Room",
                iconName: "house",
                sortOrder: Int.max
            )

            // Assert
            XCTAssertEqual(room.sortOrder, Int.max)
        }
    }

    func testRoom_SortOrder_DeterminesDisplayOrder() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let room1 = Room(name: "Third", iconName: "3.circle", sortOrder: 3)
            let room2 = Room(name: "First", iconName: "1.circle", sortOrder: 1)
            let room3 = Room(name: "Second", iconName: "2.circle", sortOrder: 2)

            context.insert(room1)
            context.insert(room2)
            context.insert(room3)

            try context.save()

            // Act
            let descriptor = FetchDescriptor<Room>(
                sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
            )
            let sortedRooms = try context.fetch(descriptor)

            // Assert
            XCTAssertEqual(sortedRooms[0].name, "First")
            XCTAssertEqual(sortedRooms[1].name, "Second")
            XCTAssertEqual(sortedRooms[2].name, "Third")
        }
    }

    // MARK: - Edge Cases

    func testRoom_EmptyName_IsAllowed() async {
        await MainActor.run {
            // Arrange & Act
            let room = Room(
                name: "",
                iconName: "house",
                sortOrder: 0
            )

            // Assert
            XCTAssertEqual(room.name, "")
        }
    }

    func testRoom_VeryLongName_IsAccepted() async {
        await MainActor.run {
            // Arrange
            let longName = String(repeating: "Room ", count: 100)

            // Act
            let room = Room(
                name: longName,
                iconName: "house",
                sortOrder: 0
            )

            // Assert
            XCTAssertEqual(room.name, longName)
        }
    }

    func testRoom_UnicodeInName_IsPreserved() async {
        await MainActor.run {
            // Arrange
            let unicodeName = "主臥室 🛏️"

            // Act
            let room = Room(
                name: unicodeName,
                iconName: "bed.double",
                sortOrder: 0
            )

            // Assert
            XCTAssertEqual(room.name, unicodeName)
        }
    }

    func testRoom_SpecialCharactersInName_ArePreserved() async {
        await MainActor.run {
            // Arrange
            let specialName = "Kid's Room (Guest) — 2nd Floor"

            // Act
            let room = Room(
                name: specialName,
                iconName: "bed.double",
                sortOrder: 0
            )

            // Assert
            XCTAssertEqual(room.name, specialName)
        }
    }

    // MARK: - UUID Tests

    func testRoom_HasUniqueUUID_OnCreation() async {
        await MainActor.run {
            // Arrange & Act
            let room1 = TestFixtures.testRoom(name: "Room 1")
            let room2 = TestFixtures.testRoom(name: "Room 2")

            // Assert
            XCTAssertNotEqual(room1.id, room2.id)
        }
    }

    // MARK: - Persistence Tests

    func testRoom_PersistsCorrectly() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let room = Room(
                name: "Persist Test Room",
                iconName: "archivebox",
                sortOrder: 42
            )
            context.insert(room)
            try context.save()

            // Act
            let descriptor = FetchDescriptor<Room>(
                predicate: #Predicate { $0.name == "Persist Test Room" }
            )
            let fetchedRooms = try context.fetch(descriptor)

            // Assert
            XCTAssertEqual(fetchedRooms.count, 1)
            let fetched = try XCTUnwrap(fetchedRooms.first)
            XCTAssertEqual(fetched.name, "Persist Test Room")
            XCTAssertEqual(fetched.iconName, "archivebox")
            XCTAssertEqual(fetched.sortOrder, 42)
        }
    }
}

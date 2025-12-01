//
//  ContainerModelTests.swift
//  Nestory-ProTests
//
//  Unit tests for Container model
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class ContainerModelTests: XCTestCase {

    // MARK: - Test Tags

    override var tags: Set<TestTag> {
        [.medium, .unit, .model]
    }

    // MARK: - Initialization Tests

    func testContainer_InitWithRequiredFields_SetsCorrectly() async {
        await MainActor.run {
            // Arrange & Act
            let container = Container(name: "Dresser")

            // Assert
            XCTAssertEqual(container.name, "Dresser")
            XCTAssertEqual(container.iconName, "shippingbox.fill")
            XCTAssertEqual(container.colorHex, "#8B5CF6")
            XCTAssertEqual(container.sortOrder, 0)
            XCTAssertNil(container.notes)
            XCTAssertNil(container.room)
            XCTAssertTrue(container.items.isEmpty)
        }
    }

    func testContainer_InitWithAllFields_SetsCorrectly() async {
        await MainActor.run {
            // Arrange
            let room = TestFixtures.testRoom(name: "Bedroom")
            let notes = "IKEA KALLAX, purchased 2023"

            // Act
            let container = Container(
                name: "TV Stand",
                iconName: "rectangle.3.group.fill",
                colorHex: "#007AFF",
                sortOrder: 5,
                notes: notes,
                room: room
            )

            // Assert
            XCTAssertEqual(container.name, "TV Stand")
            XCTAssertEqual(container.iconName, "rectangle.3.group.fill")
            XCTAssertEqual(container.colorHex, "#007AFF")
            XCTAssertEqual(container.sortOrder, 5)
            XCTAssertEqual(container.notes, notes)
            XCTAssertEqual(container.room?.name, "Bedroom")
            XCTAssertTrue(container.items.isEmpty)
        }
    }

    func testContainer_HasUniqueUUID_OnCreation() async {
        await MainActor.run {
            // Arrange & Act
            let container1 = TestFixtures.testContainer(name: "Container 1")
            let container2 = TestFixtures.testContainer(name: "Container 2")

            // Assert
            XCTAssertNotEqual(container1.id, container2.id)
        }
    }

    // MARK: - Validation Tests

    func testContainer_Validate_EmptyName_ThrowsError() async throws {
        try await MainActor.run {
            // Arrange
            let container = Container(
                name: "   ",  // Whitespace only
                iconName: "shippingbox.fill",
                colorHex: "#FF9500"
            )

            // Act & Assert
            XCTAssertThrowsError(try container.validate()) { error in
                guard let validationError = error as? Container.ValidationError else {
                    XCTFail("Expected ValidationError but got \(type(of: error))")
                    return
                }
                XCTAssertEqual(validationError, Container.ValidationError.emptyName)
            }
        }
    }

    func testContainer_Validate_InvalidColorHex_ThrowsError() async throws {
        try await MainActor.run {
            // Arrange - Invalid color formats
            let invalidColors = [
                "#GGGGGG",  // Invalid hex characters
                "red",      // Named color
                "",         // Empty string
                "#FF",      // Too short
                "#FFFFFFF", // Too long
                "FF9500",   // Missing #
                "#XYZ"      // Invalid characters
            ]

            for invalidColor in invalidColors {
                // Act
                let container = Container(
                    name: "Test Container",
                    iconName: "shippingbox.fill",
                    colorHex: invalidColor
                )

                // Assert
                XCTAssertThrowsError(try container.validate()) { error in
                    guard let validationError = error as? Container.ValidationError else {
                        XCTFail("Expected ValidationError for color '\(invalidColor)' but got \(type(of: error))")
                        return
                    }
                    XCTAssertEqual(validationError, Container.ValidationError.invalidColorHex)
                }
            }
        }
    }

    func testContainer_Validate_ValidColorHex_Succeeds() async throws {
        try await MainActor.run {
            // Arrange - Valid color formats
            let validColors = [
                "#00FF00",  // Full hex
                "#0F0",     // Short hex
                "#8B5CF6",  // Purple
                "#FFF",     // White short
                "#000000",  // Black
                "#AbCdEf"   // Mixed case (should be allowed)
            ]

            for validColor in validColors {
                // Act
                let container = Container(
                    name: "Test Container",
                    iconName: "shippingbox.fill",
                    colorHex: validColor
                )

                // Assert
                XCTAssertNoThrow(try container.validate(), "Color '\(validColor)' should be valid")
            }
        }
    }

    // MARK: - Computed Properties Tests

    func testContainer_TotalValue_NoItems_ReturnsZero() async {
        await MainActor.run {
            // Arrange
            let container = TestFixtures.testContainer()

            // Act
            let totalValue = container.totalValue

            // Assert
            XCTAssertEqual(totalValue, Decimal(0))
        }
    }

    func testContainer_TotalValue_WithItems_ReturnsSumOfPrices() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let room = TestFixtures.testRoom()
            context.insert(room)

            let container = TestFixtures.testContainer(room: room)
            context.insert(container)

            // Create items with different prices
            let item1 = TestFixtures.testItem(name: "Item 1", purchasePrice: Decimal(100))
            let item2 = TestFixtures.testItem(name: "Item 2", purchasePrice: Decimal(250))
            let item3 = TestFixtures.testItem(name: "Item 3", purchasePrice: Decimal(75.50))
            let item4 = TestFixtures.testItem(name: "Item 4", purchasePrice: nil) // No price

            item1.container = container
            item2.container = container
            item3.container = container
            item4.container = container

            context.insert(item1)
            context.insert(item2)
            context.insert(item3)
            context.insert(item4)

            try context.save()

            // Act
            let totalValue = container.totalValue

            // Assert
            XCTAssertEqual(totalValue, Decimal(425.50)) // 100 + 250 + 75.50 + 0
        }
    }

    func testContainer_AverageDocumentationScore_NoItems_ReturnsZero() async {
        await MainActor.run {
            // Arrange
            let container = TestFixtures.testContainer()

            // Act
            let avgScore = container.averageDocumentationScore

            // Assert
            XCTAssertEqual(avgScore, 0.0)
        }
    }

    func testContainer_AverageDocumentationScore_WithItems_ReturnsCorrectAverage() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let category = TestFixtures.testCategory()
            let room = TestFixtures.testRoom()
            context.insert(category)
            context.insert(room)

            let container = TestFixtures.testContainer(room: room)
            context.insert(container)

            // Item 1: Photo (30%) + Value (25%) + Category (10%) + Room (15%) = 80%
            let item1 = Item(
                name: "Item 1",
                purchasePrice: Decimal(100),
                category: category,
                room: room,
                condition: .good
            )
            let photo1 = TestFixtures.testItemPhoto()
            photo1.item = item1
            item1.container = container
            context.insert(item1)
            context.insert(photo1)

            // Item 2: Value (25%) + Room (15%) = 40%
            let item2 = Item(
                name: "Item 2",
                purchasePrice: Decimal(200),
                category: nil,
                room: room,
                condition: .good
            )
            item2.container = container
            context.insert(item2)

            try context.save()

            // Act
            let avgScore = container.averageDocumentationScore

            // Assert - Average of 0.8 and 0.4 = 0.6
            XCTAssertEqual(avgScore, 0.6, accuracy: 0.01)
        }
    }

    func testContainer_BreadcrumbPath_NoRoom_ReturnsJustContainerName() async {
        await MainActor.run {
            // Arrange
            let container = TestFixtures.testContainer(name: "Dresser", room: nil)

            // Act
            let breadcrumb = container.breadcrumbPath

            // Assert
            XCTAssertEqual(breadcrumb, "Dresser")
        }
    }

    func testContainer_BreadcrumbPath_WithRoom_ReturnsRoomAndContainer() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let room = TestFixtures.testRoom(name: "Bedroom")
            context.insert(room)

            let container = TestFixtures.testContainer(name: "Dresser", room: room)
            context.insert(container)

            try context.save()

            // Act
            let breadcrumb = container.breadcrumbPath

            // Assert
            XCTAssertEqual(breadcrumb, "Bedroom > Dresser")
        }
    }

    func testContainer_BreadcrumbPath_WithRoomAndProperty_ReturnsFullPath() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let property = Property(
                name: "Main House",
                address: "123 Main St"
            )
            context.insert(property)

            let room = TestFixtures.testRoom(name: "Bedroom")
            room.property = property
            context.insert(room)

            let container = TestFixtures.testContainer(name: "Dresser", room: room)
            context.insert(container)

            try context.save()

            // Act
            let breadcrumb = container.breadcrumbPath

            // Assert
            XCTAssertEqual(breadcrumb, "Main House > Bedroom > Dresser")
        }
    }

    // MARK: - Relationship Tests

    func testContainer_RoomRelationship_IsInitiallyNil() async {
        await MainActor.run {
            // Arrange & Act
            let container = TestFixtures.testContainer()

            // Assert
            XCTAssertNil(container.room)
        }
    }

    func testContainer_ItemsRelationship_IsInitiallyEmpty() async {
        await MainActor.run {
            // Arrange & Act
            let container = TestFixtures.testContainer()

            // Assert
            XCTAssertTrue(container.items.isEmpty)
        }
    }

    func testContainer_AddItem_UpdatesItemsArray() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let room = TestFixtures.testRoom()
            context.insert(room)

            let container = TestFixtures.testContainer(room: room)
            context.insert(container)

            let item = TestFixtures.testItem(room: room)
            item.container = container
            context.insert(item)

            try context.save()

            // Assert
            XCTAssertEqual(container.items.count, 1)
            XCTAssertTrue(container.items.contains(item))
        }
    }

    func testContainer_SetRoom_UpdatesRoomReference() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let room = TestFixtures.testRoom(name: "Living Room")
            context.insert(room)

            let container = TestFixtures.testContainer()
            context.insert(container)

            // Act - Set room on container
            container.room = room
            try context.save()

            // Assert - Check inverse relationship
            XCTAssertEqual(container.room?.name, "Living Room")
            XCTAssertTrue(room.containers.contains(container))
        }
    }

    func testContainer_DeleteContainer_NullifyItems() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let room = TestFixtures.testRoom()
            context.insert(room)

            let container = TestFixtures.testContainer(room: room)
            context.insert(container)

            let item1 = TestFixtures.testItem(name: "Item 1", room: room)
            let item2 = TestFixtures.testItem(name: "Item 2", room: room)
            item1.container = container
            item2.container = container
            context.insert(item1)
            context.insert(item2)

            try context.save()

            XCTAssertEqual(container.items.count, 2)

            // Act - Delete container
            context.delete(container)
            try context.save()

            // Assert - Items should still exist, but container reference is nullified
            let itemsDescriptor = FetchDescriptor<Item>()
            let items = try context.fetch(itemsDescriptor)
            XCTAssertEqual(items.count, 2)
            XCTAssertNil(item1.container)
            XCTAssertNil(item2.container)
        }
    }

    // MARK: - Default Containers Tests

    func testContainer_AvailableIcons_HasExpectedIcons() async {
        await MainActor.run {
            // Arrange
            let icons = Container.availableIcons

            // Assert
            XCTAssertGreaterThan(icons.count, 0, "Should have available icons")
            XCTAssertTrue(icons.contains("shippingbox.fill"))
            XCTAssertTrue(icons.contains("cabinet.fill"))
            XCTAssertTrue(icons.contains("tray.2.fill"))
            XCTAssertTrue(icons.contains("archivebox.fill"))
        }
    }

    func testContainer_AvailableColors_HasExpectedColors() async {
        await MainActor.run {
            // Arrange
            let colors = Container.availableColors

            // Assert
            XCTAssertGreaterThan(colors.count, 0, "Should have available colors")
            XCTAssertTrue(colors.contains("#8B5CF6")) // Purple (default)
            XCTAssertTrue(colors.contains("#007AFF")) // Blue
            XCTAssertTrue(colors.contains("#34C759")) // Green
            XCTAssertTrue(colors.contains("#FF9500")) // Orange

            // Verify all colors are valid hex format
            for color in colors {
                let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                let range = color.range(of: hexPattern, options: .regularExpression)
                XCTAssertNotNil(range, "Color '\(color)' should be valid hex format")
            }
        }
    }

    // MARK: - Edge Cases

    func testContainer_VeryLongName_IsAccepted() async {
        await MainActor.run {
            // Arrange
            let longName = String(repeating: "Container ", count: 100)

            // Act
            let container = Container(
                name: longName,
                iconName: "shippingbox.fill",
                colorHex: "#FF9500"
            )

            // Assert
            XCTAssertEqual(container.name, longName)
        }
    }

    func testContainer_UnicodeInName_IsPreserved() async {
        await MainActor.run {
            // Arrange
            let unicodeName = "收納箱 📦"

            // Act
            let container = Container(
                name: unicodeName,
                iconName: "shippingbox.fill",
                colorHex: "#FF9500"
            )

            // Assert
            XCTAssertEqual(container.name, unicodeName)
        }
    }

    func testContainer_NegativeSortOrder_IsAllowed() async {
        await MainActor.run {
            // Arrange & Act
            let container = Container(
                name: "Negative Sort Container",
                iconName: "shippingbox.fill",
                colorHex: "#FF9500",
                sortOrder: -10
            )

            // Assert
            XCTAssertEqual(container.sortOrder, -10)
        }
    }

    func testContainer_MultipleContainersInRoom_AllLinked() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let room = TestFixtures.testRoom(name: "Garage")
            context.insert(room)

            // Act - Create multiple containers in the same room
            let containers = (0..<5).map { i in
                TestFixtures.testContainer(
                    name: "Container \(i)",
                    room: room
                )
            }
            containers.forEach { context.insert($0) }

            try context.save()

            // Assert
            XCTAssertEqual(room.containers.count, 5)
            for container in containers {
                XCTAssertTrue(room.containers.contains(container))
                XCTAssertEqual(container.room?.name, "Garage")
            }
        }
    }

    // MARK: - Persistence Tests

    func testContainer_PersistsCorrectly() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let container = Container(
                name: "Persist Test Container",
                iconName: "cabinet.fill",
                colorHex: "#34C759",
                sortOrder: 42,
                notes: "Test notes"
            )
            context.insert(container)
            try context.save()

            // Act
            let descriptor = FetchDescriptor<Container>(
                predicate: #Predicate { $0.name == "Persist Test Container" }
            )
            let fetchedContainers = try context.fetch(descriptor)

            // Assert
            XCTAssertEqual(fetchedContainers.count, 1)
            let fetched = try XCTUnwrap(fetchedContainers.first)
            XCTAssertEqual(fetched.name, "Persist Test Container")
            XCTAssertEqual(fetched.iconName, "cabinet.fill")
            XCTAssertEqual(fetched.colorHex, "#34C759")
            XCTAssertEqual(fetched.sortOrder, 42)
            XCTAssertEqual(fetched.notes, "Test notes")
        }
    }

    func testContainer_WithRoom_PersistsRelationship() async throws {
        try await MainActor.run {
            // Arrange
            let testContainer = TestContainer.empty()
            let context = testContainer.mainContext

            let room = TestFixtures.testRoom(name: "Office")
            context.insert(room)

            let container = Container(
                name: "Desk Drawer",
                iconName: "tray.2.fill",
                colorHex: "#007AFF",
                room: room
            )
            context.insert(container)
            try context.save()

            // Act - Fetch container and verify relationship
            let descriptor = FetchDescriptor<Container>(
                predicate: #Predicate { $0.name == "Desk Drawer" }
            )
            let fetchedContainers = try context.fetch(descriptor)

            // Assert
            XCTAssertEqual(fetchedContainers.count, 1)
            let fetched = try XCTUnwrap(fetchedContainers.first)
            XCTAssertEqual(fetched.room?.name, "Office")
            XCTAssertTrue(room.containers.contains(fetched))
        }
    }
}

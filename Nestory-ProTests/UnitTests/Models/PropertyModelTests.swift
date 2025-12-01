//
//  PropertyModelTests.swift
//  Nestory-ProTests
//
//  Unit tests for Property model
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class PropertyModelTests: XCTestCase {

    // MARK: - Test Tags

    override var tags: Set<TestTag> {
        [.medium, .unit, .model, .critical]
    }

    // MARK: - Initialization Tests

    func testProperty_InitWithRequiredFields_SetsCorrectly() async {
        await MainActor.run {
            // Arrange & Act
            let property = Property(name: "Main House")

            // Assert
            XCTAssertEqual(property.name, "Main House")
            XCTAssertNil(property.address)
            XCTAssertEqual(property.iconName, "house.fill") // Default icon
            XCTAssertEqual(property.colorHex, "#007AFF") // Default color
            XCTAssertEqual(property.sortOrder, 0)
            XCTAssertFalse(property.isDefault)
            XCTAssertNil(property.notes)
            XCTAssertTrue(property.rooms.isEmpty)
            XCTAssertNotNil(property.id)
            XCTAssertNotNil(property.createdAt)
            XCTAssertNotNil(property.updatedAt)
        }
    }

    func testProperty_InitWithAllFields_SetsCorrectly() async {
        await MainActor.run {
            // Arrange & Act
            let property = Property(
                name: "Vacation Home",
                address: "123 Beach St, Ocean City, CA 90210",
                iconName: "beach.umbrella.fill",
                colorHex: "#FF9500",
                sortOrder: 1,
                isDefault: true,
                notes: "Policy #ABC123"
            )

            // Assert
            XCTAssertEqual(property.name, "Vacation Home")
            XCTAssertEqual(property.address, "123 Beach St, Ocean City, CA 90210")
            XCTAssertEqual(property.iconName, "beach.umbrella.fill")
            XCTAssertEqual(property.colorHex, "#FF9500")
            XCTAssertEqual(property.sortOrder, 1)
            XCTAssertTrue(property.isDefault)
            XCTAssertEqual(property.notes, "Policy #ABC123")
            XCTAssertTrue(property.rooms.isEmpty)
        }
    }

    func testProperty_HasUniqueUUID_OnCreation() async {
        await MainActor.run {
            // Arrange & Act
            let property1 = TestFixtures.testProperty(name: "Property 1")
            let property2 = TestFixtures.testProperty(name: "Property 2")

            // Assert
            XCTAssertNotEqual(property1.id, property2.id)
        }
    }

    // MARK: - Validation Tests

    func testProperty_Validate_EmptyName_ThrowsError() async throws {
        try await MainActor.run {
            // Arrange
            let property = Property(name: "   ") // Whitespace only

            // Act & Assert
            XCTAssertThrowsError(try property.validate()) { error in
                guard let validationError = error as? Property.ValidationError else {
                    XCTFail("Expected Property.ValidationError")
                    return
                }
                XCTAssertEqual(validationError, .emptyName)
            }
        }
    }

    func testProperty_Validate_InvalidColorHex_ThrowsError() async throws {
        try await MainActor.run {
            // Arrange - Test various invalid formats
            let invalidColors = [
                "#GGGGGG",  // Invalid hex characters
                "blue",     // Named color
                "",         // Empty
                "#12345",   // Wrong length
                "FF0000",   // Missing #
                "#FFFFFFF", // Too long
                "#12"       // Too short
            ]

            for invalidColor in invalidColors {
                let property = Property(
                    name: "Test",
                    colorHex: invalidColor
                )

                // Act & Assert
                XCTAssertThrowsError(try property.validate()) { error in
                    guard let validationError = error as? Property.ValidationError else {
                        XCTFail("Expected Property.ValidationError for color: \(invalidColor)")
                        return
                    }
                    XCTAssertEqual(validationError, .invalidColorHex,
                                   "Failed for color: \(invalidColor)")
                }
            }
        }
    }

    func testProperty_Validate_ValidColorHex_Succeeds() async throws {
        try await MainActor.run {
            // Arrange - Test various valid formats
            let validColors = [
                "#FF0000",  // 6 characters
                "#F00",     // 3 characters shorthand
                "#00ff00",  // Lowercase
                "#ABC",     // Mixed case shorthand
                "#007AFF"   // Default blue
            ]

            for validColor in validColors {
                let property = Property(
                    name: "Test",
                    colorHex: validColor
                )

                // Act & Assert
                XCTAssertNoThrow(try property.validate(),
                                 "Should accept valid color: \(validColor)")
            }
        }
    }

    // MARK: - Computed Properties Tests

    func testProperty_TotalItemCount_NoRooms_ReturnsZero() async {
        await MainActor.run {
            // Arrange
            let property = TestFixtures.testProperty()

            // Act
            let count = property.totalItemCount

            // Assert
            XCTAssertEqual(count, 0)
        }
    }

    func testProperty_TotalItemCount_WithRooms_ReturnsCorrectSum() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let property = TestFixtures.testProperty()
            context.insert(property)

            // Create 2 rooms
            let room1 = TestFixtures.testRoom(name: "Living Room")
            let room2 = TestFixtures.testRoom(name: "Bedroom")
            property.rooms.append(room1)
            property.rooms.append(room2)
            context.insert(room1)
            context.insert(room2)

            // Add 3 items to room1
            for i in 1...3 {
                let item = TestFixtures.testItem(name: "Item \(i)", room: room1)
                context.insert(item)
            }

            // Add 2 items to room2
            for i in 1...2 {
                let item = TestFixtures.testItem(name: "Item \(i)", room: room2)
                context.insert(item)
            }

            try context.save()

            // Act
            let count = property.totalItemCount

            // Assert
            XCTAssertEqual(count, 5, "Should count 3 items in room1 + 2 items in room2")
        }
    }

    func testProperty_TotalValue_NoItems_ReturnsZero() async {
        await MainActor.run {
            // Arrange
            let property = TestFixtures.testProperty()

            // Act
            let totalValue = property.totalValue

            // Assert
            XCTAssertEqual(totalValue, Decimal(0))
        }
    }

    func testProperty_TotalValue_WithItems_ReturnsSumOfPrices() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let property = TestFixtures.testProperty()
            context.insert(property)

            let room = TestFixtures.testRoom()
            property.rooms.append(room)
            context.insert(room)

            // Add items with prices
            let item1 = TestFixtures.testItem(name: "Item 1", purchasePrice: Decimal(100), room: room)
            let item2 = TestFixtures.testItem(name: "Item 2", purchasePrice: Decimal(250.50), room: room)
            let item3 = TestFixtures.testItem(name: "Item 3", purchasePrice: nil, room: room) // No price
            context.insert(item1)
            context.insert(item2)
            context.insert(item3)

            try context.save()

            // Act
            let totalValue = property.totalValue

            // Assert
            XCTAssertEqual(totalValue, Decimal(350.50), "Should sum 100 + 250.50, ignoring nil price")
        }
    }

    func testProperty_AverageDocumentationScore_NoItems_ReturnsZero() async {
        await MainActor.run {
            // Arrange
            let property = TestFixtures.testProperty()

            // Act
            let avgScore = property.averageDocumentationScore

            // Assert
            XCTAssertEqual(avgScore, 0.0)
        }
    }

    func testProperty_AverageDocumentationScore_WithItems_ReturnsCorrectAverage() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let category = TestFixtures.testCategory()
            context.insert(category)

            let property = TestFixtures.testProperty()
            context.insert(property)

            let room = TestFixtures.testRoom()
            property.rooms.append(room)
            context.insert(room)

            // Create items with known documentation scores
            // Item 1: Value (25%) + Category (10%) + Room (15%) = 50%
            let item1 = Item(
                name: "Item 1",
                purchasePrice: Decimal(100),
                category: category,
                room: room,
                condition: .good
            )
            context.insert(item1)

            // Item 2: Fully documented = 100%
            let item2 = TestFixtures.testDocumentedItem(category: category, room: room)
            let receipt = TestFixtures.testReceipt(linkedItem: item2)
            context.insert(item2)
            context.insert(receipt)

            try context.save()

            // Act
            let avgScore = property.averageDocumentationScore

            // Assert
            // Average = (0.5 + 1.0) / 2 = 0.75
            XCTAssertEqual(avgScore, 0.75, accuracy: 0.01)
        }
    }

    // MARK: - Relationship Tests

    func testProperty_RoomsRelationship_IsInitiallyEmpty() async {
        await MainActor.run {
            // Arrange & Act
            let property = TestFixtures.testProperty()

            // Assert
            XCTAssertTrue(property.rooms.isEmpty)
        }
    }

    func testProperty_AddRoom_UpdatesRoomsArray() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let property = TestFixtures.testProperty()
            context.insert(property)

            let room = TestFixtures.testRoom()
            context.insert(room)

            // Act
            property.rooms.append(room)
            try context.save()

            // Assert
            XCTAssertEqual(property.rooms.count, 1)
            XCTAssertTrue(property.rooms.contains(room))
        }
    }

    func testProperty_DeleteProperty_CascadeDeletesRooms() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let property = TestFixtures.testProperty()
            context.insert(property)

            let room1 = TestFixtures.testRoom(name: "Room 1")
            let room2 = TestFixtures.testRoom(name: "Room 2")
            property.rooms.append(room1)
            property.rooms.append(room2)
            context.insert(room1)
            context.insert(room2)

            // Add items to rooms
            let item = TestFixtures.testItem(room: room1)
            context.insert(item)

            try context.save()

            // Verify setup
            XCTAssertEqual(property.rooms.count, 2)

            // Act - Delete property
            context.delete(property)
            try context.save()

            // Assert - Rooms should be cascade deleted
            let roomDescriptor = FetchDescriptor<Room>()
            let remainingRooms = try context.fetch(roomDescriptor)
            XCTAssertTrue(remainingRooms.isEmpty, "Rooms should be cascade deleted with property")

            // Items should also be deleted (cascade from room)
            let itemDescriptor = FetchDescriptor<Item>()
            let remainingItems = try context.fetch(itemDescriptor)
            XCTAssertTrue(remainingItems.isEmpty, "Items should be cascade deleted with rooms")
        }
    }

    // MARK: - Default Property Tests

    func testProperty_CreateDefault_CreatesMyHome() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            // Act
            let property = Property.createDefault(in: context)
            try context.save()

            // Assert
            XCTAssertEqual(property.name, "My Home")
            XCTAssertEqual(property.iconName, "house.fill")
            XCTAssertEqual(property.colorHex, "#007AFF")
            XCTAssertEqual(property.sortOrder, 0)
            XCTAssertTrue(property.isDefault)

            // Verify it was inserted into context
            let descriptor = FetchDescriptor<Property>()
            let properties = try context.fetch(descriptor)
            XCTAssertEqual(properties.count, 1)
            XCTAssertEqual(properties.first?.name, "My Home")
        }
    }

    func testProperty_CreateDefault_SetsIsDefaultTrue() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            // Act
            let property = Property.createDefault(in: context)

            // Assert
            XCTAssertTrue(property.isDefault)
        }
    }

    func testProperty_AvailableIcons_HasExpectedIcons() async {
        await MainActor.run {
            // Arrange & Act
            let icons = Property.availableIcons

            // Assert
            XCTAssertGreaterThan(icons.count, 0, "Should have preset icons")

            // Check for specific expected icons
            let expectedIcons = [
                "house.fill",
                "building.2.fill",
                "house.lodge.fill",
                "tent.fill",
                "shippingbox.fill"
            ]

            for expectedIcon in expectedIcons {
                XCTAssertTrue(icons.contains(expectedIcon),
                              "Should contain icon: \(expectedIcon)")
            }
        }
    }

    func testProperty_AvailableColors_HasExpectedColors() async {
        await MainActor.run {
            // Arrange & Act
            let colors = Property.availableColors

            // Assert
            XCTAssertGreaterThan(colors.count, 0, "Should have preset colors")

            // Check for specific expected colors
            let expectedColors = [
                "#007AFF",  // Blue
                "#34C759",  // Green
                "#FF9500",  // Orange
                "#FF3B30",  // Red
                "#AF52DE"   // Purple
            ]

            for expectedColor in expectedColors {
                XCTAssertTrue(colors.contains(expectedColor),
                              "Should contain color: \(expectedColor)")
            }

            // Verify all colors are valid hex format
            for color in colors {
                let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                XCTAssertNotNil(color.range(of: hexPattern, options: .regularExpression),
                                "Color \(color) should be valid hex format")
            }
        }
    }

    // MARK: - Edge Cases

    func testProperty_VeryLongName_IsAccepted() async {
        await MainActor.run {
            // Arrange
            let longName = String(repeating: "Property ", count: 100)

            // Act
            let property = Property(name: longName)

            // Assert
            XCTAssertEqual(property.name, longName)
        }
    }

    func testProperty_UnicodeInName_IsPreserved() async {
        await MainActor.run {
            // Arrange
            let unicodeName = "主要住宅 🏠"

            // Act
            let property = Property(name: unicodeName)

            // Assert
            XCTAssertEqual(property.name, unicodeName)
        }
    }

    func testProperty_NegativeSortOrder_IsAllowed() async {
        await MainActor.run {
            // Arrange & Act
            let property = Property(
                name: "Negative Sort Property",
                sortOrder: -10
            )

            // Assert
            XCTAssertEqual(property.sortOrder, -10)
        }
    }

    func testProperty_MultipleProperties_DifferentDefaults() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            // Create multiple properties
            let property1 = Property(name: "Property 1", isDefault: true)
            let property2 = Property(name: "Property 2", isDefault: false)
            let property3 = Property(name: "Property 3", isDefault: false)

            context.insert(property1)
            context.insert(property2)
            context.insert(property3)

            try context.save()

            // Act - Fetch all properties
            let descriptor = FetchDescriptor<Property>()
            let properties = try context.fetch(descriptor)

            // Assert
            XCTAssertEqual(properties.count, 3)
            let defaultProperties = properties.filter { $0.isDefault }
            XCTAssertEqual(defaultProperties.count, 1, "Only one property should be default")
            XCTAssertEqual(defaultProperties.first?.name, "Property 1")
        }
    }

    // MARK: - Persistence Tests

    func testProperty_PersistsCorrectly() async throws {
        try await MainActor.run {
            // Arrange
            let container = TestContainer.empty()
            let context = container.mainContext

            let property = Property(
                name: "Persist Test Property",
                address: "456 Test Ave",
                iconName: "building.fill",
                colorHex: "#34C759",
                sortOrder: 5,
                isDefault: true,
                notes: "Test notes"
            )
            context.insert(property)
            try context.save()

            // Act
            let descriptor = FetchDescriptor<Property>(
                predicate: #Predicate { $0.name == "Persist Test Property" }
            )
            let fetchedProperties = try context.fetch(descriptor)

            // Assert
            XCTAssertEqual(fetchedProperties.count, 1)
            let fetched = try XCTUnwrap(fetchedProperties.first)
            XCTAssertEqual(fetched.name, "Persist Test Property")
            XCTAssertEqual(fetched.address, "456 Test Ave")
            XCTAssertEqual(fetched.iconName, "building.fill")
            XCTAssertEqual(fetched.colorHex, "#34C759")
            XCTAssertEqual(fetched.sortOrder, 5)
            XCTAssertTrue(fetched.isDefault)
            XCTAssertEqual(fetched.notes, "Test notes")
        }
    }
}

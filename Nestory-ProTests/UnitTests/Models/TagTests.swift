//
//  TagTests.swift
//  Nestory-ProTests
//
//  Unit tests for Tag model (Task P2-05)
//

import XCTest
import SwiftData
@testable import Nestory_Pro

final class TagTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testTagInit_WithDefaults_HasCorrectValues() {
        // Arrange & Act
        let tag = Tag(name: "Test Tag")
        
        // Assert
        XCTAssertEqual(tag.name, "Test Tag")
        XCTAssertEqual(tag.colorHex, "#007AFF") // Default blue
        XCTAssertFalse(tag.isFavorite)
        XCTAssertNotNil(tag.id)
        XCTAssertNotNil(tag.createdAt)
        XCTAssertTrue(tag.items.isEmpty)
    }
    
    @MainActor
    func testTagInit_WithCustomColor_HasCorrectColor() {
        // Arrange & Act
        let tag = Tag(name: "Custom", colorHex: "#FF0000")
        
        // Assert
        XCTAssertEqual(tag.colorHex, "#FF0000")
    }
    
    @MainActor
    func testTagInit_AsFavorite_IsFavoriteTrue() {
        // Arrange & Act
        let tag = Tag(name: "Favorite Tag", isFavorite: true)
        
        // Assert
        XCTAssertTrue(tag.isFavorite)
    }
    
    // MARK: - Validation Tests
    
    @MainActor
    func testTagValidate_ValidTag_DoesNotThrow() throws {
        // Arrange
        let tag = Tag(name: "Valid Tag", colorHex: "#00FF00")
        
        // Act & Assert
        XCTAssertNoThrow(try tag.validate())
    }
    
    @MainActor
    func testTagValidate_EmptyName_ThrowsEmptyNameError() {
        // Arrange
        let tag = Tag(name: "")
        
        // Act & Assert
        XCTAssertThrowsError(try tag.validate()) { error in
            XCTAssertEqual(error as? Tag.ValidationError, .emptyName)
        }
    }
    
    @MainActor
    func testTagValidate_WhitespaceName_ThrowsEmptyNameError() {
        // Arrange
        let tag = Tag(name: "   ")
        
        // Act & Assert
        XCTAssertThrowsError(try tag.validate()) { error in
            XCTAssertEqual(error as? Tag.ValidationError, .emptyName)
        }
    }
    
    @MainActor
    func testTagValidate_InvalidColorHex_ThrowsInvalidColorError() {
        // Arrange
        let tag = Tag(name: "Test", colorHex: "invalid")
        
        // Act & Assert
        XCTAssertThrowsError(try tag.validate()) { error in
            XCTAssertEqual(error as? Tag.ValidationError, .invalidColorHex)
        }
    }
    
    @MainActor
    func testTagValidate_ShortColorHex_ThrowsInvalidColorError() {
        // Arrange
        let tag = Tag(name: "Test", colorHex: "#FFF")
        
        // Act & Assert
        XCTAssertThrowsError(try tag.validate()) { error in
            XCTAssertEqual(error as? Tag.ValidationError, .invalidColorHex)
        }
    }
    
    @MainActor
    func testTagValidate_MissingHash_ThrowsInvalidColorError() {
        // Arrange
        let tag = Tag(name: "Test", colorHex: "FF0000")
        
        // Act & Assert
        XCTAssertThrowsError(try tag.validate()) { error in
            XCTAssertEqual(error as? Tag.ValidationError, .invalidColorHex)
        }
    }
    
    // MARK: - Predefined Colors Tests
    
    func testPredefinedColors_HasExpectedCount() {
        // Assert - Should have 9 predefined colors
        XCTAssertEqual(Tag.predefinedColors.count, 9)
    }
    
    func testPredefinedColors_AllAreValidHex() {
        // Assert - All colors should match #RRGGBB pattern
        let pattern = "^#[0-9A-Fa-f]{6}$"
        for color in Tag.predefinedColors {
            XCTAssertNotNil(
                color.range(of: pattern, options: .regularExpression),
                "Color \(color) should be valid hex format"
            )
        }
    }
    
    func testPredefinedColors_ContainsDefaultBlue() {
        XCTAssertTrue(Tag.predefinedColors.contains("#007AFF"))
    }
    
    // MARK: - Default Favorites Tests
    
    func testDefaultFavorites_HasFourTags() {
        XCTAssertEqual(Tag.defaultFavorites.count, 4)
    }
    
    func testDefaultFavorites_ContainsEssential() {
        let names = Tag.defaultFavorites.map { $0.name }
        XCTAssertTrue(names.contains("Essential"))
    }
    
    func testDefaultFavorites_ContainsHighValue() {
        let names = Tag.defaultFavorites.map { $0.name }
        XCTAssertTrue(names.contains("High Value"))
    }
    
    func testDefaultFavorites_ContainsElectronics() {
        let names = Tag.defaultFavorites.map { $0.name }
        XCTAssertTrue(names.contains("Electronics"))
    }
    
    func testDefaultFavorites_ContainsInsuranceCritical() {
        let names = Tag.defaultFavorites.map { $0.name }
        XCTAssertTrue(names.contains("Insurance-Critical"))
    }
    
    // MARK: - SwiftData Persistence Tests
    
    @MainActor
    func testTagPersistence_InsertAndFetch_Succeeds() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        let tag = Tag(name: "Persisted Tag", colorHex: "#FF9500", isFavorite: true)
        
        // Act
        context.insert(tag)
        try context.save()
        
        let descriptor = FetchDescriptor<Tag>()
        let tags = try context.fetch(descriptor)
        
        // Assert
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags.first?.name, "Persisted Tag")
        XCTAssertEqual(tags.first?.colorHex, "#FF9500")
        XCTAssertTrue(tags.first?.isFavorite ?? false)
    }
    
    @MainActor
    func testCreateDefaultTags_InsertsAllFavorites() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        // Act
        Tag.createDefaultTags(in: context)
        try context.save()
        
        let descriptor = FetchDescriptor<Tag>()
        let tags = try context.fetch(descriptor)
        
        // Assert
        XCTAssertEqual(tags.count, 4)
        XCTAssertTrue(tags.allSatisfy { $0.isFavorite })
    }
    
    // MARK: - Item Relationship Tests
    
    @MainActor
    func testTagItemRelationship_AddTagToItem_UpdatesBothSides() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let tag = Tag(name: "Test Tag")
        let item = TestFixtures.testItem(name: "Tagged Item")
        
        context.insert(tag)
        context.insert(item)
        
        // Act
        item.tagObjects.append(tag)
        try context.save()
        
        // Assert
        XCTAssertEqual(item.tagObjects.count, 1)
        XCTAssertEqual(item.tagObjects.first?.name, "Test Tag")
    }
    
    @MainActor
    func testTagItemRelationship_RemoveTag_UpdatesItem() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let tag = Tag(name: "Removable Tag")
        let item = TestFixtures.testItem(name: "Item")
        
        context.insert(tag)
        context.insert(item)
        item.tagObjects.append(tag)
        try context.save()
        
        // Act
        item.tagObjects.removeAll()
        try context.save()
        
        // Assert
        XCTAssertTrue(item.tagObjects.isEmpty)
    }
    
    @MainActor
    func testTagItemRelationship_MultipleTagsOnItem_AllPersist() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let tag1 = Tag(name: "Tag 1", colorHex: "#FF0000")
        let tag2 = Tag(name: "Tag 2", colorHex: "#00FF00")
        let tag3 = Tag(name: "Tag 3", colorHex: "#0000FF")
        let item = TestFixtures.testItem(name: "Multi-tagged Item")
        
        context.insert(tag1)
        context.insert(tag2)
        context.insert(tag3)
        context.insert(item)
        
        // Act
        item.tagObjects.append(contentsOf: [tag1, tag2, tag3])
        try context.save()
        
        // Assert
        XCTAssertEqual(item.tagObjects.count, 3)
    }
    
    // MARK: - Fetch Descriptor Tests
    
    @MainActor
    func testAllTagsFetch_ReturnsSortedByName() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        context.insert(Tag(name: "Zebra"))
        context.insert(Tag(name: "Alpha"))
        context.insert(Tag(name: "Middle"))
        try context.save()
        
        // Act
        let tags = try context.fetch(Tag.allTagsFetch)
        
        // Assert
        XCTAssertEqual(tags.count, 3)
        XCTAssertEqual(tags[0].name, "Alpha")
        XCTAssertEqual(tags[1].name, "Middle")
        XCTAssertEqual(tags[2].name, "Zebra")
    }
    
    @MainActor
    func testFavoriteTagsFetch_OnlyReturnsFavorites() throws {
        // Arrange
        let container = TestContainer.empty()
        let context = container.mainContext
        
        context.insert(Tag(name: "Favorite", isFavorite: true))
        context.insert(Tag(name: "Not Favorite", isFavorite: false))
        context.insert(Tag(name: "Also Favorite", isFavorite: true))
        try context.save()
        
        // Act
        let tags = try context.fetch(Tag.favoriteTagsFetch)
        
        // Assert
        XCTAssertEqual(tags.count, 2)
        XCTAssertTrue(tags.allSatisfy { $0.isFavorite })
    }
    
    // MARK: - ValidationError Descriptions
    
    func testValidationError_EmptyName_HasDescription() {
        let error = Tag.ValidationError.emptyName
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }
    
    func testValidationError_DuplicateName_HasDescription() {
        let error = Tag.ValidationError.duplicateName
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }
    
    func testValidationError_InvalidColorHex_HasDescription() {
        let error = Tag.ValidationError.invalidColorHex
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }
}

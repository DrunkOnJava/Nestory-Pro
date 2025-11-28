# Preview & Fixtures Strategy

Comprehensive guide to using sample data, fixtures, and SwiftUI previews in Nestory Pro.

## Overview

The app uses a clean separation between production data and development/test data through:

1. **PreviewFixtures** - Realistic sample data for SwiftUI previews
2. **PreviewContainer** - In-memory SwiftData containers
3. **PreviewHelpers** - Utilities for preview variations
4. **TestFixtures** - Predictable data for unit tests

## Folder Structure

```
Nestory-Pro/
├── PreviewContent/
│   ├── PreviewFixtures.swift      # Sample data factory
│   ├── PreviewContainer.swift     # In-memory containers
│   └── PreviewHelpers.swift       # Preview utilities
└── Nestory-ProTests/
    └── TestFixtures.swift          # Test-specific fixtures
```

## Using PreviewFixtures

### Basic Usage

```swift
#Preview("Item with Data") {
    ItemDetailView(item: PreviewFixtures.sampleDocumentedItem())
        .modelContainer(PreviewContainer.withSampleData())
}
```

### Available Fixtures

#### Categories
```swift
PreviewFixtures.sampleCategories()              // All default categories
PreviewFixtures.sampleElectronicsCategory()     // Single category
PreviewFixtures.sampleJewelryCategory()         // Another category
```

#### Rooms
```swift
PreviewFixtures.sampleRooms()                   // All default rooms
PreviewFixtures.sampleLivingRoom()              // Single room
PreviewFixtures.sampleBedroom()                 // Another room
```

#### Items
```swift
PreviewFixtures.sampleDocumentedItem()          // Fully documented item
PreviewFixtures.samplePartialItem()             // Missing some fields
PreviewFixtures.sampleMinimalItem()             // Minimal data
PreviewFixtures.sampleItemCollection()          // Collection of 8 items
```

#### Receipts
```swift
PreviewFixtures.sampleReceipt()                 // Complete receipt
PreviewFixtures.sampleReceiptWithLowConfidence() // Low OCR confidence
```

#### Photos
```swift
PreviewFixtures.sampleItemPhotos(count: 3)      // Multiple photos
```

## Using PreviewContainer

### Container Variations

```swift
// Empty container (no data)
PreviewContainer.empty()

// Basic data (categories and rooms only)
PreviewContainer.withBasicData()

// Sample data (full dataset)
PreviewContainer.withSampleData()

// Many items (stress testing)
PreviewContainer.withManyItems(count: 50)

// Empty inventory (categories/rooms but no items)
PreviewContainer.emptyInventory()
```

### Example Usage

```swift
#Preview("Empty State") {
    InventoryView()
        .modelContainer(PreviewContainer.emptyInventory())
}

#Preview("With Data") {
    InventoryView()
        .modelContainer(PreviewContainer.withSampleData())
}

#Preview("Many Items") {
    InventoryView()
        .modelContainer(PreviewContainer.withManyItems(count: 100))
}
```

## Preview Variations

### Color Schemes

```swift
#Preview("Light Mode") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
}

#Preview("Dark Mode") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .preferredColorScheme(.dark)
}
```

### Device Sizes

```swift
#Preview("iPhone SE") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
}

#Preview("iPhone 15 Pro Max") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
}

#Preview("iPad Pro") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
}
```

### Dynamic Type

```swift
#Preview("Small Text") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(\.dynamicTypeSize, .xSmall)
}

#Preview("Large Text") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("Accessibility XXXL") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(\.dynamicTypeSize, .accessibility5)
}
```

### Combined Variations

```swift
#Preview("iPhone SE - Dark - Large Text") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .xxxLarge)
}
```

## Preview Helper Utilities

### View Modifiers

```swift
// Wrap in NavigationStack
MyView()
    .previewInNavigation(title: "My Title")

// Add padding and background
MyView()
    .previewLayout()

// Wrap in ScrollView
MyView()
    .previewInScrollView()

// Fixed size for components
MyView()
    .previewFixedSize(width: 375, height: 200)
```

### State Wrappers

For views requiring @State bindings:

```swift
#Preview("With Binding") {
    PreviewStateWrapper(initialValue: false) { $isPresented in
        Button("Toggle") {
            isPresented.toggle()
        }
        .sheet(isPresented: $isPresented) {
            Text("Sheet Content")
        }
    }
}
```

## Testing with TestFixtures

### Unit Test Example

```swift
import XCTest
@testable import Nestory_Pro

final class ItemTests: XCTestCase {
    
    @MainActor
    func testItemDocumentationScore() throws {
        // Create test container
        let container = TestContainer.empty()
        let context = container.mainContext
        
        // Add test data
        let category = TestFixtures.testCategory()
        let room = TestFixtures.testRoom()
        context.insert(category)
        context.insert(room)
        
        // Create test item
        let item = TestFixtures.testDocumentedItem(
            category: category,
            room: room
        )
        context.insert(item)
        
        // Add photo
        let photo = TestFixtures.testItemPhoto()
        photo.item = item
        context.insert(photo)
        
        // Assert documentation score
        XCTAssertEqual(item.documentationScore, 1.0)
        XCTAssertTrue(item.isDocumented)
    }
    
    @MainActor
    func testUndocumentedItem() throws {
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let item = TestFixtures.testUndocumentedItem()
        context.insert(item)
        
        XCTAssertEqual(item.documentationScore, 0.0)
        XCTAssertFalse(item.isDocumented)
        XCTAssertEqual(item.missingDocumentation.count, 4)
    }
}
```

### XCTest Extensions

```swift
// Helper methods available in all test cases
@MainActor
func testFetchItems() throws {
    let container = createTestContainer()
    let context = container.mainContext
    
    // Add test items
    let item = TestFixtures.testItem()
    context.insert(item)
    try context.save()
    
    // Fetch using helper
    let items = try fetchAllItems(from: context)
    XCTAssertEqual(items.count, 1)
}
```

## Best Practices

### 1. Avoid Mixing Real and Fake Data

✅ **Good** - Use in-memory containers for previews:
```swift
#Preview {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
}
```

❌ **Bad** - Don't use production container:
```swift
#Preview {
    MyView()
        .modelContainer(sharedModelContainer) // Production data!
}
```

### 2. Use Appropriate Data States

```swift
// Empty state
#Preview("Empty") {
    ListView()
        .modelContainer(PreviewContainer.emptyInventory())
}

// Populated state
#Preview("With Items") {
    ListView()
        .modelContainer(PreviewContainer.withSampleData())
}

// Stress test
#Preview("Many Items") {
    ListView()
        .modelContainer(PreviewContainer.withManyItems(count: 100))
}
```

### 3. Name Previews Descriptively

```swift
✅ #Preview("Dark Mode - Large Text")
✅ #Preview("Empty Inventory State")
✅ #Preview("Error - Network Unavailable")

❌ #Preview("Test 1")
❌ #Preview("Preview")
```

### 4. Test Multiple Variations

For each view, create previews for:
- Light and dark mode
- Different device sizes
- Different dynamic type sizes
- Empty, partial, and full data states
- Error states (if applicable)

### 5. Keep Fixtures Simple

```swift
// ✅ Simple, focused fixtures
static func sampleDocumentedItem() -> Item {
    Item(
        name: "MacBook Pro",
        purchasePrice: Decimal(2999),
        // ... essential fields only
    )
}

// ❌ Overly complex fixtures
static func complexScenarioWithEverything() -> (Item, [Receipt], [Photo], Category, Room, [User]) {
    // Too much coupling and complexity
}
```

### 6. Use DEBUG Compilation Flags

All preview code is wrapped in `#if DEBUG` to ensure it's excluded from release builds:

```swift
#if DEBUG

struct PreviewFixtures {
    // Preview-only code
}

#endif
```

## Debug-Only Sample Data Mode

For development builds, you can optionally populate the app with sample data:

```swift
// In Nestory_ProApp.swift
#if DEBUG
private func loadSampleDataIfNeeded() {
    guard UserDefaults.standard.bool(forKey: "LoadSampleData") else {
        return
    }
    
    let context = sharedModelContainer.mainContext
    
    // Check if data already exists
    let descriptor = FetchDescriptor<Item>()
    let existingItems = (try? context.fetch(descriptor)) ?? []
    guard existingItems.isEmpty else { return }
    
    // Load sample data
    let categories = PreviewFixtures.sampleCategories()
    categories.forEach { context.insert($0) }
    
    let rooms = PreviewFixtures.sampleRooms()
    rooms.forEach { context.insert($0) }
    
    let items = PreviewFixtures.sampleItemCollection(
        categories: categories,
        rooms: rooms
    )
    items.forEach { context.insert($0) }
    
    try? context.save()
}
#endif
```

Toggle via debug scheme or terminal:
```bash
defaults write com.drunkonjava.nestory.pro LoadSampleData -bool true
```

## Common Patterns

### List View Previews

```swift
#Preview("List - Empty") {
    ItemListView()
        .modelContainer(PreviewContainer.emptyInventory())
}

#Preview("List - Few Items") {
    ItemListView()
        .modelContainer(PreviewContainer.withSampleData())
}

#Preview("List - Many Items") {
    ItemListView()
        .modelContainer(PreviewContainer.withManyItems(count: 50))
}

#Preview("List - Dark Mode") {
    ItemListView()
        .modelContainer(PreviewContainer.withSampleData())
        .preferredColorScheme(.dark)
}
```

### Detail View Previews

```swift
#Preview("Detail - Documented") {
    let category = PreviewFixtures.sampleElectronicsCategory()
    let room = PreviewFixtures.sampleLivingRoom()
    let item = PreviewFixtures.sampleDocumentedItem(
        category: category,
        room: room
    )
    
    return ItemDetailView(item: item)
        .modelContainer(PreviewContainer.withSampleData())
}

#Preview("Detail - Minimal Data") {
    ItemDetailView(item: PreviewFixtures.sampleMinimalItem())
        .modelContainer(PreviewContainer.withBasicData())
}
```

### Form View Previews

```swift
#Preview("Form - New Item") {
    AddItemView()
        .modelContainer(PreviewContainer.withBasicData())
}

#Preview("Form - Edit Item") {
    let item = PreviewFixtures.sampleDocumentedItem()
    return EditItemView(item: item)
        .modelContainer(PreviewContainer.withSampleData())
}
```

## Summary

The fixtures and preview system provides:

✅ **Isolation** - Preview data never touches production data  
✅ **Consistency** - Reproducible sample data  
✅ **Variations** - Easy testing of different states  
✅ **Speed** - Fast preview rendering with in-memory data  
✅ **Maintainability** - Centralized fixture management

Always use `PreviewContainer` for views that need SwiftData, and create multiple preview variations to catch layout and accessibility issues early.

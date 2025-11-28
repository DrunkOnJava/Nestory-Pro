# Testing Strategy

Comprehensive testing strategy for Nestory Pro iOS app using XCTest, Swift Concurrency, and modern testing practices.

## Test Architecture Overview

### Test Pyramid

```
                   /\
                  /  \     E2E/Manual
                 /    \
                /------\   UI Tests (10-20%)
               /        \
              /----------\  Integration Tests (20-30%)
             /            \
            /--------------\ Unit Tests (50-70%)
```

### Test Types

1. **Unit Tests** (50-70% of tests)
   - Test individual functions, methods, classes in isolation
   - Fast execution (< 0.1s per test)
   - No dependencies on external systems
   - Mocked dependencies

2. **Integration Tests** (20-30% of tests)
   - Test interaction between components
   - Use in-memory persistence
   - Test data flow and transformations
   - Moderate execution speed (< 1s per test)

3. **UI Tests** (10-20% of tests)
   - Test complete user workflows
   - Use accessibility identifiers
   - Test critical paths only
   - Slower execution (1-10s per test)

4. **Performance Tests** (As needed)
   - Measure critical operations
   - Track performance regressions
   - Set performance baselines

5. **Snapshot Tests** (Optional, not in v1)
   - Visual regression testing
   - Requires third-party framework

## Project Structure

```
Nestory-Pro.xcodeproj
├── Nestory-Pro/
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   └── PreviewContent/
├── Nestory-ProTests/              # Unit & Integration Tests
│   ├── UnitTests/
│   │   ├── Models/
│   │   │   ├── ItemTests.swift
│   │   │   ├── CategoryTests.swift
│   │   │   └── RoomTests.swift
│   │   ├── Services/
│   │   │   ├── SettingsManagerTests.swift
│   │   │   └── [Future: OcrServiceTests.swift]
│   │   └── ViewModels/
│   │       └── [Future: InventoryViewModelTests.swift]
│   ├── IntegrationTests/
│   │   ├── PersistenceTests.swift
│   │   ├── DataFlowTests.swift
│   │   └── RelationshipTests.swift
│   ├── PerformanceTests/
│   │   ├── DocumentationScoreTests.swift
│   │   └── DataLoadingTests.swift
│   ├── TestUtilities/
│   │   ├── TestFixtures.swift       # Already exists
│   │   ├── MockServices.swift
│   │   └── TestHelpers.swift
│   └── Nestory_ProTests.swift       # Default test file
└── Nestory-ProUITests/              # UI Tests
    ├── Flows/
    │   ├── InventoryFlowTests.swift
    │   ├── CaptureFlowTests.swift
    │   └── SettingsFlowTests.swift
    ├── Screens/
    │   ├── MainTabViewUITests.swift
    │   └── ItemDetailUITests.swift
    └── TestUtilities/
        ├── UITestHelpers.swift
        └── AccessibilityIdentifiers.swift
```

## What to Test Where

### Unit Tests

**Test:**
- ✅ Model computed properties and methods
- ✅ Business logic in services
- ✅ View model state transformations
- ✅ Utilities and extensions
- ✅ Validation logic
- ✅ Formatters and parsers

**Don't Test:**
- ❌ SwiftUI view rendering
- ❌ SwiftData relationships (use integration tests)
- ❌ UI interactions
- ❌ Third-party framework internals

**Example: Model Unit Test**
```swift
final class ItemTests: XCTestCase {
    
    @MainActor
    func testDocumentationScore_WithAllFields_Returns1() {
        let item = TestFixtures.testDocumentedItem(
            category: TestFixtures.testCategory(),
            room: TestFixtures.testRoom()
        )
        
        // Simulate having a photo
        item.photos = [TestFixtures.testItemPhoto()]
        
        XCTAssertEqual(item.documentationScore, 1.0)
        XCTAssertTrue(item.isDocumented)
    }
    
    @MainActor
    func testDocumentationScore_WithNoFields_Returns0() {
        let item = TestFixtures.testUndocumentedItem()
        
        XCTAssertEqual(item.documentationScore, 0.0)
        XCTAssertFalse(item.isDocumented)
        XCTAssertEqual(item.missingDocumentation.count, 4)
    }
}
```

### Integration Tests

**Test:**
- ✅ SwiftData CRUD operations
- ✅ Relationship cascades and nullifies
- ✅ Data migrations
- ✅ Service → Repository → Model flow
- ✅ Query performance with realistic data volumes

**Don't Test:**
- ❌ UI rendering
- ❌ User interactions

**Example: Integration Test**
```swift
final class PersistenceIntegrationTests: XCTestCase {
    
    @MainActor
    func testItemWithPhotos_CascadeDelete() throws {
        let container = TestContainer.empty()
        let context = container.mainContext
        
        // Create item with photos
        let item = TestFixtures.testItem()
        context.insert(item)
        
        let photo1 = TestFixtures.testItemPhoto()
        photo1.item = item
        context.insert(photo1)
        
        let photo2 = TestFixtures.testItemPhoto()
        photo2.item = item
        context.insert(photo2)
        
        try context.save()
        
        // Verify photos exist
        let photoDescriptor = FetchDescriptor<ItemPhoto>()
        let photos = try context.fetch(photoDescriptor)
        XCTAssertEqual(photos.count, 2)
        
        // Delete item
        context.delete(item)
        try context.save()
        
        // Verify photos were cascade deleted
        let photosAfterDelete = try context.fetch(photoDescriptor)
        XCTAssertEqual(photosAfterDelete.count, 0)
    }
}
```

### UI Tests

**Test:**
- ✅ Critical user workflows (happy paths)
- ✅ Navigation between screens
- ✅ Form submissions
- ✅ Error states visible to users
- ✅ Accessibility

**Don't Test:**
- ❌ Every possible interaction
- ❌ Business logic (use unit tests)
- ❌ Visual appearance (use snapshot tests)

**Example: UI Test**
```swift
final class MainTabViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testTabNavigation_AllTabsAccessible() throws {
        // Verify all tabs exist
        XCTAssertTrue(app.tabBars.buttons["Inventory"].exists)
        XCTAssertTrue(app.tabBars.buttons["Capture"].exists)
        XCTAssertTrue(app.tabBars.buttons["Reports"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
        
        // Navigate to each tab
        app.tabBars.buttons["Capture"].tap()
        XCTAssertTrue(app.staticTexts["Capture"].exists)
        
        app.tabBars.buttons["Reports"].tap()
        XCTAssertTrue(app.staticTexts["Reports"].exists)
        
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        
        app.tabBars.buttons["Inventory"].tap()
        XCTAssertTrue(app.staticTexts["Inventory"].exists)
    }
}
```

### Performance Tests

**Test:**
- ✅ Heavy computation operations
- ✅ Large data set queries
- ✅ Complex UI rendering
- ✅ Startup time
- ✅ Memory usage

**Example: Performance Test**
```swift
final class DocumentationScorePerformanceTests: XCTestCase {
    
    @MainActor
    func testDocumentationScore_ManyItems() throws {
        let container = TestContainer.withManyItems(count: 1000)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        
        measure {
            // Measure time to calculate scores for all items
            let scores = items.map { $0.documentationScore }
            XCTAssertEqual(scores.count, 1000)
        }
    }
    
    @MainActor
    func testFetchAllItems_Performance() throws {
        let container = TestContainer.withManyItems(count: 5000)
        let context = container.mainContext
        
        measure {
            let descriptor = FetchDescriptor<Item>()
            let items = try? context.fetch(descriptor)
            XCTAssertNotNil(items)
        }
    }
}
```

## Testing Async/Await Code

### Using Swift Concurrency in Tests

```swift
func testAsyncOperation() async throws {
    let service = MockOcrService()
    let result = await service.processReceipt(image: testImage)
    
    XCTAssertNotNil(result)
    XCTAssertEqual(result.vendor, "Test Store")
}

func testAsyncOperationWithTimeout() async throws {
    let service = SlowService()
    
    let task = Task {
        try await service.slowOperation()
    }
    
    // Wait with timeout
    try await Task.sleep(for: .seconds(2))
    
    if !task.isCancelled {
        task.cancel()
        XCTFail("Operation took too long")
    }
}
```

### Using XCTestExpectation

```swift
func testCompletionHandler() {
    let expectation = expectation(description: "Service completes")
    
    service.fetchData { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
}
```

### Testing @MainActor Code

```swift
@MainActor
func testMainActorFunction() {
    let viewModel = InventoryViewModel()
    viewModel.loadItems()
    
    XCTAssertTrue(viewModel.items.isEmpty)
}

func testMainActorAsync() async {
    await MainActor.run {
        let viewModel = InventoryViewModel()
        XCTAssertNotNil(viewModel)
    }
}
```

## Mocking & Dependency Injection

### Protocol-Based Mocking

```swift
// Protocol
protocol OcrServiceProtocol {
    func processReceipt(_ image: UIImage) async throws -> ReceiptData
}

// Mock Implementation
final class MockOcrService: OcrServiceProtocol {
    var processReceiptCalled = false
    var resultToReturn: ReceiptData?
    var errorToThrow: Error?
    
    func processReceipt(_ image: UIImage) async throws -> ReceiptData {
        processReceiptCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return resultToReturn ?? ReceiptData(vendor: "Mock", total: 99.99)
    }
}

// Test Usage
func testReceiptProcessing() async throws {
    let mockOcr = MockOcrService()
    mockOcr.resultToReturn = ReceiptData(vendor: "Test Store", total: 150.00)
    
    let viewModel = CaptureViewModel(ocrService: mockOcr)
    await viewModel.processReceipt(testImage)
    
    XCTAssertTrue(mockOcr.processReceiptCalled)
    XCTAssertEqual(viewModel.receiptData?.vendor, "Test Store")
}
```

## Accessibility Identifiers

### Adding Identifiers to Views

```swift
// Define identifiers in a central location
extension AccessibilityIdentifiers {
    enum MainTab {
        static let inventory = "tab.inventory"
        static let capture = "tab.capture"
        static let reports = "tab.reports"
        static let settings = "tab.settings"
    }
    
    enum Inventory {
        static let itemList = "inventory.itemList"
        static let addButton = "inventory.addButton"
        static let searchField = "inventory.searchField"
    }
}

// Use in SwiftUI
Button("Add Item") {
    showAddItem = true
}
.accessibilityIdentifier(AccessibilityIdentifiers.Inventory.addButton)

List {
    // content
}
.accessibilityIdentifier(AccessibilityIdentifiers.Inventory.itemList)
```

### Using in UI Tests

```swift
func testAddItemFlow() {
    let addButton = app.buttons[AccessibilityIdentifiers.Inventory.addButton]
    XCTAssertTrue(addButton.exists)
    addButton.tap()
    
    // Verify add item sheet appears
    XCTAssertTrue(app.sheets.firstMatch.exists)
}
```

## Naming Conventions

### Test Method Names

Follow the pattern: `test<What>_<Condition>_<ExpectedResult>()`

```swift
✅ Good:
func testDocumentationScore_AllFieldsFilled_Returns1()
func testSaveItem_ValidData_Succeeds()
func testDeleteItem_WithPhotos_CascadesDelete()
func testSearch_EmptyQuery_ReturnsAllItems()

❌ Bad:
func testItem()
func test1()
func testDocumentation()
```

### Test Class Names

```swift
✅ Good:
ItemTests
ItemIntegrationTests
ItemDocumentationTests
InventoryViewModelTests
MainTabViewUITests

❌ Bad:
TestItem
Tests
MyTests
```

### Test Organization

```swift
final class ItemTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: Item!  // System Under Test
    var container: ModelContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Setup code
    }
    
    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Documentation Score Tests
    
    func testDocumentationScore_...() { }
    
    // MARK: - Validation Tests
    
    func testValidation_...() { }
    
    // MARK: - Relationship Tests
    
    func testRelationships_...() { }
}
```

## Keeping Tests Fast & Reliable

### Speed

1. **Use in-memory databases** for all tests
2. **Minimize async waits** - use short timeouts
3. **Avoid real network calls** - mock everything
4. **Parallel test execution** - keep tests independent
5. **Selective test running** during development

### Reliability

1. **No shared state** between tests
2. **Clean setup/teardown** for each test
3. **Deterministic test data** - avoid randomness
4. **Avoid time-dependent tests** - use mocked clocks
5. **Clear assertions** - test one thing per test

### Example: Fast & Reliable Test

```swift
final class FastItemTests: XCTestCase {
    
    @MainActor
    func testDocumentationScore() throws {
        // Fast: In-memory container
        let container = TestContainer.empty()
        let context = container.mainContext
        
        // Reliable: Predictable test data
        let item = Item(
            name: "Test Item",
            purchasePrice: Decimal(100),
            category: nil,
            room: nil,
            condition: .good
        )
        
        // Clear assertion
        XCTAssertEqual(item.documentationScore, 0.5)
    }
}
```

## Scaling the Test Suite

### As App Grows

1. **Organize by feature** - mirror app structure
2. **Shared test utilities** in TestUtilities/
3. **Test data builders** for complex objects
4. **Test suites** for different purposes

### Test Suites

```swift
// Fast tests for CI
final class UnitTestSuite: XCTestCase {
    static var allTests = [
        ItemTests.self,
        CategoryTests.self,
        RoomTests.self
    ]
}

// Slower integration tests
final class IntegrationTestSuite: XCTestCase {
    static var allTests = [
        PersistenceTests.self,
        RelationshipTests.self
    ]
}
```

### Running Tests Selectively

```bash
# Run only unit tests
xcodebuild test -project Nestory-Pro.xcodeproj \
  -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/UnitTests

# Run specific test class
xcodebuild test -project Nestory-Pro.xcodeproj \
  -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/ItemTests

# Run specific test
xcodebuild test -project Nestory-Pro.xcodeproj \
  -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/ItemTests/testDocumentationScore
```

## Code Coverage

### Enable in Xcode

1. Edit Scheme → Test → Options
2. Check "Code Coverage"
3. Enable "Gather coverage for all targets"

### Target Goals

- **Unit Tests**: 80-90% coverage
- **Integration Tests**: Key data flows covered
- **Overall**: 70%+ coverage

### What Not to Worry About

- SwiftUI view body coverage (tested by UI tests)
- Generated code (SwiftData, StoreKit)
- Trivial getters/setters
- Preview code

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project Nestory-Pro.xcodeproj \
            -scheme Nestory-Pro \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:Nestory-ProTests/UnitTests
      
      - name: Run Integration Tests
        run: |
          xcodebuild test \
            -project Nestory-Pro.xcodeproj \
            -scheme Nestory-Pro \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:Nestory-ProTests/IntegrationTests
```

## Recommended Frameworks

### XCTest (Built-in) ✅
- Unit testing
- Integration testing
- Performance testing
- UI testing

### Swift Testing (iOS 18+) 🔄
- Modern alternative to XCTest
- Better async support
- Parameterized tests
- Not available for iOS 17

### Third-Party (Optional)

**Snapshot Testing** - `swift-snapshot-testing`
```swift
// Not in v1, but for future reference
func testViewSnapshot() {
    let view = ItemDetailView(item: testItem)
    assertSnapshot(matching: view, as: .image)
}
```

**Quick/Nimble** - BDD-style testing
```swift
// Optional, adds readability
expect(item.documentationScore).to(equal(1.0))
```

## Summary Checklist

✅ **Structure**
- [ ] Separate unit/integration/UI test folders
- [ ] Test utilities in shared location
- [ ] Mirror app structure in tests

✅ **Coverage**
- [ ] 80%+ unit test coverage
- [ ] Key workflows in UI tests
- [ ] Critical paths in integration tests

✅ **Speed**
- [ ] Unit tests < 0.1s each
- [ ] Integration tests < 1s each
- [ ] Full suite < 5 minutes

✅ **Reliability**
- [ ] No flaky tests
- [ ] Tests pass in parallel
- [ ] Deterministic test data

✅ **Maintainability**
- [ ] Clear naming conventions
- [ ] Shared test utilities
- [ ] Documentation for complex tests

## Next Steps

1. Review TestFixtures.swift (already created)
2. Create example tests for each category
3. Add accessibility identifiers to views
4. Set up CI pipeline
5. Establish code coverage baseline
6. Write tests for new features before implementation (TDD)

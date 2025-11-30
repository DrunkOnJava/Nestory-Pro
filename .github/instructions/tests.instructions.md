---
applyTo: "**/*Tests.swift"
---

# Test Guidelines

When writing tests for Nestory Pro:

## Naming Convention

`test<What>_<Condition>_<ExpectedResult>()`

Examples:
- ✅ `testDocumentationScore_AllFieldsFilled_Returns1()`
- ✅ `testItemDelete_WithPhotos_CascadesDelete()`
- ❌ `testItem()`, `test1()`

## Performance Targets

- Unit tests: < 0.1s per test
- Integration tests: < 1s per test
- UI tests: < 10s per test

## Required Patterns

- **Always** use in-memory containers: `TestContainer.withSampleData()`
- **Always** use `TestFixtures` for predictable data
- **Never** use production `sharedModelContainer`
- **Mark** SwiftData operations with `@MainActor`

## Test Structure

```swift
@MainActor
func testDocumentationScore_FullyDocumented_Returns1() throws {
    // Arrange
    let container = TestContainer.withSampleData()
    let context = container.mainContext
    let item = TestFixtures.testDocumentedItem()
    context.insert(item)

    // Act
    let score = item.documentationScore

    // Assert
    XCTAssertEqual(score, 1.0)
}
```

## Coverage Requirements

- Minimum 60% coverage for new files
- 100% coverage for critical business logic (documentation scoring, Pro limits)
- All public APIs must have tests

# Test Infrastructure

This directory contains the test tagging system for Nestory-Pro, enabling selective test execution and performance monitoring.

## Overview

The test tagging system allows tests to be classified by:
- **Performance** (fast, medium, slow)
- **Category** (unit, integration, performance, snapshot)
- **Domain** (model, service, viewModel, ui)
- **Priority** (critical, regression)

## Files

| File | Purpose |
|------|---------|
| `TestTags.swift` | Enum defining all available test tags |
| `XCTestCase+Tags.swift` | Extension for tagging test classes |
| `XCTestCase+PerformanceMonitor.swift` | Timeout enforcement and performance assertions |

## Usage

### Tagging a Test Class

Override the `tags` property in your test class:

```swift
final class MyTests: XCTestCase {
    override var tags: Set<TestTag> {
        [.fast, .unit, .model]
    }
}
```

### Performance-Based Tags

| Tag | Duration | Use Case |
|-----|----------|----------|
| `.fast` | <0.1s | Quick unit tests, computed properties |
| `.medium` | 0.1-1s | Integration tests, SwiftData operations |
| `.slow` | >1s | Complex workflows, batch operations |

### Category-Based Tags

| Tag | Description |
|-----|-------------|
| `.unit` | Pure unit tests with no dependencies |
| `.integration` | Tests involving SwiftData/file system |
| `.performance` | Benchmark tests measuring execution time |
| `.snapshot` | Visual regression tests |

### Domain-Based Tags

| Tag | Layer |
|-----|-------|
| `.model` | Model layer (Item, Room, Category, etc.) |
| `.service` | Service layer (OCR, Reports, Backup) |
| `.viewModel` | ViewModel/presentation layer |
| `.ui` | UI/user interaction tests |

### Priority-Based Tags

| Tag | Purpose |
|-----|---------|
| `.critical` | Smoke tests for core functionality |
| `.regression` | Tests for previously fixed bugs |

## Predefined Tag Sets

Use these convenient sets for common scenarios:

```swift
// Quick smoke tests for CI
Set<TestTag>.smoke  // [.critical, .fast]

// All unit tests
Set<TestTag>.unitOnly  // [.unit, .fast]

// Integration tests with SwiftData
Set<TestTag>.integrationOnly  // [.integration, .medium]

// Model layer tests
Set<TestTag>.modelLayer  // [.model, .unit, .fast]

// Service layer tests
Set<TestTag>.serviceLayer  // [.service, .unit, .fast]
```

## Performance Monitoring

### Automatic Timeout Enforcement

Use `testWithTimeout` to automatically fail tests that exceed expected duration:

```swift
func testQuickOperation() async throws {
    try await testWithTimeout {
        // Test code here - will fail if exceeds expectedDuration
    }
}
```

Expected duration is determined by performance tags:
- `.fast` → 0.1s
- `.medium` → 1.0s
- `.slow` → 5.0s

### Custom Timeout

Override the expected duration:

```swift
func testSlowOperation() async throws {
    try await testWithTimeout(10.0) {
        // Test code with custom 10s timeout
    }
}
```

### Async Support

For Swift concurrency tests:

```swift
@MainActor
func testAsyncOperation() async throws {
    try await testWithTimeoutAsync {
        // Async test code
    }
}
```

### Performance Measurements

Measure execution time without failing:

```swift
func testOperationPerformance() throws {
    let elapsed = try measureExecution(of: "Database fetch") {
        // Operation to measure
    }
    // Logs warning if exceeds expectedDuration, but doesn't fail
}
```

### Performance Assertions

Assert specific performance requirements:

```swift
func testMustBeFast() throws {
    try assertPerformance(lessThan: 0.05, named: "Critical operation") {
        // Must complete in <50ms or test fails
    }
}
```

## Running Tests Selectively

### Via Xcode

1. Filter test navigator by test name
2. Run specific test classes or methods
3. Use test plans for custom configurations

### Via xcodebuild

Run all tests:
```bash
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Run specific test class:
```bash
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/ItemTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Run specific test method:
```bash
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/ItemTests/testDocumentationScore_AllFieldsFilled_Returns1 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

### Via Fastlane

Use the test lane:
```bash
bundle exec fastlane test
```

## Tag Examples

### Model Layer Tests

```swift
final class ItemTests: XCTestCase {
    override var tags: Set<TestTag> {
        [.fast, .unit, .model, .critical]
    }
}
```

**Rationale:**
- `.fast` - Model tests should complete in <0.1s
- `.unit` - Pure logic, no external dependencies
- `.model` - Tests model layer
- `.critical` - Core functionality for smoke tests

### Integration Tests

```swift
final class SwiftDataPersistenceTests: XCTestCase {
    override var tags: Set<TestTag> {
        [.medium, .integration, .model]
    }
}
```

**Rationale:**
- `.medium` - SwiftData operations take 0.1-1s
- `.integration` - Involves database operations
- `.model` - Tests model persistence

### Performance Tests

```swift
final class DocumentationScoreBenchmarkTests: XCTestCase {
    override var tags: Set<TestTag> {
        [.slow, .performance, .model]
    }
}
```

**Rationale:**
- `.slow` - Benchmark with 1000+ items takes >1s
- `.performance` - Measures execution time
- `.model` - Benchmarks model computations

## Best Practices

1. **Always tag test classes** - Untagged tests default to 1s timeout
2. **Be realistic with performance tags** - Use actual measured durations
3. **Mark critical paths** - Use `.critical` for smoke tests
4. **Document regressions** - Use `.regression` for bug fix tests
5. **Use `testWithTimeout` for fast tests** - Catches performance degradation early
6. **Measure before optimizing** - Use `measureExecution` to identify bottlenecks

## CI Integration

For GitHub Actions or other CI systems, run smoke tests first:

```yaml
- name: Run Smoke Tests
  run: |
    xcodebuild test \
      -project Nestory-Pro.xcodeproj \
      -scheme Nestory-Pro \
      -only-testing:Nestory-ProTests/ItemTests \
      -only-testing:Nestory-ProTests/PropertyModelTests \
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Then run full test suite:

```yaml
- name: Run Full Test Suite
  run: bundle exec fastlane test
```

## Future Enhancements

Potential additions to the tagging system:

1. **Test Plan Integration** - Create `.xctestplan` files filtered by tags
2. **Custom Reporters** - Generate tag-based test reports
3. **Dynamic Filtering** - Runtime test filtering based on tags
4. **Tag Analytics** - Track tag distribution and test execution patterns

---

**Created:** 2025-01-30
**Author:** Claude Code
**Version:** 1.0

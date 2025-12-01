# Xcode Test Plans for CI Optimization

Three test plans have been created to optimize Xcode Cloud compute usage and reduce CI time from 15min → 5min for PRs.

## Test Plans

### 1. FastTests.xctestplan (Recommended for PRs)
**Target Time:** ~5 minutes
**Purpose:** Fast feedback loop for pull requests
**Includes:**
- All unit tests (Models, Services)
- Fast integration tests (PersistenceIntegrationTests, DataModelInvariantsTests, ConcurrencyTests)

**Skips:**
- ⏱️ Performance tests (DocumentationScorePerformanceTests)
- 📸 Snapshot tests (ViewSnapshotTests, InventorySnapshotTests, ItemDetailSnapshotTests, PaywallSnapshotTests, ReportsSnapshotTests)
- 🐌 Slow integration tests (DataModelHarnessTests, ReportGeneratorOutputTests)

**Configuration:**
- Random test execution order
- 60s max per test
- No repetition

**Usage:**
```bash
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -testPlan FastTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

---

### 2. FullTests.xctestplan (Default - Nightly/Pre-Release)
**Target Time:** ~15 minutes (with parallelization)
**Purpose:** Comprehensive testing before releases
**Includes:**
- All unit tests
- All integration tests
- All performance tests

**Skips:**
- 📸 Snapshot tests only (run locally before committing UI changes)

**Configuration:**
- Random test execution order
- 300s max per test
- No repetition

**Usage:**
```bash
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -testPlan FullTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

---

### 3. CriticalPath.xctestplan (Quick Smoke Tests)
**Target Time:** ~2 minutes
**Purpose:** Rapid smoke testing for quick validation
**Includes:**
- Basic model tests (CategoryTests, RoomTests, ReceiptTests, TagTests, ItemTests, PropertyModelTests, ContainerModelTests)
- Basic service tests (KeychainManagerTests, FeedbackServiceTests, IAPValidatorTests, AppLockServiceTests, OCRServiceTests, PhotoStorageServiceTests)
- OnboardingSheetControllerTests

**Skips:**
- All performance tests
- All snapshot tests
- All integration tests
- Edge case tests (ItemEdgeCaseTests)
- Heavy service tests (BackupServiceTests, ReportGeneratorServiceTests)

**Configuration:**
- Random test execution order
- 30s max per test (fail fast)
- No repetition

**Usage:**
```bash
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -testPlan CriticalPath \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

---

## Test Coverage Summary

| Test Plan | Unit Tests | Integration Tests | Performance Tests | Snapshot Tests | Estimated Time |
|-----------|-----------|-------------------|-------------------|----------------|----------------|
| **CriticalPath** | ✅ Basic only | ❌ None | ❌ None | ❌ None | ~2 min |
| **FastTests** | ✅ All | ✅ Fast only | ❌ None | ❌ None | ~5 min |
| **FullTests** | ✅ All | ✅ All | ✅ All | ❌ None | ~15 min |

**Note:** Snapshot tests should be run locally during UI development. They are excluded from all CI test plans to avoid simulator inconsistencies.

---

## Xcode Cloud Integration

The Nestory-Pro scheme has been updated to reference all three test plans. The default plan is **FullTests** for comprehensive coverage.

### Recommended CI Strategy

1. **Pull Request Checks:** Use `FastTests` for quick feedback
2. **Main Branch Commits:** Use `FullTests` for comprehensive validation
3. **Local Development:** Use `CriticalPath` for rapid iteration

### Xcode Cloud Configuration

In your Xcode Cloud workflow:

```yaml
# .xcode-cloud/workflows/pr-validation.yml
steps:
  - name: Test
    action: test
    scheme: Nestory-Pro
    testPlan: FastTests
    destination: iPhone 17 Pro Max

# .xcode-cloud/workflows/main-validation.yml
steps:
  - name: Test
    action: test
    scheme: Nestory-Pro
    testPlan: FullTests
    destination: iPhone 17 Pro Max
```

---

## Test Organization

### Unit Tests (Nestory-ProTests/UnitTests/)
- **Models:** ItemTests, CategoryTests, RoomTests, ReceiptTests, TagTests, PropertyModelTests, ContainerModelTests, ItemEdgeCaseTests
- **Services:** OCRServiceTests, AppLockServiceTests, BackupServiceTests, ReportGeneratorServiceTests, KeychainManagerTests, IAPValidatorTests, PhotoStorageServiceTests, FeedbackServiceTests

### Integration Tests (Nestory-ProTests/IntegrationTests/)
- **Fast:** PersistenceIntegrationTests, DataModelInvariantsTests, ConcurrencyTests
- **Slow:** DataModelHarnessTests, ReportGeneratorOutputTests

### Performance Tests (Nestory-ProTests/PerformanceTests/)
- DocumentationScorePerformanceTests

### Snapshot Tests (Nestory-ProTests/SnapshotTests/)
- ViewSnapshotTests (InventorySnapshotTests, ItemDetailSnapshotTests, PaywallSnapshotTests, ReportsSnapshotTests)

---

## Files Created

- `/Users/griffin/Projects/Nestory/Nestory-Pro/FastTests.xctestplan`
- `/Users/griffin/Projects/Nestory/Nestory-Pro/FullTests.xctestplan`
- `/Users/griffin/Projects/Nestory/Nestory-Pro/CriticalPath.xctestplan`

The Nestory-Pro scheme has been updated to reference all three test plans with FullTests as the default.

# Xcode Cloud Test Optimization Strategy

**Goal:** Reduce compute hours from ~48.8/month to under 25/month (free tier)

## Current Situation

**Test Suite:**
- 30 test files
- 413 test functions
- Categories: Unit (70%), Integration (20%), Performance (5%), Snapshot (5%)

**Projected Monthly Usage (Before Optimization):**
- PR Validation: 15 min × 20 PRs = 5.0 hours
- Main Branch: 25 min × 30 commits = 12.5 hours
- Nightly: 60 min × 30 days = 30.0 hours
- Release: 40 min × 2 releases = 1.3 hours
- **Total: 48.8 hours** ❌ (Exceeds free tier by 95%)

## Optimization Strategies

### 1. Parallel Test Execution ⚡️

**Impact:** Reduce test time by 60-70%

Xcode Cloud can run tests in parallel across multiple simulators. Split tests into:
- **Fast Tests** (<1s each): Unit tests, model tests
- **Medium Tests** (1-5s): Integration tests, service tests
- **Slow Tests** (>5s): Performance tests, UI tests

**Implementation:**
```swift
// XCTestCase+Tags.swift
extension XCTestCase {
    var tags: [String] {
        []  // Override in subclasses
    }
}

// Fast test example
class ItemTests: XCTestCase {
    override var tags: [String] { ["fast", "unit", "model"] }
}

// Slow test example
class PerformanceTests: XCTestCase {
    override var tags: [String] { ["slow", "performance"] }
}
```

**Test Plans:**
1. `FastTests.xctestplan` - Unit + fast integration (~5 min)
2. `FullTests.xctestplan` - All tests (~15 min with parallelization)
3. `CriticalPath.xctestplan` - Smoke tests only (~2 min)

### 2. Selective Test Execution 🎯

**Impact:** Reduce PR validation from 15 min → 5 min

Run different test suites based on trigger:

| Trigger | Tests | Time | Devices |
|---------|-------|------|---------|
| **PR Open/Update** | Fast + Critical | 5 min | iPhone 17 Pro Max only |
| **Main Branch** | Full suite | 12 min | iPhone 17 Pro Max, iPhone SE |
| **Pre-Release Tag** | Full + Performance | 20 min | All supported devices |
| **Nightly** | DISABLED | 0 min | - |

**Savings:**
- PR: 15 min → 5 min (10 min saved × 20 = 200 min = 3.3 hours)
- Nightly: 60 min × 30 = 30 hours → 0 hours (eliminated)
- **Total saved: 33.3 hours/month**

### 3. Test Plan Configuration

**FastTests.xctestplan:**
```json
{
  "configurations": [{
    "name": "Fast Tests",
    "options": {
      "testExecutionOrdering": "random",
      "testRepetitionMode": "none",
      "maximumTestExecutionTimeAllowance": 60
    }
  }],
  "testTargets": [{
    "target": {
      "containerPath": "Nestory-Pro.xcodeproj",
      "identifier": "Nestory-ProTests",
      "name": "Nestory-ProTests"
    },
    "skippedTests": [
      "PerformanceTests",
      "ViewSnapshotTests",
      "DataModelHarnessTests/testLargeDataset*"
    ]
  }]
}
```

### 4. Caching & Build Optimization 💾

**Swift Package Dependencies:**
- Xcode Cloud automatically caches SPM packages
- First build: ~2 min, subsequent: ~30s
- **Savings: ~1.5 min per build**

**DerivedData Caching:**
```bash
# ci_scripts/ci_post_clone.sh
# Restore build cache if available
if [ -d "$CI_DERIVED_DATA_PATH" ]; then
    echo "Using cached DerivedData"
fi
```

### 5. Fail Fast Configuration ⚠️

Stop on first failure for PR validation:

```swift
// Nestory-ProTests/XCTestCase+FailFast.swift
extension XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = ProcessInfo.processInfo.environment["CI_WORKFLOW"] != "PR Validation"
    }
}
```

**Impact:** Failed PR tests stop after first failure (~30s vs 5 min)

### 6. Optimize Test Fixtures 🔧

**Current Issue:** Creating full test data for each test

**Optimized Approach:**
```swift
// Lazy fixture creation
class TestFixtures {
    private static var sharedContainer: ModelContainer?

    static func shared() -> ModelContainer {
        if sharedContainer == nil {
            sharedContainer = TestContainer.withBasicData()
        }
        return sharedContainer!
    }

    static func reset() {
        sharedContainer = nil
    }
}

// Usage in tests
class ItemTests: XCTestCase {
    override class func tearDown() {
        TestFixtures.reset()  // Reset once per test class
    }

    func testDocumentationScore() {
        let container = TestFixtures.shared()  // Reuse across tests
        // ...
    }
}
```

**Impact:** Reduce fixture creation from 413 times → ~30 times (per test class)

### 7. Remove Redundant Tests 🗑️

**Audit Needed:**
- Duplicate coverage between unit + integration tests
- Over-specified edge cases
- Tests that verify framework behavior (not our code)

**Example Candidates:**
```swift
// REMOVE: Testing Swift/SwiftData behavior
func testRoom_HasUniqueUUID_OnCreation() {
    // UUID() always creates unique IDs - this is Swift stdlib behavior
}

// REMOVE: Duplicate of persistence test
func testRoom_PersistsCorrectly() {
    // Already covered by PersistenceIntegrationTests
}

// KEEP: Business logic
func testRoom_DeleteRoom_NullifiesItems() {
    // Tests our relationship configuration
}
```

**Target:** Reduce from 413 → ~300 tests (27% reduction)

### 8. Xcode Cloud Workflow Configuration

**Optimized Workflows:**

#### PR Validation (5 min, ~20/month = 1.7 hours)
```yaml
start_condition: pull_request
environment:
  xcode: 15.0
  macos: 14.0
actions:
  - name: Test
    test_plan: FastTests
    platform: iOS Simulator
    destination: iPhone 17 Pro Max, iOS 18.0
    disable_performance_testing: true
post_actions:
  - name: Post Status to GitHub
```

#### Main Branch (12 min, ~30/month = 6.0 hours)
```yaml
start_condition: branch_push(main)
environment:
  xcode: 15.0
  macos: 14.0
actions:
  - name: Test
    test_plan: FullTests
    platform: iOS Simulator
    destinations:
      - iPhone 17 Pro Max, iOS 18.0
      - iPhone SE (3rd gen), iOS 17.0
    parallelize: true
  - name: Archive
    scheme: Nestory-Pro-Beta
post_actions:
  - name: Deploy to TestFlight (Internal)
```

#### Pre-Release (20 min, ~2/month = 0.7 hours)
```yaml
start_condition: tag(v*)
environment:
  xcode: 15.0
  macos: 14.0
actions:
  - name: Test
    test_plan: FullTests
    platform: iOS Simulator
    destinations:
      - iPhone 17 Pro Max, iOS 18.0
      - iPhone 17 Pro, iOS 18.0
      - iPhone SE (3rd gen), iOS 17.0
      - iPad Pro 12.9", iOS 18.0
    parallelize: true
  - name: Archive
    scheme: Nestory-Pro-Release
post_actions:
  - name: Deploy to TestFlight (External)
```

### 9. Test Execution Time Budget

**Allocated per test type:**
- Unit tests: <0.1s each (target: <30s total for all unit tests)
- Integration tests: <1s each (target: <2 min total)
- Performance tests: <5s each (only on release builds)
- Snapshot tests: SKIP on CI (local only, or weekly job)

**Enforce with timeout:**
```swift
// XCTestCase+Timeout.swift
extension XCTestCase {
    func testWithTimeout(_ timeout: TimeInterval = 0.1, _ block: () throws -> Void) rethrows {
        let start = Date()
        try block()
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, timeout, "Test exceeded \(timeout)s timeout")
    }
}

// Usage
func testDocumentationScore() {
    testWithTimeout(0.05) {
        let item = TestFixtures.testItem()
        XCTAssertEqual(item.documentationScore, 0.0)
    }
}
```

### 10. Monitoring & Alerts

**Track compute usage:**
```bash
# Scripts/xc-cloud-usage.sh
#!/bin/bash
# Fetch build history and calculate monthly usage

source Scripts/xc-env.sh

# Get all builds for current month
BUILDS=$(./Scripts/xcodecloud.sh list-builds --month $(date +%m))

# Calculate total minutes
TOTAL_MINUTES=$(echo "$BUILDS" | jq '[.[] | .attributes.executionTime] | add')

echo "Xcode Cloud Usage This Month:"
echo "  Total: $(echo "scale=1; $TOTAL_MINUTES / 60" | bc) hours"
echo "  Free tier: 25 hours"
echo "  Remaining: $(echo "scale=1; 25 - ($TOTAL_MINUTES / 60)" | bc) hours"
```

**Alert when >20 hours used:**
```bash
# Add to ci_scripts/ci_post_xcodebuild.sh
if [ "$MONTHLY_USAGE" -gt 20 ]; then
    echo "⚠️  WARNING: Approaching monthly limit (${MONTHLY_USAGE}/25 hours)"
fi
```

## Projected Savings

### Before Optimization
| Workflow | Time | Frequency | Monthly Hours |
|----------|------|-----------|---------------|
| PR Validation | 15 min | 20 | 5.0 |
| Main Branch | 25 min | 30 | 12.5 |
| Nightly | 60 min | 30 | 30.0 |
| Release | 40 min | 2 | 1.3 |
| **TOTAL** | | | **48.8** ❌ |

### After Optimization
| Workflow | Time | Frequency | Monthly Hours |
|----------|------|-----------|---------------|
| PR Validation (Fast) | 5 min | 20 | 1.7 |
| Main Branch (Parallel) | 12 min | 30 | 6.0 |
| Nightly | DISABLED | 0 | 0.0 |
| Release (Full) | 20 min | 2 | 0.7 |
| **TOTAL** | | | **8.4** ✅ |

**Savings: 40.4 hours/month (83% reduction)**

**Margin:** 16.6 hours remaining for ad-hoc builds

## Implementation Checklist

- [ ] Create test plans (FastTests, FullTests, CriticalPath)
- [ ] Add test tags to all test classes
- [ ] Optimize test fixtures (shared containers)
- [ ] Audit and remove redundant tests
- [ ] Configure Xcode Cloud workflows via API
- [ ] Add fail-fast for PR validation
- [ ] Implement test timeout enforcement
- [ ] Disable nightly builds
- [ ] Create usage monitoring script
- [ ] Document for team in CLAUDE.md

## Maintenance

**Monthly Review:**
1. Check actual usage vs projected
2. Identify slowest tests (>1s)
3. Review failed test patterns
4. Adjust test plans as needed

---

**Last Updated:** November 30, 2025
**Target:** <25 hours/month
**Current Projection:** 8.4 hours/month ✅

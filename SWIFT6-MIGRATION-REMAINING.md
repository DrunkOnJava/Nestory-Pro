# Swift 6 Test Migration - Remaining Work

## Status: Partially Complete (v1.1 - Phase 1)

### ✅ Completed

1. **xcconfig Configuration** - Fixed test target isolation
   - `Config/Tests.xcconfig`: Added `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`
   - `Config/UITests.xcconfig`: Added `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`
   - **Reason**: XCTestCase lifecycle methods (init, setUp, tearDown) are nonisolated and conflict with MainActor default isolation

2. **Project Regeneration**
   - Ran `xcodegen generate` to apply xcconfig changes
   - All targets now use correct actor isolation settings

3. **Test Files with async/MainActor.run Wrappers** (from previous session + this session)
   - ✅ IAPValidatorTests.swift - Complete rewrite with async/MainActor.run pattern
   - ✅ DocumentationScorePerformanceTests.swift - Lazy initialization pattern for class-level setUp
   - ✅ RoomTests.swift - All tests wrapped
   - ✅ CategoryTests.swift - All tests wrapped
   - ✅ ItemTests.swift - All tests wrapped
   - ✅ ItemEdgeCaseTests.swift - All tests wrapped
   - ✅ ReceiptTests.swift - All tests wrapped
   - ✅ AppLockServiceTests.swift - All tests wrapped
   - ✅ BackupServiceTests.swift - All tests wrapped
   - ✅ KeychainManagerTests.swift - All tests wrapped
   - ✅ ReportGeneratorServiceTests.swift - All tests wrapped
   - ✅ ConcurrencyTests.swift - All tests wrapped
   - ✅ DataModelHarnessTests.swift - All tests wrapped
   - ✅ DataModelInvariantsTests.swift - All tests wrapped
   - ✅ PersistenceIntegrationTests.swift - All tests wrapped

### ⚠️ Remaining Issues (2 files)

#### 1. OCRServiceTests.swift (40+ errors)

**Problem**: MainActor-isolated properties accessed in XCTAssert autoclosures

**Errors**:
```
error: main actor-isolated property 'purchaseDate' can not be referenced from a nonisolated autoclosure
error: main actor-isolated property 'total' can not be referenced from a nonisolated autoclosure
error: main actor-isolated property 'taxAmount' can not be referenced from a nonisolated autoclosure
error: main actor-isolated property 'vendor' can not be referenced from a nonisolated autoclosure
```

**Affected Lines**: 62, 65, 85, 88, 108, 111, 131, 134, 152, 169, 170, 185, 186, 203, 204, 219, 220, 235, 236, 251, 252, 267, 286, 287, 304, 305, 322, 323, 340, 341, 358, 359, 374, 395...

**Solution Pattern**:
```swift
// BEFORE (causes error):
func testSomething() async throws {
    let result = try await parseReceiptFromText(text)
    XCTAssertNotNil(result.purchaseDate, "...") // ❌ MainActor property in autoclosure
}

// AFTER (correct):
func testSomething() async throws {
    try await MainActor.run {
        let result = try parseReceiptFromText(text)
        let purchaseDate = result.purchaseDate  // ✅ Extract property
        XCTAssertNotNil(purchaseDate, "...")    // ✅ Use local variable
    }
}
```

**Required Changes**:
- Wrap all 31 test method bodies in `try await MainActor.run {}`
- Extract `result.purchaseDate`, `result.total`, `result.taxAmount`, `result.vendor` to local variables before XCTAssert calls
- Change `try await parseReceiptFromText()` to `try parseReceiptFromText()` (already inside MainActor.run)

#### 2. ViewSnapshotTests.swift (16 errors)

**Problem**: Calling `@MainActor` helper methods on `self` from nonisolated async context causes data race warnings

**Errors**:
```
error: sending 'self' risks causing data races
```

**Affected Lines**: 45, 58, 71, 84, 109, 131, 151, 168, 182, 196, 210, 224, 238, 256, 269, 282

**Solution Pattern**:
```swift
// BEFORE (causes error):
func testInventoryList_Empty() async {
    await MainActor.run {
        let container = PreviewContainer.emptyInventory()
        assertViewSnapshot(...)  // ❌ Implicitly calls self.assertViewSnapshot from MainActor.run
    }
}

// AFTER (correct):
@MainActor  // ✅ Mark entire method as MainActor
func testInventoryList_Empty() {
    let container = PreviewContainer.emptyInventory()
    assertViewSnapshot(...)  // ✅ Safe - method is @MainActor
}
```

**Required Changes**:
- Remove `async` keyword from test methods (they don't await anything except MainActor.run)
- Add `@MainActor` attribute to all test methods
- Remove `await MainActor.run {}` wrappers
- Methods affected: All 16 test methods in InventorySnapshotTests, ItemDetailSnapshotTests, PaywallSnapshotTests, ReportsSnapshotTests

### 🔄 Next Session Tasks

1. **Fix OCRServiceTests.swift**
   - Apply the pattern to all 31 test methods
   - Automated script approach failed (broke file structure), requires manual editing
   - Estimate: 30-45 minutes

2. **Fix ViewSnapshotTests.swift**
   - Convert all test methods from `async + await MainActor.run {}` to `@MainActor`
   - Simpler transformation than OCRServiceTests
   - Estimate: 15-20 minutes

3. **Rebuild and Verify**
   - `xcodebuild clean build-for-testing ...`
   - Verify zero errors
   - Run tests: `xcodebuild test ...`

4. **Record Baseline Snapshots** (Table 3.3: Tasks 9.3.1-9.3.4)
   - Set `isRecording = true` in snapshot tests
   - Run snapshot tests to generate baseline images
   - Commit baseline images to git

5. **Final Commit**
   - Commit all Swift 6 migration fixes
   - Update TODO.md to mark Phase 1 complete

### 📝 Notes

- **Why automated scripts failed**: Complex AST manipulation required for OCRServiceTests (30+ methods with varied assertion patterns). Python regex approach was too fragile for Swift syntax.

- **Manual approach recommended**: Use Edit tool with careful verification for each batch of 5-10 test methods.

- **Testing strategy**: After fixing each file, run `swift build` to verify syntax before moving to next file.

- **Context from previous session**: Most test files were already migrated with async/MainActor.run wrappers in a previous session. This session focused on xcconfig fixes and the remaining problematic files.

### 🎯 Success Criteria

- ✅ All tests compile with `SWIFT_STRICT_CONCURRENCY = complete`
- ✅ Zero actor isolation errors
- ✅ Zero data race warnings
- ✅ All existing tests pass
- ✅ Snapshot baselines recorded for v1.1

---

**Last Updated**: 2025-11-29 (Session ended at context limit)
**Next Session**: Continue from "Fix OCRServiceTests.swift"

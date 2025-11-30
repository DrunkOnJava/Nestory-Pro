# Swift 6 Test Migration - Remaining Work

## Status: In Progress (v1.1 - Phase 1)

**Last Updated**: 2025-11-30 02:47 UTC

### 🔴 Remaining Compilation Errors

#### 1. OCRServiceTests.swift (~40 property access errors)

**Problem**: Test methods access `sut` property (OCRService actor) from nonisolated context.

**File**: `Nestory-ProTests/UnitTests/Services/OCRServiceTests.swift`

**Error Pattern**:
```swift
var sut: OCRService!  // MainActor-isolated property

func testProcessReceipt_DateFormat...() async throws {
    // ERROR: Main actor-isolated property 'sut' can not be referenced from a nonisolated context
    let result = try await parseReceiptFromText(receiptText)
}
```

**Fix Required**:
- Mark all test methods `@MainActor` OR
- Make `sut` access async-safe with `await MainActor.run {}`
- Note: The tests don't actually use `sut` - they use local helper methods. Remove unused `sut` property.

#### 2. ViewSnapshotTests.swift (16 data race errors)

**Problem**: PreviewContainer methods are MainActor-isolated but called from test context.

**File**: `Nestory-ProTests/SnapshotTests/ViewSnapshotTests.swift`

**Error Pattern**:
```swift
@MainActor func testInventoryList_Empty() {
    let container = PreviewContainer.emptyInventory()  // MainActor call
    // ...
}
```

**Fix Required**:
- Ensure PreviewContainer methods are properly isolated
- Tests already marked `@MainActor` - verify helper functions match

---

### ✅ Previously Completed

1. **xcconfig Configuration** - Fixed test target isolation
   - `Config/Tests.xcconfig`: `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`
   - `Config/UITests.xcconfig`: `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`

2. **App Module Value Type Fixes** (Swift 6 `nonisolated` structs/enums)
   - ✅ `ReceiptData`, `BiometricType`, `BackupData`
   - ✅ `ItemExport`, `CategoryExport`, `RoomExport`, `ReceiptExport`
   - ✅ `ImportResult`, `RestoreResult`, `ImportError`, `ZIPRestoreResult`
   - ✅ `BackupCodableHelper`

3. **TestFixtures Fixes**
   - ✅ Date properties marked `nonisolated static`

4. **Test Files Previously Fixed**
   - ✅ ReportGeneratorServiceTests.swift
   - ✅ ConcurrencyTests.swift
   - ✅ KeychainManagerTests.swift
   - ✅ DocumentationScorePerformanceTests.swift
   - ✅ ItemEdgeCaseTests.swift
   - ✅ DataModelHarnessTests.swift

---

### 🔄 Next Steps

1. **Fix OCRServiceTests.swift**
   - Remove unused `sut` property (tests use local helper methods)
   - Or mark test class `@MainActor` if sut is needed

2. **Fix ViewSnapshotTests.swift**
   - Verify PreviewContainer isolation matches test isolation
   - Check assertViewSnapshot/assertMultiDeviceSnapshot helper isolation

3. **Rebuild and Verify**
   ```bash
   xcodebuild build-for-testing -scheme Nestory-Pro -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -quiet
   ```

4. **Record Baseline Snapshots (9.3.1-9.3.4)**
   - Set `isRecording = true` in snapshot tests
   - Run tests to generate baselines
   - Commit baseline images

---

### 📝 Key Swift 6 Migration Patterns

1. **Value types in MainActor app**: Use `nonisolated struct/enum` for Sendable value types
2. **Test methods accessing MainActor state**: Use `@MainActor func test...()`
3. **setUp/tearDown with MainActor APIs**: Use `async throws` with `await MainActor.run {}`
4. **XCTAssert with MainActor properties**: Extract to local variable first
5. **SwiftData models**: Keep all operations on MainActor

### 🎯 Success Criteria

- ⏳ All tests compile with `SWIFT_STRICT_CONCURRENCY = complete`
- ⏳ Zero actor isolation errors
- ⏳ Zero data race warnings  
- ⏳ All existing tests pass
- ⏳ Snapshot baselines recorded for v1.1

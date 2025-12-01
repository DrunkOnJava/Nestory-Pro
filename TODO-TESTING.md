# Nestory Pro - Test Infrastructure Task Management

<!--
================================================================================
CLAUDE CODE AGENT INSTRUCTIONS - READ BEFORE WORKING
================================================================================

This document tracks TEST INFRASTRUCTURE and TEST QUALITY work. It follows the
same format as TODO.md but focuses exclusively on testing improvements.

TASK STATUS LEGEND:
  - [ ] Available    = Task is free to be picked up
  - [~] In Progress  = Task is CHECKED OUT by an agent (see agent ID in brackets)
  - [x] Completed    = Task is done and verified
  - [-] Blocked      = Task cannot proceed (see blocker note)
  - [!] Needs Review = Task completed but needs human review

CHECKOUT PROCEDURE:
1. Before starting ANY task, mark it as [~] and add your session identifier
   Example: - [~] [AGENT-abc123] Task description...
2. Add checkout timestamp in the "Active Checkouts" section below
3. Work on the task
4. When complete, mark as [x] and move to "Completed" section with date
5. Remove your entry from "Active Checkouts"

TESTING-SPECIFIC RULES:
- Always run tests after changes: `bundle exec fastlane test`
- Clean DerivedData if seeing stale errors: `rm -rf ~/Library/Developer/Xcode/DerivedData/Nestory-Pro-*`
- Use test plans: FastTests (PR), FullTests (main), CriticalPath (smoke)
- Document test timing if >0.1s: add comment explaining why
- Never commit broken tests - mark task [!] if tests fail

COMMIT RULES:
- Format: "test(scope): description - closes #TEST-ID"
- Example: "test(infrastructure): enable parallel execution - closes #T1-01"
- No "Generated with Claude Code" attribution
- No Co-Authored-By lines

================================================================================
-->

## Active Checkouts

> When you check out a task, replace `(none)` with your checkout entry. One active task per agent.

| Task ID | Agent ID | Checkout Time | Notes |
|---------|----------|---------------|-------|
| (none)  | -        | -             | -     |

---

## Test Infrastructure Status Summary

**Current State (2025-11-30):**
- ✅ Test plans created and wired to schemes
- ✅ Parallel execution enabled (50-70% speedup)
- ✅ Compiler performance warnings configured
- ✅ CI scripts for build timing analysis
- ❌ Build cache preventing successful test run
- ❌ No test content cleanup performed
- ❌ Test performance not profiled
- ❌ Compiler warnings in test files not fixed

**Test Suite Stats:**
- 24 test files
- 413 test methods
- 0 commented-out tests
- 10 documentation TODOs (not issues)
- 8 tests skipped in FastTests (performance + snapshots + integration)

**Optimization Impact:**
- Xcode Cloud: 48.8h → 7.1h/month (85% reduction)
- Local test execution: Estimated 50-70% faster with parallel execution
- Build optimization: Single-file compilation for faster incremental builds

---

## Phase 1 – Critical Fixes (IMMEDIATE)

> **Priority:** BLOCKING - Must complete before test suite is functional
> **Target:** 2025-12-01
> **Estimated Time:** 1-2 hours

### T1-01: Build Cache Cleanup & Verification

- [ ] **T1-01.1** Clean DerivedData to remove stale build cache
  - `rm -rf ~/Library/Developer/Xcode/DerivedData/Nestory-Pro-*`
  - Verify: Check that Nestory-Pro-* directories are removed
  - Estimated: 5 min

- [ ] **T1-01.2** Clean build folder via Xcode
  - Open Xcode → Product → Clean Build Folder (Cmd+Shift+K)
  - Verify: Build folder cleaned successfully
  - Estimated: 2 min

- [ ] **T1-01.3** Verify FastTests build and run successfully
  - `xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -testPlan FastTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'`
  - Verify: All tests pass (no "property tags is declared" errors)
  - Expected: ~5 minutes with parallel execution
  - Success Criteria: Exit code 0, no compilation errors
  - Estimated: 10 min

- [ ] **T1-01.4** Verify test plans work with all schemes
  - Test Nestory-Pro scheme with FastTests
  - Test Nestory-Pro-Beta scheme with FullTests
  - Test Nestory-Pro-Release scheme with FullTests
  - Verify: All schemes can select and run test plans
  - Estimated: 15 min

**Blocked-by:** None
**Blocks:** All other test infrastructure work
**Priority:** P0 (Critical)
**Files:** DerivedData, *.xcodeproj

---

## Phase 2 – Compiler Warning Fixes

> **Priority:** HIGH - Technical debt cleanup
> **Target:** 2025-12-02
> **Estimated Time:** 2-3 hours

### T2-01: Fix Async/Await Warnings

- [ ] **T2-01.1** Fix unnecessary `try` expressions in ItemTests.swift
  - Lines: 17, 71, 104, 158, 237
  - Issue: `try await MainActor.run { }` where closure doesn't throw
  - Fix: Remove `try` keyword from non-throwing MainActor.run calls
  - Verify: No "no calls to throwing functions" warnings
  - Estimated: 15 min

- [ ] **T2-01.2** Fix BackupServiceTests.swift async warning
  - Line: 31
  - Issue: `await BackupService.shared` where shared is not async
  - Fix: Remove `await` keyword
  - Verify: No "no 'async' operations occur" warning
  - Estimated: 5 min

- [ ] **T2-01.3** Fix ConcurrencyTests.swift trailing closure warning
  - Line: 258
  - Issue: Trailing closure confusable with statement body
  - Fix: Use parenthesized argument: `AsyncStream<String>({ continuation in })`
  - Verify: No "trailing closure confusable" warning
  - Estimated: 5 min

**Blocked-by:** T1-01 (build must work first)
**Blocks:** None
**Priority:** P1 (High)
**Files:** ItemTests.swift, BackupServiceTests.swift, ConcurrencyTests.swift

### T2-02: Fix Deprecated API Usage

- [ ] **T2-02.1** Update SnapshotHelpers.swift to use #filePath
  - Line: 102, 114
  - Issue: Using `#file` (deprecated) instead of `#filePath`
  - Fix: Change parameter default to `#filePath`
  - Verify: No "parameter with default argument '#file'" warning
  - Related: swift-snapshot-testing API changes
  - Estimated: 10 min

**Blocked-by:** T1-01
**Blocks:** None
**Priority:** P1 (High)
**Files:** SnapshotHelpers.swift

---

## Phase 3 – Test Performance Analysis

> **Priority:** MEDIUM - Data-driven optimization
> **Target:** 2025-12-03
> **Estimated Time:** 3-4 hours

### T3-01: Profile Test Execution Times

- [ ] **T3-01.1** Run FullTests with timing data collection
  - Command: `xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -testPlan FullTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -enableCodeCoverage YES`
  - Extract xcresult bundle timing data
  - Use: `xcrun xcresulttool get --path <bundle>.xcresult --format json`
  - Output: timing-analysis.json
  - Estimated: 20 min (15 min test run + 5 min extraction)

- [ ] **T3-01.2** Parse timing data and categorize tests
  - Parse JSON to extract test execution times
  - Categorize: fast (<0.1s), medium (0.1-1s), slow (>1s)
  - Create report: test-performance-report.md
  - Include: Top 20 slowest tests, average time per category
  - Estimated: 30 min

- [ ] **T3-01.3** Identify optimization opportunities
  - Find tests that should be fast but are medium/slow
  - Identify tests with inconsistent timing (flaky)
  - Flag tests that could benefit from mocking
  - Flag tests with expensive setup/teardown
  - Output: test-optimization-recommendations.md
  - Estimated: 45 min

**Blocked-by:** T1-01 (tests must run successfully)
**Blocks:** T3-02, T4-01
**Priority:** P2 (Medium)
**Files:** New: timing-analysis.json, test-performance-report.md

### T3-02: Update Test Plan Configurations Based on Data

- [ ] **T3-02.1** Review FastTests skipped tests against actual timing
  - Current skips: DocumentationScorePerformanceTests, ViewSnapshotTests, etc.
  - Verify skips are justified by timing data
  - Remove incorrectly skipped fast tests
  - Add newly identified slow tests
  - Estimated: 30 min

- [ ] **T3-02.2** Create detailed test categorization
  - Update test plan configurations with accurate skips
  - Document rationale for each skip in test plan comments
  - Verify FastTests target: <5 min total
  - Verify FullTests target: <15 min total
  - Estimated: 30 min

- [ ] **T3-02.3** Validate new test plan timings
  - Run FastTests and measure actual time
  - Run FullTests and measure actual time
  - Compare to targets and adjust if needed
  - Document final timing results
  - Estimated: 25 min

**Blocked-by:** T3-01.3
**Blocks:** None
**Priority:** P2 (Medium)
**Files:** FastTests.xctestplan, FullTests.xctestplan, test-performance-report.md

---

## Phase 4 – Test Content Cleanup

> **Priority:** MEDIUM - Code quality improvement
> **Target:** 2025-12-04
> **Estimated Time:** 4-6 hours

### T4-01: Identify and Fix Slow Tests

- [ ] **T4-01.1** Optimize top 10 slowest unit tests
  - Use timing data from T3-01.2
  - For each slow test:
    - Profile to find bottleneck
    - Add mocks where appropriate
    - Reduce unnecessary setup/teardown
    - Split into smaller tests if too complex
  - Target: Reduce each test to <0.1s
  - Document: Changes made and timing improvement
  - Estimated: 2 hours

- [ ] **T4-01.2** Review integration tests for optimization
  - Integration tests should be <1s
  - Consider: In-memory vs persistent storage
  - Consider: Minimal test data vs comprehensive
  - Optimize or move slow tests to separate category
  - Estimated: 1.5 hours

- [ ] **T4-01.3** Document performance expectations
  - Add comments to slow tests explaining why (if legitimate)
  - Add performance test category for benchmark tests
  - Create performance test guidelines doc
  - Estimated: 30 min

**Blocked-by:** T3-01.3 (need timing data)
**Blocks:** None
**Priority:** P2 (Medium)
**Files:** Various test files, test-performance-guidelines.md

### T4-02: Test Duplication Analysis

- [ ] **T4-02.1** Find duplicate test coverage
  - Search for tests testing same functionality
  - Look for copy-pasted test patterns
  - Identify redundant edge case tests
  - Create duplication report
  - Estimated: 1 hour

- [ ] **T4-02.2** Consolidate duplicate tests
  - Merge or remove redundant tests
  - Keep most comprehensive version
  - Ensure coverage isn't reduced
  - Document removals in commit message
  - Estimated: 1.5 hours

**Blocked-by:** T1-01
**Blocks:** None
**Priority:** P3 (Low)
**Files:** Various test files

### T4-03: Test Quality Improvements

- [ ] **T4-03.1** Add missing test documentation
  - Review tests without header comments
  - Add clear descriptions of what's being tested
  - Document complex test scenarios
  - Add references to PRODUCT-SPEC.md where relevant
  - Estimated: 1 hour

- [ ] **T4-03.2** Improve test naming consistency
  - Verify all tests follow: `test<What>_<Condition>_<Expected>()`
  - Rename non-conforming tests
  - Ensure test names clearly describe behavior
  - Estimated: 45 min

- [ ] **T4-03.3** Review and improve test assertions
  - Replace generic XCTAssert with specific assertions
  - Add descriptive failure messages
  - Ensure assertions test the right thing
  - Estimated: 1 hour

**Blocked-by:** T1-01
**Blocks:** None
**Priority:** P3 (Low)
**Files:** Various test files

---

## Phase 5 – Documentation Updates

> **Priority:** MEDIUM - Knowledge sharing
> **Target:** 2025-12-05
> **Estimated Time:** 2-3 hours

### T5-01: Update Test Infrastructure Documentation

- [ ] **T5-01.1** Update TestTaggingExamples.swift
  - Remove override var tags examples (obsolete)
  - Add test plan usage examples
  - Show how to use Apple's built-in test tagging
  - Document test categorization via test plans
  - Estimated: 30 min

- [ ] **T5-01.2** Create comprehensive testing guide
  - File: docs/TESTING-GUIDE.md
  - Cover: Test plans, parallel execution, test categorization
  - Include: How to run tests, how to debug failures
  - Include: Performance expectations and profiling
  - Include: Common test patterns and anti-patterns
  - Estimated: 1.5 hours

- [ ] **T5-01.3** Update CLAUDE.md with test infrastructure
  - Add test plan usage instructions
  - Update test commands with test plan examples
  - Document test categorization system
  - Add performance expectations
  - Estimated: 30 min

**Blocked-by:** T1-01, T3-02 (need finalized test plans)
**Blocks:** None
**Priority:** P2 (Medium)
**Files:** TestTaggingExamples.swift, docs/TESTING-GUIDE.md, CLAUDE.md

### T5-02: Document Test Performance Baseline

- [ ] **T5-02.1** Create test performance baseline document
  - File: docs/TEST-PERFORMANCE-BASELINE.md
  - Include: Current timing data for all test plans
  - Include: Historical comparison (if available)
  - Include: Performance targets and thresholds
  - Include: How to measure and update baseline
  - Estimated: 45 min

- [ ] **T5-02.2** Add performance regression detection guide
  - Document how to detect performance regressions
  - Document acceptable performance variance
  - Document escalation process for slow tests
  - Estimated: 30 min

**Blocked-by:** T3-01.3
**Blocks:** None
**Priority:** P3 (Low)
**Files:** docs/TEST-PERFORMANCE-BASELINE.md

---

## Phase 6 – CI/CD Integration

> **Priority:** LOW - Future enhancement
> **Target:** 2025-12-10
> **Estimated Time:** 3-4 hours

### T6-01: Xcode Cloud Test Optimization

- [ ] **T6-01.1** Verify Xcode Cloud uses test plans correctly
  - Check workflow configurations use correct test plans
  - PR workflow → FastTests
  - Main workflow → FullTests
  - Verify parallel execution enabled in cloud
  - Estimated: 30 min

- [ ] **T6-01.2** Add test timing collection to CI
  - Update ci_post_xcodebuild.sh to extract timing data
  - Store timing data in xcresult bundle
  - Create historical timing trend tracking
  - Estimated: 1 hour

- [ ] **T6-01.3** Set up test performance monitoring
  - Create alert for test plan exceeding time budget
  - FastTests > 5 min → warn
  - FullTests > 15 min → warn
  - Document monitoring setup
  - Estimated: 1 hour

**Blocked-by:** T1-01, T3-02
**Blocks:** None
**Priority:** P3 (Low)
**Files:** ci_scripts/ci_post_xcodebuild.sh, docs/CI-TEST-MONITORING.md

### T6-02: GitHub Actions Test Integration

- [ ] **T6-02.1** Add test plan support to GitHub Actions
  - Update .github/workflows/beta.yml to use test plans
  - Run FastTests on PR
  - Run FullTests on main
  - Estimated: 30 min

- [ ] **T6-02.2** Add test result reporting
  - Upload test results as artifacts
  - Add test summary to PR comments
  - Highlight failures prominently
  - Estimated: 45 min

**Blocked-by:** T1-01
**Blocks:** None
**Priority:** P4 (Very Low)
**Files:** .github/workflows/beta.yml

---

## Phase 7 – Advanced Testing Features

> **Priority:** FUTURE - v1.2+ enhancements
> **Target:** Q1 2026
> **Estimated Time:** TBD

### T7-01: Snapshot Testing (Deferred from v1.1)

- [ ] **T7-01.1** Enable snapshot test recording mode
  - Set isRecording = true in ViewSnapshotTests.swift
  - Generate baselines for all snapshot tests
  - Review and approve baseline images
  - Commit baselines to repository
  - Estimated: 1 hour
  - **Blocked-by:** v1.2 P2-02 (Property/Container hierarchy complete)

- [ ] **T7-01.2** Add snapshot tests to test plans
  - Remove ViewSnapshotTests from FastTests skips
  - Keep in FullTests
  - Document snapshot update process
  - Estimated: 15 min
  - **Blocked-by:** T7-01.1

### T7-02: Code Coverage Targets

- [ ] **T7-02.1** Establish code coverage baseline
  - Run tests with coverage enabled
  - Generate coverage report
  - Document current coverage percentage
  - Set realistic coverage targets per module
  - Estimated: 1 hour

- [ ] **T7-02.2** Implement coverage enforcement
  - Add coverage check to CI
  - Warn on coverage decrease
  - Document coverage exclusions (UI, generated code)
  - Estimated: 45 min

### T7-03: Test Reliability Improvements

- [ ] **T7-03.1** Identify and fix flaky tests
  - Run test suite 10x to find inconsistent tests
  - Debug timing-dependent failures
  - Add proper synchronization/waiting
  - Document flaky test patterns to avoid
  - Estimated: 3-4 hours

- [ ] **T7-03.2** Add test isolation verification
  - Ensure tests don't depend on execution order
  - Verify random execution order works
  - Check for shared state leaks
  - Estimated: 2 hours

---

## Completed Tasks

> Tasks marked [x] are moved here with completion date. Most recent at top.

### 2025-11-30

- [x] **T0-01** Create test plans (FastTests, FullTests, CriticalPath)
  - Created 3 test plan configurations with parallel execution
  - Configured test skips for performance and snapshot tests
  - Documented in test plan files

- [x] **T0-02** Wire test plans into Xcode schemes
  - Updated project.yml with testPlans configuration
  - Regenerated Xcode project with xcodegen
  - Verified all 3 schemes have test plan support

- [x] **T0-03** Add compiler performance warnings
  - Added to Debug.xcconfig: -warn-long-function-bodies=100
  - Added to Debug.xcconfig: -warn-long-expression-type-checking=100
  - Will identify slow-compiling test code

- [x] **T0-04** Create ci_post_xcodebuild.sh for timing analysis
  - Created script with build timing extraction
  - Added test execution summary logging
  - Ready for Xcode Cloud integration

- [x] **T0-05** Remove conflicting test tags override
  - Removed override var tags from 5 test files
  - Fixed conflict with Apple's built-in test tagging
  - TestTag enum kept for documentation

---

## Discovered Tasks

> Tasks discovered during work but not yet planned. Add here for future prioritization.

- [ ] **DISC-01** Investigate parallel test execution flakiness
  - Some tests may have race conditions when run in parallel
  - Need to identify and fix shared state issues
  - Priority: TBD

- [ ] **DISC-02** Create test data generation utilities
  - Tests currently use hardcoded fixture data
  - Could benefit from property-based testing
  - SwiftCheck or similar framework
  - Priority: Low

- [ ] **DISC-03** Add performance benchmarking suite
  - Beyond pass/fail, track performance trends
  - Document expected performance ranges
  - Alert on regressions
  - Priority: Medium (v1.3+)

---

## Notes & Guidelines

### Test Categorization Philosophy

**Fast Tests (<0.1s):**
- Pure unit tests
- No disk I/O
- No network calls
- Minimal mocking
- Compute-only operations

**Medium Tests (0.1-1s):**
- Integration tests with SwiftData
- File system operations
- Complex object graphs
- Multiple service interactions

**Slow Tests (>1s):**
- Performance benchmarks
- Large data sets (1000+ items)
- UI tests
- End-to-end workflows

### Test Plan Strategy

**FastTests (PR Validation):**
- Target: 5 minutes total
- Run: All fast + medium unit tests
- Skip: Performance, snapshots, integration harness
- Purpose: Quick feedback on pull requests

**FullTests (Main Branch):**
- Target: 15 minutes total
- Run: Everything except snapshots (deferred to v1.2)
- Purpose: Comprehensive validation before merge

**CriticalPath (Smoke Tests):**
- Target: 2 minutes total
- Run: Absolute minimum to verify app launches and core features work
- Purpose: Quick sanity check

### Parallel Execution Considerations

**Safe for parallel execution:**
- Tests using in-memory containers
- Tests with isolated state
- Read-only tests

**Not safe for parallel execution:**
- Tests writing to UserDefaults
- Tests writing to shared file paths
- Tests with timing dependencies
- Tests modifying global state

### References

- [XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md](docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md) - 19 optimization techniques
- [IOS_BUILD_OPTIMIZATIONS.md](docs/IOS_BUILD_OPTIMIZATIONS.md) - Build-time optimizations
- [TestingStrategy.md](TestingStrategy.md) - Original testing strategy document
- [PreviewExamples.md](PreviewExamples.md) - Preview and fixture patterns

---

**Last Updated:** 2025-11-30
**Total Pending Tasks:** 45 (7 in Phase 1-2, 14 in Phase 3-4, 6 in Phase 5, 7 in Phase 6, 8 in Phase 7, 3 discovered)
**Total Completed Tasks:** 5 (infrastructure setup)

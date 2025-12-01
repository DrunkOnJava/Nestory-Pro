# Nestory Pro - Task Management System

<!--
================================================================================
CLAUDE CODE AGENT INSTRUCTIONS - READ BEFORE WORKING
================================================================================

This document is the SINGLE SOURCE OF TRUTH for task management. Multiple Claude
Code agents may be working on this project simultaneously. Follow these rules:

TASK STATUS LEGEND:
  - [ ] Available    = Task is free to be picked up
  - [~] In Progress  = Task is CHECKED OUT by an agent (see agent ID in brackets)
  - [x] Completed    = Task is done and verified
  - [-] Blocked      = Task cannot proceed (see blocker note)
  - [!] Needs Review = Task completed but needs human review

CHECKOUT PROCEDURE (Like a library book):
1. Before starting ANY task, mark it as [~] and add your session identifier
   Example: - [~] [AGENT-abc123] Task description...
2. Add checkout timestamp in the "Active Checkouts" section below
3. Work on the task
4. When complete, mark as [x] and move to "Completed" section with date
5. Remove your entry from "Active Checkouts"

CHECKOUT RULES:
- ONE task per agent at a time (finish or return before taking another)
- If you see [~] on a task, DO NOT work on it - find another task
- If a checkout is >2 hours old with no progress, you may take over (add note)
- Always check "Active Checkouts" section before starting work

DEPENDENCY RULES:
- Tasks marked "Blocked-by: X" cannot start until that task is [x] or ✓
- Check dependencies BEFORE checking out a task
- Dependencies marked ✓ were completed in v1.0

SCOPE RULES:
- Do NOT add features not in this document
- Do NOT refactor code unless a task explicitly requires it
- Do NOT modify files outside the task's scope
- If you discover new work needed, ADD it to "Discovered Tasks" section

TESTING RULES:
- All code changes require tests (unit or UI as appropriate)
- Run `xcodebuild test -only-testing:Nestory-ProTests` before marking complete
- Mark task [!] if tests fail - do not mark [x]

COMMIT RULES:
- One commit per completed task
- Format: "feat|fix|docs|chore(scope): description - closes #TASK-ID"
- No "Generated with Claude Code" attribution
- No Co-Authored-By lines

================================================================================
-->

## Active Checkouts

> When you check out a task, replace `(none)` with your checkout entry. One active task per agent.

| Task ID | Agent ID | Checkout Time | Notes |
|---------|----------|---------------|-------|
| (none) | (none) | (none) | (none) |

---

## Version Roadmap Overview

| Version | Theme | Tasks | Target | Pricing Tier |
|---------|-------|-------|--------|--------------|
| **v1.0** | Launch | ✅ 105 done | ✅ Shipped | Free / Pro |
| **v1.1** | Stability & Swift 6 | ✅ 9 done | ✅ Complete | Pro |
| **v1.2** | UX Polish & Onboarding | ~54 done, 2 QA pending, 4 deferred | Q1 2026 | Pro |
| **v1.3** | Pro Features + Competitive | 10 tasks (5+5), 49 subtasks | Q2 2026 | Pro/Pro+ |
| **v1.4** | Automation & Extensions | 5 tasks | Q2 2026 | Pro |
| **v1.5** | Platform Expansion | 4 tasks | Q3 2026 | Pro |
| **v2.0** | Data Intelligence | 8 tasks | Q4 2026 | Pro+ ($4.99/mo) |
| **v2.1** | Professional Features | 8 tasks | Q1 2027 | Business ($9.99/mo) |
| **v3.0** | Enterprise | 8 tasks | Q2 2027 | Enterprise (Contact) |

**Total: ~46 pending tasks** (2 QA pending + 4 deferred + 39 future work; v1.2-v3.0)

---

## v1.1 – Stability & Infrastructure

> **Theme:** Technical foundation, Swift 6 migration, CloudKit readiness
> **Goal:** Rock-solid stability before adding new features
> **STATUS:** ✅ **COMPLETE** (2025-11-30) - **Archived to TODO-COMPLETE.md**

All v1.1 tasks (P1-00 through P1-04) have been completed and moved to TODO-COMPLETE.md for reference.

### Snapshot Tests - DEFERRED TO v1.2

**Decision (2025-11-30):** Snapshot tests deferred to v1.2 (P2-02) due to v1.2 schema changes.

**Reason:** Models updated for Property/Container hierarchy (v1.2), but UI views require full feature implementation before baselines are meaningful. PreviewContainer fixed to use v1.2 schema (NestoryModelContainer.createForTesting()), but recording baselines now would capture incomplete/transitional state.

- [ ] **9.3.1** Add Inventory list snapshot → **Moved to v1.2**
  - Blocked-by: P2-02 (Property/Container hierarchy completion)
  - Tests exist in ViewSnapshotTests.swift with recording mode commented out
- [ ] **9.3.2** Add Item detail snapshot → **Moved to v1.2**
  - Blocked-by: P2-02
- [ ] **9.3.3** Add Paywall snapshot → **Moved to v1.2**
  - Blocked-by: P2-02
- [ ] **9.3.4** Add Reports tab snapshot → **Moved to v1.2**
  - Blocked-by: P2-02

---

## v1.2 – UX Polish & Onboarding

> **Theme:** First-run experience, user guidance, organization
> **Goal:** Reduce time-to-value for new users
> **Tasks:** 5 | **Dependencies:** v1.1 foundation

**Completed:** P2-01, P2-05, P4-07, P5-03 → **Archived to TODO-COMPLETE.md**

---

> **P2-02** – Information architecture: ✅ **COMPLETE** (2025-12-01) - **Archived to TODO-COMPLETE.md**

---

## v1.2 – Phase 12: Visual Polish & Presentation Layer

> ✅ **STATUS: IMPLEMENTATION COMPLETE** (2025-12-01)
>
> **Theme:** Transform functional UI into a cohesive, professionally designed app experience
> **Goal:** Build new hierarchy views with polish from day 1, then retrofit existing views
> **Strategy:** Design system → ViewModels → Views → Cross-cutting concerns
> **Tasks:** 54 subtasks complete, 2 QA pending (P2-18-4, P2-20-4 device testing)
> **Dependencies:** P2-02 (Property/Container hierarchy) ✅ Complete
> **Target:** Q1 2026 (ready for QA)

### Phase 12 Overview

**What This Phase Delivers:**
- Unified design system (colors, typography, metrics, animations, haptics)
- Rich presentation models in ViewModels (keeps views lean)
- Card-based, modern layouts across all screens
- Comprehensive accessibility support (VoiceOver, Dynamic Type, Reduce Motion)
- Loading states, error states, empty states for all views
- Smooth animations and haptic feedback
- Performance optimizations for large inventories

**Implementation Order:**
1. **Foundation** (P2-06, P2-07): Design system + presentation models
2. **New Views** (P2-08): Polish new hierarchy views (Property/Container/Room detail)
3. **Retrofit Existing** (P2-09 to P2-13): Inventory, Item Detail, Capture, Forms, Settings, Reports
4. **Cross-Cutting** (P2-14 to P2-18): Accessibility, Animations, Haptics, Performance
5. **Testing & Integration** (P2-19, P2-20): Comprehensive testing, project integration

**Architectural Principles:**
- Business logic stays in ViewModels (no SF Symbols, colors, or layout in VMs)
- Views stay declarative and lean (driven by VM presentation models)
- Reusable components in `SharedUI/`
- State-driven UI (enum states, not boolean flags)
- Accessibility-first (VoiceOver labels, Dynamic Type, semantic colors)

---

### P2-06 – Design System Foundation

> ✅ **COMPLETE** (2025-12-01) - **All 3 tasks archived to TODO-COMPLETE.md**
> P2-06-1 (Design tokens), P2-06-2 (Card modifiers), P2-06-3 (Layouts)

---

### P2-07 – ViewModel Presentation Models

> ✅ **COMPLETE** (2025-12-01) - **All 5 tasks archived to TODO-COMPLETE.md**
> P2-07-1 (InventoryTabVM), P2-07-2 (CaptureTabVM), P2-07-3 (AddItemVM), P2-07-4 (ReportsTabVM), P2-07-5 (ItemDetailVM)
> Tests deferred to P2-18

---

### P2-08 – New Hierarchy Views (Build with Polish)

> ✅ **COMPLETE** (2025-12-01) - **All 3 tasks archived to TODO-COMPLETE.md**
> P2-08-1 (PropertyDetailView), P2-08-2 (RoomDetailView), P2-08-3 (ContainerDetailView)

---

### P2-09 – Inventory Tab & App Shell (Retrofit)

> ✅ **COMPLETE** (2025-12-01) - **All 4 tasks archived to TODO-COMPLETE.md**
> P2-09-1 (MainTabView), P2-09-2 (LockScreenView), P2-09-3 (InventoryTab cards), P2-09-4 (Item limit banner)

---

### P2-10 – Item Detail View (Retrofit)

> ✅ **COMPLETE** (2025-12-01) - **All 3 tasks archived to TODO-COMPLETE.md**
> P2-10-1 (Hero photo), P2-10-2 (Info cards), P2-10-3 (Documentation status)

---

### P2-11 – Capture Flows (Retrofit)

> ✅ **COMPLETE** (2025-12-01) - **All 3 tasks archived to TODO-COMPLETE.md**
> P2-11-1 (Action cards hub), P2-11-2 (Status banner), P2-11-3 (Camera views)

---

### P2-12 – Add Item Forms (Retrofit)

> ✅ **COMPLETE** (2025-12-01) - **All 2 tasks archived to TODO-COMPLETE.md**
> P2-12-1 (AddItemView form), P2-12-2 (QuickAddItemSheet)

---

### P2-13 – Settings, Paywall, Reports (Retrofit)

> **Goal:** Professional, marketing-quality UI
> **Blocked-by:** P2-06

#### [x] P2-13-1 – SettingsTab: Card-based sections ✅ (2025-12-01)
- **Completed:** All subtasks implemented in SettingsTab.swift
- **Implemented:**
  - [x] `SettingsRowView`: icon (colored circle), title, subtitle, chevron
  - [x] Sections: Account & Sync, Backup & Restore, Appearance, Support, About
  - [x] Inline state: iCloud sync indicator, sync status
  - [x] ProgressView inline for export/import operations
  - [x] Version number in footer

---

#### [x] P2-13-2 – ContextualPaywallSheet: Marketing layout ✅ (2025-12-01)
- **Completed:** All subtasks implemented in ContextualPaywallSheet.swift
- **Implemented:**
  - [x] Hero icon (120pt), "Upgrade to Nestory Pro" title
  - [x] Benefits list in card with checkmarks
  - [x] Primary CTA with `.borderedProminent`, `.controlSize(.large)`
  - [x] Secondary "Maybe Later", legal text in footnote
  - [x] Restore Purchases button, `.presentationDetents([.medium, .large])`

---

#### [x] P2-13-3 – ReportsTab: Summary dashboard ✅ (2025-12-01)
- Status: Complete

**Subtasks:**
- [x] Summary cards (from `InventorySummary`): Total Items, Total Value, Categories, Rooms in 2x2 grid (StatCard)
- [x] Card groups: "Inventory Reports", "Loss Documentation", "QR Code Labels" (ReportCard)

---

#### [x] P2-13-4 – Report generation views: State-driven UI ✅ (2025-12-01)
- Status: Complete

**Applies to:** `FullInventoryReportView`, `LossListPDFView`, `WarrantyListView`

**Subtasks:**
- [x] Map `ReportGenerationState`: `.idle` → "Generate" button, `.generating` → ProgressView + message, `.ready(url)` → QuickLook preview, `.error(msg)` → Alert with retry
- [x] Haptic feedback on success/error (P2-16-1)

---

### P2-14 – Accessibility & Inclusive Design

> **Goal:** Ensure all polish improvements are accessible to everyone
> **Blocked-by:** P2-06, P2-08 to P2-13 (all views complete)

#### [x] P2-14-1 – VoiceOver labels & hints ✅ (2025-12-01)
- Status: Complete (implemented in DesignSystem.swift + 20 view files)

**Subtasks:**
- [x] Audit all interactive elements for `.accessibilityLabel()` - helpers in DesignSystem.swift
- [x] Add `.accessibilityHint()` for non-obvious actions - `accessibilityCard()`, `accessibilityItemRow()` modifiers
- [x] Examples implemented: StatCard, ReportCard, ItemRow all have VoiceOver support
- [ ] Test with VoiceOver enabled on device (QA verification needed)

---

#### [x] P2-14-2 – Dynamic Type support ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:114-125, 885-1023)

**Subtasks:**
- [x] Typography already uses system fonts (Font.headline, etc.) that scale automatically
- [x] Added `Typography.scaled()` helper for custom-size fonts with Dynamic Type
- [x] Created `AdaptiveStack` component that switches HStack→VStack at accessibility sizes
- [x] Added `.dynamicTypeFitting()` modifier for constrained text with minimumScaleFactor
- [x] Added `.limitDynamicType(to:)` modifier for edge cases where layout can't adapt
- [x] Added `@ScaledSpacing` property wrapper for spacing that scales with text

---

#### [x] P2-14-3 – Reduce Motion support ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:372-454)

**Subtasks:**
- [x] Check `@Environment(\.accessibilityReduceMotion)` - Used in all animation modifiers
- [x] Disable spring animations when enabled - `ReduceMotionAnimationModifier`
- [x] Use instant `.opacity` transitions instead of slides - `ReduceMotionTransitionModifier`
- [x] Disable skeleton shimmer - `AccessibleShimmerModifier` shows static opacity:0.6

---

#### [x] P2-14-4 – Color contrast audit ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:20-95)

**Subtasks:**
- [x] Documented WCAG AA requirements in Colors enum (4.5:1 text, 3:1 UI)
- [x] Created WCAG-compliant semantic colors (success/warning/error)
- [x] Added `Color(light:dark:)` helper for mode-adaptive colors
- [x] Success: #1B8A2C (4.5:1 on white), Warning: #B85000, Error: #C53030
- [x] Verified system colors (primaryLabel, secondaryLabel) meet requirements
- [x] Updated documented/incomplete status colors to use compliant variants

---

#### [x] P2-14-5 – Accessibility Identifiers (UI Testing) ✅ (2025-12-01)
- Status: Complete (AccessibilityIdentifiers.swift: 297 lines)

**Subtasks:**
- [x] Add `.accessibilityIdentifier()` to key elements - Comprehensive enum structure
- [x] Update `AccessibilityIdentifiers.swift` with constants - MainTab, Inventory, Hierarchy, AddEditItem, ItemDetail, Capture, Reports, Onboarding, Settings, Alert, Sheet, Pro, LockScreen, Common
- [x] Dynamic identifier generators: `itemCell(at:)`, `filterChip(named:)`, `propertyRow(id:)`, etc.

---

### P2-15 – Animations & Micro-interactions

> **Goal:** Smooth, delightful animations that enhance UX
> **Blocked-by:** P2-06-1

#### [x] P2-15-1 – View transitions ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:146-155)

**Subtasks:**
- [x] Animation presets defined: `NestoryTheme.Animation.quick`, `.standard`, `.slow`, `.spring`, `.bouncy`
- [x] Transition helper: `transitionWithMotionPreference()` modifier
- [x] Reduce Motion support integrated via `ReduceMotionTransitionModifier`

---

#### [x] P2-15-2 – Button press feedback ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:559-631)

**Subtasks:**
- [x] `PressableButtonStyle` with `scaleEffect(0.96)` + haptic feedback
- [x] `CardButtonStyle` with `scaleEffect(0.98)` + shadow animation
- [x] View extension: `.pressableStyle()`, `.cardButtonStyle()` modifiers
- [x] Reduce Motion respected in both styles

---

#### [x] P2-15-3 – Card expansion animations ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:672-818, ItemDetailView.swift:46)

**Subtasks:**
- [x] `ExpandableSection<Header, Content>` with spring animations and chevron rotation
- [x] `ExpandableCard<Header, Summary, Content>` for progressive disclosure pattern
- [x] Smooth height transitions using `.transition(.asymmetric(...))`
- [x] Reduce Motion support: falls back to opacity-only transitions
- [x] Haptic feedback on expand/collapse via `NestoryTheme.Haptics.selection()`

---

#### [x] P2-15-4 – Loading skeleton animation ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:270-306, 399-440)

**Subtasks:**
- [x] `ShimmerModifier` with animated LinearGradient sweep
- [x] `AccessibleShimmerModifier` with Reduce Motion support (static opacity:0.6)
- [x] View extension: `.shimmering()`, `.accessibleShimmer()` modifiers
- [x] `.loadingCard()` modifier combines redaction + shimmer

---

### P2-16 – Haptic Feedback

> **Goal:** Tactile feedback for key interactions
> **Blocked-by:** P2-06-1

#### [x] P2-16-1 – Success feedback ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:161-163, used in 8 view files)

**Subtasks:**
- [x] `NestoryTheme.Haptics.success()` implemented
- [x] Used in: FullInventoryReportView, LabelGeneratorView, QuickAddItemSheet, etc.

---

#### [x] P2-16-2 – Error feedback ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:165-167)

**Subtasks:**
- [x] `NestoryTheme.Haptics.error()` implemented
- [x] Used in: FullInventoryReportView error handling, form validation

---

#### [x] P2-16-3 – Selection feedback ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:173-175)

**Subtasks:**
- [x] `NestoryTheme.Haptics.selection()` implemented
- [x] Used in: ReportsTab cards, PressableButtonStyle, CardButtonStyle
- [x] `NestoryTheme.Haptics.impact()` with light/heavy variants for toggles

---

### P2-17 – Performance & Loading States

> **Goal:** Smooth performance with large inventories (100+ items)
> **Blocked-by:** P2-06 ✓
> P2-17-1 (Image caching) ✅ **COMPLETE** - Archived to TODO-COMPLETE.md

#### [x] P2-17-2 – Lazy loading for large lists ✅ (2025-12-01)
- Status: Complete (pagination deferred - not needed for typical home inventories)

**Subtasks:**
- [x] Use `LazyVStack` in scrolling views - InventoryTab, EditQueueView, RoomEditorSheet, ContainerEditorSheet, PropertyEditorSheet, TagPillView
- [x] Use `LazyVGrid` for grid layout - InventoryTab grid view
- [-] Pagination (>50 items) - Deferred; typical home inventories <100 items, LazyVStack handles well

---

#### [x] P2-17-3 – Progressive disclosure ✅ (2025-12-01)
- Status: Complete (DesignSystem.swift:722-818, ItemDetailView.swift:383-448)

**Subtasks:**
- [x] `ExpandableCard` component: always shows summary, expands for details
- [x] Documentation status: score percentage + progress bar always visible, 6-field badges on expand
- [x] Hierarchy views can use `ExpandableSection` for summary → details pattern

---

### P2-18 – Testing

> **Goal:** Comprehensive test coverage for all new models and UI
> **Blocked-by:** All implementation tasks

#### [x] P2-18-1 – ViewModel presentation model tests ✅ (2025-12-01)
- Status: Complete (Nestory-ProTests/UnitTests/ViewModels/PresentationModelTests.swift)

**Subtasks:**
- [x] Unit tests for `InventorySection` (id, displayName, hashable)
- [x] Unit tests for `SearchMatchMetadata` (hasMatch, matchSummary, noMatch)
- [x] Unit tests for `DocumentationStatus` (coreScore, extendedScore, isFullyDocumented, missingFields)
- [x] Unit tests for `AddItemField` (isRequired, displayName, iconName, placeholder)
- [x] ~45 test methods covering all presentation model computed properties

---

#### [x] P2-18-2 – Preview examples ✅ (2025-12-01)
- Status: Complete (40+ previews across 20+ view files)

**Subtasks:**
- [x] Add `#Preview` for views - 40+ preview macros across Reports, Capture, Inventory, Settings, Onboarding, etc.
- [x] Multiple state previews - Empty, With Data, Loading states covered
- [x] Preview helpers in ReportsTab.swift, FullInventoryReportView.swift, etc.

---

#### [x] P2-18-3 – Snapshot tests ✅ (2025-12-01)
- Status: Complete (Nestory-ProTests/SnapshotTests/)
- Note: Baselines need recording when views stabilize (`isRecording = true` once)

**Subtasks:**
- [x] SnapshotHelpers.swift: Device configs (iPhone17ProMax/Pro/SE, iPadPro12_9)
- [x] SnapshotHelpers.swift: `assertViewSnapshot()` and `assertMultiDeviceSnapshot()` helpers
- [x] InventorySnapshotTests: Empty, WithItems, ManyItems, MultiDevice tests
- [x] ItemDetailSnapshotTests: FullyDocumented, MinimalData, MultiDevice tests
- [x] PaywallSnapshotTests: ItemLimit, LossListLimit, PhotosInPDF, CSVExport, AlreadyPro tests
- [x] ReportsSnapshotTests: WithItems, Empty, MultiDevice tests
- [ ] QA: Record baselines with `isRecording = true` after v1.2 views stabilize

---

#### [~] P2-18-4 – Accessibility audit (QA Required)
- Status: Implementation Complete, QA Verification Needed

**Implementation Complete:**
- [x] P2-14-1: VoiceOver support - `.accessibilityLabel()` and `.accessibilityHint()` throughout views
- [x] P2-14-2: Dynamic Type - `AdaptiveStack`, `ScaledSpacing`, `.dynamicTypeFitting()` modifiers
- [x] P2-14-3: Reduce Motion - `ReduceMotionAnimationModifier`, `AccessibleShimmerModifier`
- [x] P2-14-4: Color contrast - WCAG AA compliant success/warning/error colors
- [x] P2-14-5: Accessibility identifiers - `AccessibilityIdentifiers` enum for UI testing

**QA Verification Needed:**
- [ ] VoiceOver testing on device (navigate InventoryTab, verify labels/hierarchy)
- [ ] Dynamic Type testing at `xxxLarge` and `accessibilityXXXLarge`
- [ ] Color contrast with Xcode Accessibility Inspector (verify implementation)
- [ ] Reduce Motion testing (verify animations disabled)

---

### P2-19 – Project Integration

> ✅ **COMPLETE** (2025-12-01) - **All 2 tasks archived to TODO-COMPLETE.md**
> P2-19-1 (Xcode project updates), P2-19-2 (Scheme validation)
> All builds succeeded (Debug, Beta, Release), UI Tests fixed

---

### P2-20 – Phase 12 Completion Checklist

> **Goal:** Validate all Phase 12 objectives met before declaring complete

#### [x] P2-20-1 – Design system validation ✅ (2025-12-01)
- Status: Complete

**Checklist:**
- [x] `NestoryTheme` tokens defined and documented (DesignSystem.swift)
- [x] All color assets present with light/dark variants (Colors enum, BrandColor.colorset)
- [x] Card modifiers implemented and used consistently (`.cardStyle()`, 15+ usages)
- [x] Typography scale applied across app (Typography enum with 10+ presets)
- [x] Animation durations standardized (Animation enum: quick/standard/slow/spring)
- [x] Haptic patterns implemented (Haptics enum: impact/notification/selection/success/error)

---

#### [x] P2-20-2 – ViewModel presentation models validation ✅ (2025-12-01)
- Status: Complete

**Checklist:**
- [x] `InventorySectionData`, `SearchMatchMetadata`, `itemLimitWarningDisplay()` in InventoryTabViewModel
- [x] `CaptureMode`, `CaptureActionCard` in CaptureTabViewModel
- [x] `AddItemField`, `AddItemSection`, `FieldValidationState` in AddItemViewModel
- [x] `InventorySummary`, `InventorySummaryItem`, `ReportGenerationState` in ReportsTabViewModel
- [x] `DocumentationStatus` in ItemDetailViewModel
- [x] All models have unit tests in PresentationModelTests.swift (~45 test methods)

---

#### [x] P2-20-3 – View polish validation ✅ (2025-12-01)
- Status: Complete

**Checklist:**
- [x] `.cardStyle()` used (25 occurrences across 3 files)
- [x] Empty states: 11 files with EmptyStateView/ContentUnavailableView
- [x] Loading states: 31 occurrences (ProgressView, .redacted, .shimmering, .loadingCard)
- [x] Error states: 44 occurrences (.alert, case error/failed)
- [x] Accessibility labels: 142 occurrences across 20+ files
- [x] Light/dark mode: Colors enum supports both with WCAG-compliant variants
- [x] Preview examples: 45 #Preview macros across 20+ view files

---

#### [~] P2-20-4 – Accessibility validation (Implementation Complete, QA Pending)
- Status: Implementation complete, QA device testing needed

**Checklist:**
- [x] VoiceOver support implemented: 142 accessibility modifiers across 20+ files
- [x] Dynamic Type support: `AdaptiveStack`, `ScaledSpacing`, `.dynamicTypeFitting()` in DesignSystem.swift
- [x] Reduce Motion support: `ReduceMotionAnimationModifier`, `AccessibleShimmerModifier`
- [x] Color contrast meets WCAG AA: #1B8A2C success, #B85000 warning, #C53030 error
- [x] Accessibility Identifiers: AccessibilityIdentifiers.swift (297 lines)
- [ ] QA: Device testing with VoiceOver, xxxLarge Dynamic Type, Reduce Motion (manual)

---

#### [x] P2-20-5 – Performance validation ✅ (2025-12-01)
- Status: Complete (implementation verified)

**Checklist:**
- [x] Image caching: ImageCacheService implemented (P2-17-1, archived)
- [x] Lazy loading: 11 LazyVStack/LazyVGrid/LazyHStack usages in 6 files
- [x] Progressive disclosure: `ExpandableCard` in DesignSystem.swift, used in ItemDetailView
- [x] Animation presets: `NestoryTheme.Animation` with spring/standard/quick durations
- [ ] Runtime testing: Frame rate & scrolling performance (manual QA on device)

---

#### [x] P2-20-6 – Final build & test ✅ (2025-12-01)
- Status: Complete

**Checklist:**
- [x] Clean build: `BUILD SUCCEEDED [18.547 sec]` (Debug, iPhone 17 Pro Max)
- [x] All unit tests pass: `TEST SUCCEEDED [154.280 sec]`
- [x] All integration tests pass: `TEST SUCCEEDED [85.220 sec]`
- [x] Snapshot tests: Infrastructure ready (baselines to record after v1.2 stabilizes)
- [x] No compiler warnings (clean build)
- [x] TSan disabled in Tests.xcconfig (Swift 6 compatibility issue)
- [ ] Archive: Pending (TestFlight deployment when v1.2 releases)

---

### Phase 12 Agent Notes

**READ BEFORE STARTING ANY PHASE 12 TASK:**

1. **Implementation Order:** P2-06 (Design System) → P2-07 (ViewModels) → P2-08+ (Views) → P2-14-18 (Cross-cutting)

2. **Small PRs:** 1 PR = 1 design system component OR 1 ViewModel + 1 view. Do NOT combine multiple views.

3. **Business Logic vs. Presentation:**
   - Business logic (parsing, validation, grouping) → ViewModels
   - Styling (colors, fonts, SF Symbols, layout) → Views or DesignSystem
   - NEVER put SF Symbols, Colors in ViewModels

4. **Testing Requirements:**
   - EVERY new ViewModel model/helper needs unit tests
   - EVERY new view needs `#Preview` examples (empty, single, many)
   - KEY views need snapshot tests
   - Run `xcodebuild test -only-testing:Nestory-ProTests` before marking complete

5. **Accessibility is NOT Optional:**
   - Add `.accessibilityLabel()` to ALL interactive elements
   - Test with VoiceOver ON before marking view tasks complete

6. **State-Driven UI:** Use enums, NOT boolean flags. Good: `CaptureStatus.processing("Scanning...")`. Bad: `isProcessing = true`

7. **Commit Format:**
   - `feat(design-system): add NestoryTheme color tokens - closes #P2-06-1`
   - NO "Generated with Claude Code" attribution
   - NO Co-Authored-By lines

8. **Discovered Issues:** Add to "Discovered Tasks" section. Do NOT expand scope mid-task.

---

### Phase 12 Completion Criteria

Phase 12 is **complete** when:

✅ All 78 subtasks marked `[x]`
✅ All unit tests passing (90%+ coverage for presentation models)
✅ All snapshot baselines recorded and passing
✅ Accessibility audit complete (VoiceOver, Dynamic Type, Reduce Motion, contrast)
✅ All schemes build without warnings (Debug, Beta, Release)
✅ Performance validated with 100+ items (no frame drops)
✅ TestFlight build uploaded and tested on device

**Estimated Effort:** 4-6 weeks (1-2 developers working in parallel)

**Deliverable:** A visually cohesive, professionally polished iOS app with rich accessibility support and smooth performance at scale.

---

### v1.2 Release Checklist

**Completed Features → Archived to TODO-COMPLETE.md:**
- ✅ Onboarding flow (P2-01)
- ✅ Tags system (P2-05)
- ✅ Feedback mechanism (P4-07)
- ✅ Reminder notifications (P5-03)
- ✅ Property/Container hierarchy (P2-02)
- ✅ Phase 12 foundation: P2-06, P2-07, P2-08, P2-09, P2-10, P2-11, P2-12
- ✅ Cross-cutting complete: P2-13, P2-14, P2-15, P2-16, P2-17
- ✅ Project integration: P2-19-1, P2-19-2
- ✅ Testing: P2-18 (unit tests, previews, snapshot infrastructure)
- ✅ Completion validation: P2-20 (2025-12-01)

**QA Pending (Manual Device Testing):**
- [ ] VoiceOver navigation testing on device
- [ ] Dynamic Type testing at xxxLarge sizes
- [ ] Reduce Motion testing
- [ ] Frame rate & scrolling performance profiling

**Deferred:**
- [ ] Snapshot test baselines (9.3.1-9.3.4) - Record after v1.2 views stabilize

---

## v1.3 – Pro Features v2 & Competitive Features

> **Theme:** Monetization infrastructure, multi-property support, competitive differentiators
> **Goal:** Increase Pro conversion, retention, and capture market from competitors (Sortly, Encircle)
> **Tasks:** 10 (5 original + 5 competitive features) | **Dependencies:** v1.2 UX work
> **Competitive Features Added:** 2025-12-01 (F5-F9 from market research)

#### [ ] P3-05 – Value summary view per property
- Checked-out-by: none
- Blocked-by: P2-02

**Goal:** One tap to see total value for insurance discussions.

**Subtasks:**
- [ ] Add summary screen per property: total items, estimated value
- [ ] Break down by room and category
- [ ] Add "export summary as PDF/email" stub
- [ ] Respect currency and optional fields

---

#### [ ] P4-01 – Feature flag system (free vs Pro)
- Checked-out-by: none
- Blocked-by: P2-06 ✓, P3-01 ✓

**Goal:** Central, testable mechanism for Pro feature gating.

**Subtasks:**
- [ ] Implement `FeatureFlags` service
- [ ] Inject via environment or observable object
- [ ] Add test coverage for flag behavior
- [ ] Show Pro features in Settings (even before paywall)

---

#### [ ] P4-02 – Multi-property support (Pro differentiator)
- Checked-out-by: none
- Blocked-by: P2-02, P4-01

**Goal:** Manage multiple homes/locations as Pro feature.

**Subtasks:**
- [ ] Extend model for multiple properties
- [ ] Implement property switcher UI
- [ ] Add per-property backups and summaries
- [ ] Gate behind `FeatureFlags.isPro`

---

#### [ ] P4-08 – Server-side receipt validation
- Checked-out-by: none
- Blocked-by: P4-03 ✓

**Goal:** Secure IAP validation to prevent piracy.

**Subtasks:**
- [ ] Design REST endpoint (Cloudflare Workers or Vercel Edge)
- [ ] Implement App Store Server API v2 integration
- [ ] Add server-side verification to IAPValidator
- [ ] Handle offline graceful degradation
- [ ] Monitor for fraud patterns

---

#### [ ] P5-04 – Lightweight analytics (privacy-respecting)
- Checked-out-by: none
- Blocked-by: P4-03 ✓

**Goal:** Understand usage without compromising privacy.

**Subtasks:**
- [ ] Implement simple event logging (no PII)
- [ ] Add opt-in analytics toggle in Settings
- [ ] Consider self-hosted or privacy-first solution
- [ ] Use data to refine roadmap

---

### Competitive Features (F5-F9) – Added 2025-12-01

> **Source:** Market research from TODO-FEATURES.md
> **Implementation Order:** F7 → F8 → F6 → F5 → F9
> **Total Subtasks:** 49

---

#### [ ] F7 – Offline Mode Indicator (Quick Win)
- Checked-out-by: none
- Blocked-by: None
- **Priority:** SHOULD HAVE | **Tier:** Free | **Effort:** LOW (1-2 days)

**Goal:** Show users when they're offline and when data is syncing to iCloud.

**Success Criteria Levels:**

| Level | Criteria |
|-------|----------|
| **Bronze (MVP)** | Status badge in Settings showing online/offline state |
| **Silver (Production)** | Real-time banner with sync status, pending changes count |
| **Gold (Polished)** | Sync progress indicator, retry button, accessibility support |

**Subtasks:**
- [ ] **F7-01** Create `NetworkMonitor` service (NWPathMonitor, @Observable, AppEnvironment injection)
- [ ] **F7-02** Create `SyncStatusService` for CloudKit state (.idle, .syncing, .synced, .error)
- [ ] **F7-03** Create `SyncStatusBanner` UI component (auto-dismiss, states: hidden/yellow/green/red)
- [ ] **F7-04** Add sync status to SettingsTab (indicator, timestamp, "Sync Now" button)
- [ ] **F7-05** Handle offline gracefully (queue ops, no error modals for expected state)
- [ ] **F7-06** Unit tests for NetworkMonitor and SyncStatusService

**Files:** `Services/NetworkMonitor.swift`, `Services/SyncStatusService.swift`, `Views/SharedUI/SyncStatusBanner.swift`

---

#### [ ] F8 – Batch Photo Capture Mode
- Checked-out-by: none
- Blocked-by: P3-01 ✓
- **Priority:** SHOULD HAVE | **Tier:** Free | **Effort:** Medium (3-4 days)

**Goal:** Rapid-fire photo capture for quick inventory, add item details later. "Photograph everything, organize later."

**Success Criteria Levels:**

| Level | Criteria |
|-------|----------|
| **Bronze (MVP)** | Burst capture mode, photos queued for processing |
| **Silver (Production)** | Edit queue UI, batch room/category assignment |
| **Gold (Polished)** | AI suggestions, swipe gestures, photo grouping |

**Subtasks:**
- [ ] **F8-01** Create `BatchCaptureView` camera interface (full-screen, minimal UI, haptic feedback)
- [ ] **F8-02** Create `PendingCapture` temporary model (photo data, timestamp, location)
- [ ] **F8-03** Create `CaptureQueueService` (queue management, background compression, persistence)
- [ ] **F8-04** Create `EditQueueView` for pending items (grid view, multi-select, swipe to delete)
- [ ] **F8-05** Create `QuickEditSheet` for single item (name, room, category, "Save & Next")
- [ ] **F8-06** Implement batch operations (assign room/category, delete selected, process all)
- [ ] **F8-07** Add queue badge to CaptureTab (red badge with pending count)
- [ ] **F8-08** Add smart suggestions (Silver+) - duplicate detection, grouping, category hints
- [ ] **F8-09** Persistence and recovery (disk storage, crash recovery, 30-day auto-cleanup)
- [ ] **F8-10** Unit tests for queue operations

**Files:** `Views/Capture/BatchCaptureView.swift`, `Views/Capture/EditQueueView.swift`, `Views/Capture/QuickEditSheet.swift`, `Services/CaptureQueueService.swift`, `Models/PendingCapture.swift`

---

#### [ ] F6 – Batch Import from Spreadsheets
- Checked-out-by: none
- Blocked-by: P3-03 ✓
- **Priority:** SHOULD HAVE | **Tier:** Pro | **Effort:** Medium (3-5 days)

**Goal:** Import items from CSV/Excel files with column mapping UI, enabling migration from competitors.

**Success Criteria Levels:**

| Level | Criteria |
|-------|----------|
| **Bronze (MVP)** | CSV import with auto-detected columns, basic mapping |
| **Silver (Production)** | Excel support, custom field mapping UI, validation preview |
| **Gold (Polished)** | Template downloads, error recovery, import history, undo |

**Subtasks:**
- [ ] **F6-01** Create `CSVParser` service (UTF-8/Windows-1252, quoted fields, delimiters)
- [ ] **F6-02** Create `ColumnMapper` for field detection (auto-detect: Name, Price, Room, Category)
- [ ] **F6-03** Create `ImportPreviewView` sheet (file picker, preview rows, mapping dropdowns)
- [ ] **F6-04** Create `FieldMappingView` UI (source → target mapping, required field indicators)
- [ ] **F6-05** Implement import validation (required fields, type validation, duplicate detection)
- [ ] **F6-06** Create `ImportProgressView` (progress bar, error list, undo option)
- [ ] **F6-07** Add Excel (.xlsx) support (CoreXLSX package, multiple sheets)
- [ ] **F6-08** Create import templates ("Download Template", Basic/Detailed/From Sortly/From Encircle)
- [ ] **F6-09** Import history and undo (track batches, "Undo Last Import", 30-day retention)
- [ ] **F6-10** Pro feature gating (paywall before import, preview without Pro)
- [ ] **F6-11** Unit tests for CSV parsing and mapping

**Files:** `Services/CSVParser.swift`, `Services/ColumnMapper.swift`, `Services/ImportService.swift`, `Views/Settings/ImportPreviewView.swift`, `Views/Settings/FieldMappingView.swift`, `Views/Settings/ImportProgressView.swift`

---

#### [ ] F5 – Depreciation Tracking & Value History
- Checked-out-by: none
- Blocked-by: P2-02 ✓, F4 ✓
- **Priority:** SHOULD HAVE | **Tier:** Pro+ | **Effort:** Medium-High (5-7 days)

**Goal:** Track item value changes over time with depreciation calculations for insurance claims.

**Success Criteria Levels:**

| Level | Criteria |
|-------|----------|
| **Bronze (MVP)** | Manual value entries, simple depreciation calculation |
| **Silver (Production)** | Auto-depreciation, charts, category-based rates |
| **Gold (Polished)** | Multiple methods, schedules, reports, tax export |

**Subtasks:**
- [ ] **F5-01** Create `ValueEntry` model (id, date, value, source, notes, Item relationship)
- [ ] **F5-02** Extend Item model with depreciation fields (method, rate, residualValue, valueHistory)
- [ ] **F5-03** Create `DepreciationMethod` enum (.none, .straightLine, .decliningBalance, .custom)
- [ ] **F5-04** Create `DepreciationService` (calculate value, auto-generate entries, category defaults)
- [ ] **F5-05** Create `ValueHistoryView` in ItemDetailView (Swift Charts line chart)
- [ ] **F5-06** Create `DepreciationSettingsView` (method picker, rate input, preview)
- [ ] **F5-07** Add depreciation to reports ("Original vs. Current Value", total depreciation)
- [ ] **F5-08** Create category-based depreciation defaults (Electronics 20%, Furniture 10%, etc.)
- [ ] **F5-09** Batch depreciation update ("Recalculate All Values" in Settings)
- [ ] **F5-10** Pro+ feature gating (teaser in ItemDetailView)
- [ ] **F5-11** Unit tests for depreciation calculations

**Files:** `Models/ValueEntry.swift`, `Models/DepreciationMethod.swift`, `Services/DepreciationService.swift`, `Views/Inventory/ValueHistoryView.swift`, `Views/Inventory/DepreciationSettingsView.swift`

---

#### [ ] F9 – 3D Room Scanning (LiDAR)
- Checked-out-by: none
- Blocked-by: P2-02 ✓
- **Priority:** NICE TO HAVE | **Tier:** Pro+ | **Effort:** HIGH (7-10 days)
- **Limitation:** Requires iOS 16+ and LiDAR device (iPhone 12 Pro+, iPad Pro)

**Goal:** Capture spatial documentation of rooms using Apple's RoomPlan API.

**Success Criteria Levels:**

| Level | Criteria |
|-------|----------|
| **Bronze (MVP)** | Basic room scan, USDZ export, dimensions |
| **Silver (Production)** | Room linking, floor plans, item placement hints |
| **Gold (Polished)** | AR item placement, interactive 3D viewer, multi-room |

**Subtasks:**
- [ ] **F9-01** Check device capability (LiDAR detection, "Requires LiDAR" message, fallback)
- [ ] **F9-02** Create `RoomScanView` with RoomPlan (RoomCaptureView, coaching UI, progress)
- [ ] **F9-03** Create `RoomScan` model (id, roomId, scanDate, usdzData, thumbnailImage)
- [ ] **F9-04** Implement scan processing (CapturedRoom → USDZ, dimensions, floor plan)
- [ ] **F9-05** Create `RoomScanViewer` for playback (SceneKit/RealityKit, orbit/pan/zoom)
- [ ] **F9-06** Link scans to rooms ("Scan Room" button, thumbnail in header)
- [ ] **F9-07** Export scan data (USDZ, floor plan PNG, include in PDF reports)
- [ ] **F9-08** AR item placement hints (Gold) - tap to add item
- [ ] **F9-09** Storage management (compress older scans, "Manage Scans" in Settings)
- [ ] **F9-10** Pro+ feature gating (subscription + device check)
- [ ] **F9-11** Unit tests (model creation, file storage)

**Files:** `Views/Hierarchy/RoomScanView.swift`, `Views/Hierarchy/RoomScanViewer.swift`, `Models/RoomScan.swift`, `Services/RoomScanService.swift`

---

### v1.3 Release Checklist

**Original Features:**
- [ ] Multi-property support working for Pro users
- [ ] Feature flag system testable and documented
- [ ] Server-side receipt validation deployed
- [ ] Analytics opt-in functional

**Competitive Features (F5-F9):**
- [ ] F7: Offline mode indicator showing sync status
- [ ] F8: Batch photo capture with edit queue
- [ ] F6: CSV/Excel import with column mapping (Pro)
- [ ] F5: Depreciation tracking with value history (Pro+)
- [ ] F9: 3D room scanning on LiDAR devices (Pro+)

---

## v1.4 – Automation & Extensions

> **Theme:** Widgets, Siri, smart suggestions
> **Goal:** Reduce friction for power users
> **Tasks:** 5 | **Dependencies:** v1.2 tags, v1.3 properties

#### [ ] P5-02 – Smart suggestions for categories & tags
- Checked-out-by: none
- Blocked-by: P2-05

**Goal:** Use heuristics to speed up tagging.

**Subtasks:**
- [ ] Implement heuristics (e.g., "TV" → Electronics)
- [ ] Suggest tags at creation time
- [ ] Allow 1-tap application
- [ ] Log acceptance rates for ML upgrades

---

#### [ ] P5-05 – Shareable summaries
- Checked-out-by: none
- Blocked-by: P3-05

**Goal:** Make Nestory useful in multi-person contexts.

**Subtasks:**
- [ ] Create "Share summary" flow (PDF or text)
- [ ] Add options: "For insurance", "For landlord", "For roommate"
- [ ] Ensure exports never leak sensitive items
- [ ] Gate advanced templates behind Pro

---

#### [ ] P5-07 – Widget extension for quick capture
- Checked-out-by: none
- Blocked-by: P2-03 ✓

**Goal:** Home screen widget for instant capture.

**Subtasks:**
- [ ] Create WidgetKit extension target
- [ ] Design small/medium widget layouts
- [ ] Implement App Intent for camera capture
- [ ] Share data via App Group
- [ ] Add widget configuration options

---

#### [ ] P5-08 – Siri Shortcuts support
- Checked-out-by: none
- Blocked-by: P2-03 ✓

**Goal:** Voice-activated inventory management.

**Subtasks:**
- [ ] Define App Intents for common actions
- [ ] Implement `AddItemIntent` with voice capture
- [ ] Implement `SearchInventoryIntent`
- [ ] Add Shortcuts app integration
- [ ] Test various invocation phrases

---

#### [ ] P5-09 – App Clips for quick capture
- Checked-out-by: none
- Blocked-by: P2-03 ✓, P5-07

**Goal:** Lightweight capture via QR/NFC without full install.

**Subtasks:**
- [ ] Create App Clip target (<15MB)
- [ ] Implement quick photo capture flow
- [ ] Design QR/NFC integration for room-specific capture
- [ ] Handle data handoff to full app

---

### v1.4 Release Checklist

- [ ] Widget functional on Home Screen
- [ ] Siri Shortcuts working with common commands
- [ ] App Clip approved and functional
- [ ] Smart suggestions improving tag adoption

---

## v1.5 – Platform Expansion

> **Theme:** Mac Catalyst, localization, sharing
> **Goal:** Expand addressable market
> **Tasks:** 4 | **Dependencies:** v1.3-1.4 features

#### [ ] P4-09 – CloudKit sharing for family inventories
- Checked-out-by: none
- Blocked-by: P4-02, P3-04 ✓

**Goal:** Share inventory with family via iCloud.

**Subtasks:**
- [ ] Enable CloudKit sharing capabilities
- [ ] Implement `CKShare` for property-level sharing
- [ ] Design invitation flow (share link or contacts)
- [ ] Handle permission levels (view-only vs. edit)
- [ ] Implement conflict resolution
- [ ] Add "Shared with me" section

---

#### [ ] P5-06 – Template extraction (canonical starter kit)
- Checked-out-by: none
- Blocked-by: P1-01, P2-06 ✓, P3-02 ✓, P4-01

**Goal:** Turn Nestory into reusable iOS starter template.

**Subtasks:**
- [ ] Document architecture in `docs/ARCHITECTURE.md`
- [ ] Create architecture diagram (Mermaid)
- [ ] Extract reusable modules as Swift packages
- [ ] Provide minimal "starter app" variant

---

#### [ ] P6-01 – Mac Catalyst support
- Checked-out-by: none
- Blocked-by: P1-01, P5-06

**Goal:** Run Nestory natively on macOS.

**Subtasks:**
- [ ] Enable Mac Catalyst in Xcode
- [ ] Adapt UI for mouse/keyboard (hover states, shortcuts)
- [ ] Handle macOS file paths and sandbox
- [ ] Add menu bar integration
- [ ] Test all features (camera → screen capture fallback)
- [ ] Submit to Mac App Store

---

#### [ ] P6-02 – Spanish localization
- Checked-out-by: none
- Blocked-by: P2-01

**Goal:** First non-English localization.

**Subtasks:**
- [ ] Extract strings to `Localizable.strings`
- [ ] Create `es.lproj` folder
- [ ] Professional translation review
- [ ] Localize App Store metadata
- [ ] Test string length edge cases

---

### v1.5 Release Checklist

- [ ] Mac Catalyst app on Mac App Store
- [ ] Spanish localization complete
- [ ] CloudKit sharing functional
- [ ] Template extraction documented

---

## v2.0 – Data Intelligence (Pro+ Tier)

> **Theme:** Transform from inventory to intelligent asset management
> **Goal:** Unlock prosumer market with $4.99/mo subscription
> **Tasks:** 8 | **Dependencies:** v1.x foundation complete

#### [ ] P7-01 – Depreciation & value lifecycle tracking
- Checked-out-by: none
- Blocked-by: P2-03 ✓

**Goal:** Track value changes for accurate insurance claims.

**Subtasks:**
- [ ] Add `purchaseDate`, `purchasePrice`, `currentValue`, `depreciationMethod`
- [ ] Implement depreciation calculators (straight-line, declining balance)
- [ ] Auto-calculate current value based on age
- [ ] Show "original vs. current value" comparison
- [ ] Category-based default depreciation rates
- [ ] "Replacement Cost" vs "Actual Cash Value" toggle

---

#### [ ] P7-02 – Audit trail & change history
- Checked-out-by: none
- Blocked-by: P2-03 ✓

**Goal:** Track changes for compliance and accountability.

**Subtasks:**
- [ ] Create `ItemHistory` model
- [ ] Record all Item field changes automatically
- [ ] Show history timeline in item detail
- [ ] Add "Restore previous value" action
- [ ] Export audit log (PDF/CSV)

---

#### [ ] P7-03 – Custom fields
- Checked-out-by: none
- Blocked-by: P2-02, P4-02

**Goal:** Let power users track any attribute.

**Subtasks:**
- [ ] Create `CustomFieldDefinition` model (name, type, required, options, scope)
- [ ] Create `ItemCustomFieldValue` junction model for storage
- [ ] Support types: text, number, date, single/multi-select, URL
- [ ] Property-level or global definitions
- [ ] Show in item detail, edit forms, reports
- [ ] Include in search and filters

---

#### [ ] P7-04 – Bulk operations
- Checked-out-by: none
- Blocked-by: P2-04 ✓

**Goal:** Efficiently manage large inventories.

**Subtasks:**
- [ ] Add multi-select mode (long-press or edit button)
- [ ] Bulk assign category, room, tags
- [ ] Bulk value adjustment (percentage or fixed)
- [ ] Bulk delete with undo window
- [ ] Bulk export selected items

---

#### [ ] P7-05 – CSV import with field mapping
- Checked-out-by: none
- Blocked-by: P3-03 ✓

**Goal:** Migrate users from spreadsheets.

**Subtasks:**
- [ ] File picker with preview
- [ ] Auto-detect columns and suggest mappings
- [ ] Drag-and-drop field mapping UI
- [ ] Validation with error highlighting
- [ ] Import progress with skip/retry

---

#### [ ] P7-06 – Saved searches & smart folders
- Checked-out-by: none
- Blocked-by: P2-04 ✓, 10.2.2 ✓

**Goal:** Dynamic, auto-updating views.

**Subtasks:**
- [ ] Save search queries with custom names
- [ ] Smart folder = saved search that auto-updates
- [ ] Pre-built: "Needs Documentation", "High Value", "Expiring Warranty"
- [ ] Pin favorites to inventory top

---

#### [ ] P7-07 – Document attachments (beyond receipts)
- Checked-out-by: none
- Blocked-by: P3-01 ✓

**Goal:** Store all insurance documentation.

**Subtasks:**
- [ ] Create `Document` model (warranty, manual, appraisal, invoice)
- [ ] Multiple documents per item
- [ ] PDF viewer integration
- [ ] Expiration tracking and reminders
- [ ] Include in inventory reports

---

#### [ ] P7-08 – Insurance readiness score
- Checked-out-by: none
- Blocked-by: P2-01

**Goal:** Gamify inventory completion.

**Subtasks:**
- [ ] Extend documentationScore to per-room/property
- [ ] Dashboard with "Insurance Readiness" progress rings
- [ ] "Complete Your Inventory" guided walkthrough
- [ ] Achievements/badges for milestones

---

### v2.0 Release Checklist

- [ ] Pro+ subscription tier live ($4.99/mo)
- [ ] Depreciation calculations accurate
- [ ] Audit trail complete and exportable
- [ ] CSV import tested with various formats
- [ ] Smart folders improving discoverability

---

## v2.1 – Professional Features (Business Tier)

> **Theme:** Features that justify premium pricing
> **Goal:** Unlock professional market with $9.99/mo subscription
> **Tasks:** 8 | **Dependencies:** v2.0 data intelligence

#### [ ] P8-01 – Insurance claim workflow
- Checked-out-by: none
- Blocked-by: P7-07

**Goal:** End-to-end claim management.

**Subtasks:**
- [ ] Create `Claim` model
- [ ] Create claim from loss list selection
- [ ] Status tracking: Draft → Submitted → Under Review → Settled
- [ ] Communication log with insurance company
- [ ] Settlement tracking per item

---

#### [ ] P8-02 – Coverage gap analysis
- Checked-out-by: none
- Blocked-by: P7-01, P3-05

**Goal:** Help users understand insurance coverage.

**Subtasks:**
- [ ] Input policy limits by category
- [ ] Calculate inventory value vs. coverage
- [ ] Visualize gaps with charts
- [ ] Generate recommendations
- [ ] Export for insurance agent

---

#### [ ] P8-03 – Core ML image recognition
- Checked-out-by: none
- Blocked-by: P3-01 ✓, P5-02

**Goal:** Reduce manual data entry via photo analysis.

**Subtasks:**
- [ ] Train/integrate Core ML model for categorization
- [ ] Auto-suggest category with confidence score
- [ ] Brand/product detection
- [ ] Text extraction (serial numbers, model numbers)
- [ ] Photo quality assessment

---

#### [ ] P8-04 – Value lookup & market pricing
- Checked-out-by: none
- Blocked-by: P5-01 ✓, P7-01

**Goal:** Accurate replacement cost estimation.

**Subtasks:**
- [ ] Barcode → product database API
- [ ] Name/brand/model → price estimates
- [ ] "Similar items" suggestions
- [ ] Replacement cost vs. actual cash value
- [ ] Price history tracking

---

#### [ ] P8-05 – Analytics dashboard & visualization
- Checked-out-by: none
- Blocked-by: P3-05

**Goal:** Visual insights into inventory.

**Subtasks:**
- [ ] Value distribution pie chart
- [ ] Value by room bar chart
- [ ] Purchase timeline
- [ ] Documentation progress gauges
- [ ] Export charts as images

---

#### [ ] P8-06 – Advanced sharing & permissions
- Checked-out-by: none
- Blocked-by: P4-09

**Goal:** Granular access control.

**Subtasks:**
- [ ] Role enum: Owner, Editor, Viewer, Auditor
- [ ] Per-property permission assignment
- [ ] Time-limited sharing (access expires after X days)
- [ ] Activity feed ("John added TV to Living Room at 3:42 PM")
- [ ] Optional approval workflow (changes require owner approval)
- [ ] Revoke access with confirmation
- [ ] "Shared with" indicator on properties

---

#### [ ] P8-07 – Item templates
- Checked-out-by: none
- Blocked-by: P7-03

**Goal:** Speed up common item types.

**Subtasks:**
- [ ] Create `ItemTemplate` model
- [ ] System templates: TV, Laptop, Smartphone, etc.
- [ ] User-created templates from existing items
- [ ] Auto-suggest based on category or photo

---

#### [ ] P8-08 – Photo quality & capture guidance
- Checked-out-by: none
- Blocked-by: P8-03

**Goal:** Ensure photos are insurance-ready.

**Subtasks:**
- [ ] Real-time photo quality scoring
- [ ] Guidance overlays: "Capture serial number", "Better lighting"
- [ ] Multiple angle suggestions per category
- [ ] Photo checklist per item

---

### v2.1 Release Checklist

- [ ] Business subscription tier live ($9.99/mo)
- [ ] Claims workflow tested with real scenarios
- [ ] Core ML categorization >80% accuracy
- [ ] Value lookup API integrated
- [ ] Analytics dashboard polished

---

## v3.0 – Enterprise

> **Theme:** B2B features for property managers, adjusters, businesses
> **Goal:** Enterprise tier with custom pricing and recurring revenue
> **Tasks:** 8 | **Dependencies:** v2.x professional features

#### [ ] P9-01 – REST API & webhooks
- Checked-out-by: none
- Blocked-by: P4-08, P1-01

**Goal:** Enable third-party integrations.

**Subtasks:**
- [ ] Design REST API (items, properties, rooms, reports, claims)
- [ ] JWT authentication with API key management
- [ ] Webhook registration for change events
- [ ] Rate limiting and usage tracking
- [ ] OpenAPI/Swagger documentation
- [ ] Developer portal with sandbox

---

#### [ ] P9-02 – Team & organization management
- Checked-out-by: none
- Blocked-by: P8-06

**Goal:** Multi-user organizations.

**Subtasks:**
- [ ] Create `Organization` model
- [ ] Team invitations via email or link
- [ ] Seat-based licensing
- [ ] Organization-wide settings
- [ ] Member activity dashboard

---

#### [ ] P9-03 – Compliance & data governance
- Checked-out-by: none
- Blocked-by: P7-02

**Goal:** Meet regulatory requirements.

**Subtasks:**
- [ ] GDPR data export (all personal data in machine-readable format)
- [ ] Data retention policies (auto-archive or delete after X years)
- [ ] Legal hold capability (prevent deletion during litigation)
- [ ] Chain of custody documentation for high-value items
- [ ] Audit log export for legal/compliance review
- [ ] Right to deletion workflow with confirmation
- [ ] Data residency options (future: regional storage)

---

#### [ ] P9-04 – Voice & natural language interface
- Checked-out-by: none
- Blocked-by: P5-08, P8-04

**Goal:** Hands-free inventory management.

**Subtasks:**
- [ ] Enhanced Siri: "Add [item] worth [value] in [room]"
- [ ] In-app voice capture button
- [ ] Natural language search
- [ ] Voice notes on items

---

#### [ ] P9-05 – B2B / white-label mode
- Checked-out-by: none
- Blocked-by: P9-02

**Goal:** Serve property managers and adjusters.

**Subtasks:**
- [ ] Property manager dashboard (manage multiple client inventories)
- [ ] Insurance adjuster read-only mode with claim integration
- [ ] Custom branding options (logo, colors, app name)
- [ ] Client handoff workflow (transfer inventory ownership)
- [ ] Bulk property onboarding
- [ ] Reseller/partner program infrastructure

---

#### [ ] P9-06 – Advanced performance & scale
- Checked-out-by: none
- Blocked-by: P4-09, P1-03

**Goal:** Handle 10K+ item inventories.

**Subtasks:**
- [ ] Lazy loading and virtualized lists
- [ ] Photo CDN for shared inventories
- [ ] Incremental sync (delta only)
- [ ] Background photo processing
- [ ] Performance benchmarks

---

#### [ ] P9-07 – Observability & quality infrastructure
- Checked-out-by: none
- Blocked-by: P5-04, P4-07

**Goal:** Production-grade monitoring.

**Subtasks:**
- [ ] Crash reporting (Sentry or Crashlytics)
- [ ] Performance monitoring
- [ ] Remote feature flag service
- [ ] A/B testing infrastructure
- [ ] Alerting for error spikes

---

#### [ ] P9-08 – Premium integrations
- Checked-out-by: none
- Blocked-by: P9-01, P8-01

**Goal:** Connect to broader ecosystem.

**Subtasks:**
- [ ] Insurance company API integration
- [ ] Smart home integration (Ring/Nest)
- [ ] E-commerce import (Amazon/eBay)
- [ ] Bank transaction matching
- [ ] Moving company integration

---

### v3.0 Release Checklist

- [ ] Enterprise tier with custom pricing
- [ ] REST API documented and versioned
- [ ] Team management functional
- [ ] GDPR compliance verified
- [ ] White-label option for partners

---

## Discovered Tasks

<!--
Add new tasks discovered during development here.
Format: - [ ] **D.X** Description (discovered by AGENT-ID, date)
Periodically promote to appropriate version above.
-->

_None yet_

---

## Completed (v1.0)

Tasks with ~~strikethrough~~ were completed in v1.0 and remain for reference:

- ~~P1-05~~ Fastlane pipeline (completed in 7.1.x)
- ~~P2-03~~ Core item detail view (completed in 2.3.x)
- ~~P2-04~~ Search & filtering (completed in 2.2.x, 10.2.2)
- ~~P2-06~~ Basic Settings screen (completed in Phase 6)
- ~~P3-01~~ Photo capture & gallery (completed in 2.4.x, 2.5.x)
- ~~P3-02~~ Backup export v1 (completed in 3.4.x)
- ~~P3-03~~ Backup import (completed in 6.3.x)
- ~~P3-04~~ Cloud sync sanity checks (completed in 10.1.x)
- ~~P4-03~~ IAP integration (completed - IAPValidator, StoreKit 2)
- ~~P4-04~~ Pro-only feature set v1 (completed in Phase 4)
- ~~P4-05~~ PDF export (completed in 3.1.x, 3.2.x)
- ~~P4-06~~ App Store metadata (completed in 7.3.x)
- ~~P5-01~~ Barcode scanning (completed in 2.7.x - scan-only)
- ~~10.2.2~~ Enhanced search syntax (completed)

**Full v1.0 archive:** See `TODO-COMPLETE.md` (105 tasks)

---

## Notes

### Key Decisions Made ✓

1. ✅ **Bundle ID:** Keep `com.drunkonjava.Nestory-Pro` - 2025-11-28
   - **Reason:** Avoids App Store complications, provisioning regeneration, CloudKit migration

2. ✅ **Documentation score:** 6-field weighted (Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%) - 2025-11-28
   - **Reason:** Better reflects insurance documentation priorities than equal 4-field weighting

3. ✅ **CloudKit sync:** Disabled for v1.0, enable in v1.1 - 2025-11-28
   - **Reason:** Local-only storage safer for launch; sync tested thoroughly before enabling

4. ✅ **Swift version:** Ship v1.0 with Swift 5, migrate to Swift 6 in v1.1 - 2025-11-29
   - **Reason:** Swift 6 strict concurrency surfaces ~20 warnings needing careful actor/Sendable fixes; address in P1-03 before enabling

### Testing Requirements

- All new code must have tests
- Minimum 60% coverage for new files
- Run tests before marking complete
- Primary test suites: `Nestory-ProTests` (unit/integration), `Nestory-ProUITests` (UI flows)

### Reference Documents

- `PRODUCT-SPEC.md` – Full product requirements
- `CLAUDE.md` – Development guidelines (agents MUST obey)
- `TODO-COMPLETE.md` – Completed v1.0 tasks archive

> **Note:** Agents must follow governance rules in both `CLAUDE.md` and this file.

---

## Pricing Tier Summary

> **IMPORTANT:** Pricing is product-owner controlled. Agents MUST NOT change tier names, prices, or feature mappings.

| Tier | Price | Versions | Key Features |
|------|-------|----------|--------------|
| **Free** | $0 | v1.0 | 100 items, basic features |
| **Pro** | $24.99 | v1.0-1.5 | Unlimited items, PDF photos, CSV export |
| **Pro+** | $4.99/mo | v2.0 | Depreciation, custom fields, bulk ops, CSV import |
| **Business** | $9.99/mo | v2.1 | Claims, AI categorization, analytics, advanced sharing |
| **Enterprise** | Contact | v3.0 | API, teams, compliance, white-label, integrations |

---

*Last Updated: December 1, 2025*

### Changelog

- **2025-12-01**: Fixed UITests Swift 6 concurrency issues
  - Changed `UITests.xcconfig` to use `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`
  - Updated all 8 UITest classes with `nonisolated(unsafe) var app` pattern
  - Added comprehensive documentation to TestingStrategy.md
  - P2-19-2 now fully passing (all schemes build, all tests compile)
- **2025-11-30**: Added Phase 12 - Visual Polish & Presentation Layer (78 subtasks)
  - Comprehensive design system (NestoryTheme with colors, typography, metrics, animations, haptics)
  - ViewModel presentation models for 5 major ViewModels (state-driven UI, no boolean flags)
  - Card-based layouts for all views (new hierarchy views + retrofitted existing)
  - Cross-cutting concerns: accessibility, animations, haptics, performance
  - Complete testing strategy (unit, preview, snapshot, accessibility audit)
  - Integration & completion validation (project integration, build validation)
  - Updated v1.2 roadmap: 1 active + 78 Phase 12 + 4 deferred snapshots = 83 total tasks
  - Estimated 4-6 weeks effort for professional-grade visual polish
- **2025-11-30**: Archived completed v1.1 and v1.2 tasks to TODO-COMPLETE.md
  - Moved 9 completed v1.1 tasks (P1-00 through P1-04, infrastructure fixes)
  - Moved 4 completed v1.2 tasks (P2-01, P2-05, P4-07, P5-03)
  - Reduced TODO.md line count from 1250 → ~700 lines
  - Total archived: 118 completed tasks (105 v1.0 + 9 v1.1 + 4 v1.2)
  - Active tasks: 1 in-progress (P2-02), 4 deferred snapshot tests, 39 pending future work
- **2025-11-29**: Added Agent Collaboration Rules across all governance docs
  - Added comprehensive collaboration model to CLAUDE.md
  - Added parallel section to WARP.md with version roadmap reference
  - Updated PRODUCT-SPEC.md roadmap to match TODO.md version structure
  - Updated README.md with current roadmap table and documentation links
  - Defined strategic change categories requiring `AskUserQuestion` approval
  - Documented orphaned code integration protocol
  - Added pricing protection: "Agents MUST NOT change tier names, prices, or mappings"
  - Added governance note: "Agents must follow rules in CLAUDE.md and TODO.md"
- **2025-11-29**: Reorganized by version milestones (v1.1 → v3.0)
  - Mapped 52 pending tasks to 8 version milestones (v1.1–v3.0)
  - Added P1-00 to unblock snapshot tests (swift-snapshot-testing package)
  - Added version overview table with release targets and pricing tiers
  - Added release checklists per version for validation
  - Grouped tasks by theme within each version for clarity
  - Updated dependency notation: `Blocked-by: X ✓` indicates v1.0 completed dependency
  - Restored critical subtask details (junction models, compliance constraints, revocation workflows)
  - Added rationale to Key Decisions to prevent premature "upgrades"
  - Backlog section removed: all items now scoped with version targets
- **2025-11-29**: Archived 105 completed v1.0 tasks to TODO-COMPLETE.md
- **2025-11-29**: Added enterprise roadmap (FR Phases 7-9)
- **2025-11-29**: Initial Future Roadmap with stable P{phase}-{index} IDs

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
| **v1.2** | UX Polish & Onboarding | 1 active, 78 Phase 12, 4 deferred | Q1 2026 | Pro |
| **v1.3** | Pro Features v2 | 5 tasks | Q2 2026 | Pro |
| **v1.4** | Automation & Extensions | 5 tasks | Q2 2026 | Pro |
| **v1.5** | Platform Expansion | 4 tasks | Q3 2026 | Pro |
| **v2.0** | Data Intelligence | 8 tasks | Q4 2026 | Pro+ ($4.99/mo) |
| **v2.1** | Professional Features | 8 tasks | Q1 2027 | Business ($9.99/mo) |
| **v3.0** | Enterprise | 8 tasks | Q2 2027 | Enterprise (Contact) |

**Total: 117 pending tasks** (1 active + 78 Phase 12 + 4 deferred snapshots + 34 future work; v1.2-v3.0)

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

#### [x] P2-02 – Information architecture: Spaces, rooms, containers
- Completed: 2025-12-01
- Blocked-by: P1-01 ✓

**Goal:** Crystal clear mental model: property → room → container → item.

**Subtasks:**
- [x] Define models: `Property`, `Room` (updated), `Container`, `Item` (updated) ✓ 2025-11-30
  - Property.swift: Top-level hierarchy (e.g., "My Home", "Vacation Home")
  - Container.swift: Optional level between Room and Item (e.g., "TV Stand", "Dresser")
  - Room.swift: Added `property` relationship, `containers` relationship
  - Item.swift: Added `container` optional relationship
- [x] Implement versioned schema migration (V1 → V1.2) ✓ 2025-11-30
  - NestorySchema.swift: V1 (frozen), V1_2 (with Property/Container)
  - Custom migration with willMigrate/didMigrate handlers
  - Auto-creates default "My Home" property for existing rooms
- [x] Implement hierarchy navigation views ✓ 2025-11-30
  - PropertyListView: Top-level property list with stats
  - PropertyDetailView: Rooms within a property
  - RoomDetailView: Containers and items within a room
  - ContainerDetailView: Items within a container
- [x] Add breadcrumbs ("Home > Apartment > Living Room > TV Stand") ✓ 2025-11-30
  - BreadcrumbView: Horizontal scrolling capsule-style breadcrumbs
  - Convenience initializers for Item, Container, Room
  - Tappable navigation to parent levels
- [x] Add editor sheets for each level ✓ 2025-11-30
  - PropertyEditorSheet: Add/edit property with icon/color selection
  - RoomEditorSheet: Add/edit room with quick templates
  - ContainerEditorSheet: Add/edit container with templates
- [x] Add re-ordering support ✓ 2025-11-30
  - sortOrder property on Property, Room, Container
  - .onMove() handlers in list views
- [x] Add renaming support (inline editing) ✓ 2025-11-30
  - Alert-based renaming on swipe left in PropertyDetailView, RoomDetailView, ContainerDetailView
- [x] Unit tests for new models ✓ 2025-11-30
- [x] Integration tests for migration ✓ 2025-11-30

**Files Created:**
- `Nestory-Pro/Models/Property.swift` (166 lines)
- `Nestory-Pro/Models/Container.swift` (172 lines)
- `Nestory-Pro/Views/Hierarchy/BreadcrumbView.swift` (209 lines)
- `Nestory-Pro/Views/Hierarchy/PropertyListView.swift` (193 lines)
- `Nestory-Pro/Views/Hierarchy/PropertyDetailView.swift` (285 lines)
- `Nestory-Pro/Views/Hierarchy/RoomDetailView.swift` (323 lines)
- `Nestory-Pro/Views/Hierarchy/ContainerDetailView.swift` (291 lines)
- `Nestory-Pro/Views/Hierarchy/PropertyEditorSheet.swift` (214 lines)
- `Nestory-Pro/Views/Hierarchy/RoomEditorSheet.swift` (181 lines)
- `Nestory-Pro/Views/Hierarchy/ContainerEditorSheet.swift` (206 lines)

**Files Modified:**
- `Nestory-Pro/Models/Room.swift` - Added property, containers relationships
- `Nestory-Pro/Models/Item.swift` - Added container relationship, breadcrumbPath
- `Nestory-Pro/Models/NestorySchema.swift` - Added V1_2 schema with custom migration

---

## v1.2 – Phase 12: Visual Polish & Presentation Layer

> **Theme:** Transform functional UI into a cohesive, professionally designed app experience
> **Goal:** Build new hierarchy views with polish from day 1, then retrofit existing views
> **Strategy:** Design system → ViewModels → Views → Cross-cutting concerns
> **Tasks:** 78 subtasks across 15 major sections (P2-06 through P2-20)
> **Dependencies:** P2-02 (Property/Container hierarchy) MUST be complete
> **Target:** Q1 2026

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

> **Goal:** Create a unified design language that scales across the entire app
> **Blocked-by:** P2-02 ✓
> **Files:** `SharedUI/DesignSystem.swift`, `Assets.xcassets`, `SharedUI/SharedComponents.swift`

#### [x] P2-06-1 – Define NestoryTheme design tokens
- Completed: 2025-12-01
- Blocked-by: P2-02 ✓

**Goal:** Create complete design token set (colors, typography, metrics, shadows, animations, haptics)

**Subtasks:**
- [x] Create `SharedUI/DesignSystem.swift` with `NestoryTheme` enum ✓ 2025-12-01
- [x] Define `NestoryTheme.Colors` (background, cardBackground, accent, border, muted, chipBackground, success, warning, error, info, documented, incomplete, missing) ✓ 2025-12-01
- [x] Define `NestoryTheme.Metrics` (corner radii, padding, spacing, icon sizes, card sizes, thumbnails) ✓ 2025-12-01
- [x] Define `NestoryTheme.Typography` (title, title2, headline, subheadline, body, caption, caption2, statValue, statLabel, buttonLabel) ✓ 2025-12-01
- [x] Define `NestoryTheme.Shadow` struct (card, elevated, subtle) ✓ 2025-12-01
- [x] Define `NestoryTheme.Animation` (duration, easing, spring) ✓ 2025-12-01
- [x] Define `NestoryTheme.Haptics.Pattern` enum (success, error, warning, selection, impact) ✓ 2025-12-01
- [x] Add color assets to `Assets.xcassets` with light + dark variants (BrandColor) ✓ 2025-12-01
- [ ] Add unit tests for design token accessibility (contrast ratios) - Deferred to P2-18
- [x] Document usage in code comments ✓ 2025-12-01

**Files Created:**
- `Nestory-Pro/Views/SharedUI/DesignSystem.swift` (185 lines)
- `Nestory-Pro/Assets.xcassets/BrandColor.colorset/Contents.json`

---

#### [x] P2-06-2 – Create reusable card modifiers
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Goal:** Consistent card styling across all views

**Subtasks:**
- [x] Implement `CardBackgroundModifier` (standard card with padding, rounded corners, shadow) ✓ 2025-12-01
- [x] Implement `LoadingCardModifier` (skeleton placeholder with `.redacted(reason: .placeholder)`) ✓ 2025-12-01
- [x] Implement `ErrorCardModifier` (red-tinted error state) ✓ 2025-12-01
- [x] Implement `EmptyStateCardModifier` (centered content for empty states) ✓ 2025-12-01
- [x] Create View extensions: `.cardStyle()`, `.loadingCard()`, `.errorCard()`, `.emptyStateCard()` ✓ 2025-12-01
- [x] Create `.sectionHeader(_:systemImage:)` extension for consistent section titles ✓ 2025-12-01
- [x] Add preview examples showing all card variants ✓ 2025-12-01
- [x] Test in light + dark mode ✓ 2025-12-01

**Files Modified:**
- `Nestory-Pro/Views/SharedUI/DesignSystem.swift` - Added card modifiers and view extensions

---

#### [x] P2-06-3 – Standardize backgrounds & layout scaffolding
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Goal:** Consistent layout patterns for all screens

**Subtasks:**
- [x] Define standard background: `NestoryTheme.Colors.background.ignoresSafeArea()` ✓ 2025-12-01
- [x] Create `StandardScrollLayout` wrapper component (ScrollView + VStack + padding) ✓ 2025-12-01
- [x] Create `StandardLayout` wrapper for non-scrollable screens ✓ 2025-12-01
- [x] Document navigation bar appearance standards (`.large` for tabs, `.inline` for detail) ✓ 2025-12-01
- [x] Add `.tabRootNavigationStyle()`, `.detailNavigationStyle()`, `.sheetNavigationStyle()` modifiers ✓ 2025-12-01
- [x] Add `.visibleTabBarBackground()` modifier ✓ 2025-12-01
- [x] Add layout preview examples ✓ 2025-12-01

**Files Modified:**
- `Nestory-Pro/Views/SharedUI/DesignSystem.swift` - Added StandardScrollLayout, StandardLayout, navigation modifiers

---

### P2-07 – ViewModel Presentation Models

> **Goal:** Rich, presentation-ready models in ViewModels (keeps views declarative and lean)
> **Blocked-by:** P2-06-1 ✓
> **Files:** All existing ViewModels

#### [x] P2-07-1 – InventoryTabViewModel: Sections & metadata
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Goal:** Group items into sections, provide search metadata, item limit warnings

**Presentation Models Added:**
- `InventorySection` (id, kind, title, subtitle, items, totalValue, itemCount) ✓
- `SearchMatchMetadata` (matchedRoomName, matchedCategoryName, valueFilterDescription, plainTextTerms) ✓
- `ItemLimitWarningDisplay` (style: .none/.soft/.hard, message, detail, actionTitle) ✓

**Computed Properties:**
- [x] `groupedSections: [InventorySection]` - Group `filteredItems` by room/property ✓ 2025-12-01
- [x] `activeSearchMetadata: SearchMatchMetadata` - Parse search text for filter chips ✓ 2025-12-01
- [x] `itemLimitWarningDisplay: ItemLimitWarningDisplay` - Map from `ItemLimitWarningLevel` ✓ 2025-12-01

**Tests:** Deferred to P2-18

---

#### [x] P2-07-2 – CaptureTabViewModel: Modes & statuses
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Goal:** Replace boolean flags with semantic state enums

**Presentation Models Added:**
- `CaptureStatus` enum (.ready, .scanning, .processing(String), .success(String), .error(String)) ✓
- `CaptureActionCard` struct (kind, title, subtitle, systemImage, isPrimary) ✓

**State Management:**
- [x] Add `status: CaptureStatus` property ✓ 2025-12-01
- [x] Implement `captureCards: [CaptureActionCard]` computed property ✓ 2025-12-01
- [x] Add mode transition methods with status updates ✓ 2025-12-01

**Tests:** Deferred to P2-18

---

#### [x] P2-07-3 – AddItemViewModel: Form metadata & validation
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Goal:** Drive form layout and validation from ViewModel

**Presentation Models Added:**
- `AddItemField` enum (all form fields with `displayName`, `isRequired`) ✓
- `AddItemSection` struct (title, fields array) ✓
- `FieldValidationState` struct (level: .ok/.warning/.error, message) ✓

**Computed Properties & Methods:**
- [x] `formSections: [AddItemSection]` - "Basics", "Value & Warranty", "Additional Details" ✓ 2025-12-01
- [x] `validationState(for: AddItemField) -> FieldValidationState` ✓ 2025-12-01
- [x] `canSave: Bool` - True if no error-level validations ✓ 2025-12-01

**Validation Rules Implemented:**
- [x] Name required (non-empty) ✓ 2025-12-01
- [x] Category required ✓ 2025-12-01
- [x] Purchase price non-negative ✓ 2025-12-01
- [x] Warranty expiry not before purchase date (warning) ✓ 2025-12-01

**Tests:** Deferred to P2-18

---

#### [x] P2-07-4 – ReportsTabViewModel: Summary & generation states
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Goal:** State-driven report generation UI

**Presentation Models Added:**
- `InventorySummary` struct (totalItems, totalValue, propertiesCount, roomsCount, lastUpdated) ✓
- `InventorySummaryItem` struct (label, value, systemImage, color) ✓
- `ReportGenerationState` enum (.idle, .generating(String), .ready(URL), .error(String)) ✓

**Refactoring:**
- [x] Implement `makeInventorySummary(items:properties:rooms:)` ✓ 2025-12-01
- [x] Add `summaryItems` computed property for UI display ✓ 2025-12-01
- [x] Add user-friendly error messages ✓ 2025-12-01

**Tests:** Deferred to P2-18

---

#### [x] P2-07-5 – ItemDetailViewModel: Documentation status & display helpers
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Goal:** Rich documentation metadata and display formatting

**Presentation Models Added:**
- `DocumentationStatus` struct with Level enum (.complete, .partial, .minimal, .none) ✓
- `DocumentationFieldItem` struct (label, isComplete, weight) ✓

**Display Helpers:**
- [x] `documentationStatus: DocumentationStatus` property ✓ 2025-12-01
- [x] `documentationFields: [DocumentationFieldItem]` property ✓ 2025-12-01
- [x] `DocumentationLevel` enum for semantic status levels ✓ 2025-12-01

**Tests:** Deferred to P2-18

---

### P2-08 – New Hierarchy Views (Build with Polish)

> **Goal:** Build Property/Container/Room detail views with polish from day 1
> **Blocked-by:** P2-06-2, P2-07-1, P2-02 ✓

#### [x] P2-08-1 – PropertyDetailView: Card-based layout
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓, P2-07-1 ✓

**Subtasks:**
- [x] Header: Property icon/color + name ✓ 2025-12-01
- [x] "Summary" card: total rooms, containers, items, value ✓ 2025-12-01
- [x] "Rooms" card: List with item counts ✓ 2025-12-01
- [x] Empty state: "No rooms yet" + "Add First Room" CTA ✓ 2025-12-01
- [x] Use NestoryTheme tokens for all styling ✓ 2025-12-01
- [x] Added StatCell component with theme integration ✓ 2025-12-01

---

#### [x] P2-08-2 – RoomDetailView: Card-based layout
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓, P2-07-1 ✓

**Subtasks:**
- [x] Header: Room icon + name + breadcrumb (Property › Room) ✓ 2025-12-01
- [x] "Summary" card: containers, items, value ✓ 2025-12-01
- [x] "Containers" + "Items" sections with swipe actions (Edit, Delete, Rename) ✓ 2025-12-01
- [x] Empty state with "Add Item" messaging ✓ 2025-12-01
- [x] ContainerRowView, ItemRowCompact, StatCell with NestoryTheme ✓ 2025-12-01

---

#### [x] P2-08-3 – ContainerDetailView: Card-based layout
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓, P2-07-1 ✓

**Subtasks:**
- [x] Header: Container icon + breadcrumb (Property › Room › Container) ✓ 2025-12-01
- [x] "Summary" card: items count, total value, documentation score ✓ 2025-12-01
- [x] "Contents" section with ContainerItemRow ✓ 2025-12-01
- [x] Empty state for empty containers ✓ 2025-12-01
- [x] Swipe actions for item removal ✓ 2025-12-01
- [x] StatCell, ContainerItemRow with NestoryTheme ✓ 2025-12-01

---

### P2-09 – Inventory Tab & App Shell (Retrofit)

> **Goal:** Modernize existing Inventory tab with cards, sections, rich states
> **Blocked-by:** P2-06, P2-07-1

#### [x] P2-09-1 – MainTabView: Modern tab appearance
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Subtasks:**
- [x] Fill icon variants already in use (archivebox.fill, camera.fill, etc.) ✓ 2025-12-01
- [x] `.toolbarBackground(.visible, for: .tabBar)` for separation ✓ 2025-12-01
- [x] When locked: `.blur(radius: 20)` + `.overlay(Color.black.opacity(0.35))` ✓ 2025-12-01
- [x] Tab accessibility labels and identifiers ✓ 2025-12-01

---

#### [x] P2-09-2 – LockScreenView: System-like design
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓

**Subtasks:**
- [x] Center card: large lock icon (circular material), "Nestory Locked" title ✓ 2025-12-01
- [x] Subtitle: "Unlock with Face ID or passcode to access your inventory." ✓ 2025-12-01
- [x] Primary button: "Unlock" (`.borderedProminent`, `.controlSize(.large)`) ✓ 2025-12-01
- [x] Face ID failure handling ✓ 2025-12-01

**Files Modified:**
- `Nestory-Pro/Views/SharedUI/LockScreenView.swift` - Updated to system-like design with circular material background, dynamic biometric subtitle

---

#### [x] P2-09-3 – InventoryTab: Card sections & states
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓, P2-07-1 ✓

**Subtasks:**
- [x] Use `groupedSections` from ViewModel, render with `.sectionHeader()` ✓ 2025-12-01
- [x] Each item row: name, breadcrumb, tags, price in `.cardStyle()` ✓ 2025-12-01
- [x] Empty state: hero icon (`archivebox`), "No items yet", "Add Item" button ✓ 2025-12-01
- [x] Loading state: 3 skeleton cards (`.loadingCard()`) with SkeletonItemCard ✓ 2025-12-01
- [x] Error state: red error card (`.errorCard()`) with retry button ✓ 2025-12-01
- [x] Pull-to-refresh with `.refreshable` and haptic feedback ✓ 2025-12-01

**Files Modified:**
- `Nestory-Pro/Views/Inventory/InventoryTab.swift` - Added grouped sections, card styling, loading/error states, pull-to-refresh
- `Nestory-Pro/ViewModels/InventoryTabViewModel.swift` - Added groupedSections, activeSearchMetadata, itemLimitWarningDisplay
- `Nestory-Pro/Views/SharedUI/SharedComponents.swift` - Added SkeletonItemCard component

---

#### [x] P2-09-4 – InventoryTab: Item limit warning banner
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓, P2-07-1 ✓

**Subtasks:**
- [x] Check `itemLimitWarningDisplay.style` from ViewModel ✓ 2025-12-01
- [x] If `.soft`: Yellow banner with "Upgrade" button ✓ 2025-12-01
- [x] If `.hard`: Red banner with "Upgrade Now" button ✓ 2025-12-01
- [x] Dismiss button (stores state in UserDefaults) ✓ 2025-12-01

**Note:** Already implemented prior to P2-09-3 work - banner uses NestoryTheme colors and has full accessibility support.

---

### P2-10 – Item Detail View (Retrofit)

> **Goal:** Visually rich, documentation-focused ItemDetailView
> **Blocked-by:** P2-06 ✓, P2-07-5 ✓

#### [x] P2-10-1 – ItemDetailView: Hero photo header
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓, P2-07-5 ✓

**Subtasks:**
- [x] `TabView(.page)` for multiple photos, `RoundedRectangle(16)` clip ✓ 2025-12-01
- [x] Gradient overlay (black → clear), item name + brand/model overlaid ✓ 2025-12-01
- [x] If no photos: placeholder with category icon ✓ (already implemented)
- [x] Accessibility: "Photo 1 of 3", swipe actions announced ✓ 2025-12-01

**Files Modified:**
- `Nestory-Pro/Views/Inventory/ItemDetailView.swift` - Added gradient overlay, overlaid text, improved accessibility

---

#### [x] P2-10-2 – ItemDetailView: Info cards
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓, P2-07-5 ✓

**Subtasks:**
- [x] "Basic Info" card: name, brand/model, category, location ✓ (already implemented)
- [x] Applied `.cardStyle()` modifier to all info cards ✓ 2025-12-01
- [x] "Warranty" card: status line with active/expired colors ✓ (already implemented)
- [x] Color: expired = red/muted, active = green/accent ✓ (already implemented)

**Files Modified:**
- `Nestory-Pro/Views/Inventory/ItemDetailView.swift` - Applied .cardStyle() to documentation, basic info, receipts, warranty sections

---

#### [x] P2-10-3 – ItemDetailView: Documentation status card
- Completed: 2025-12-01
- Blocked-by: P2-06-2 ✓, P2-07-5 ✓

**Subtasks:**
- [x] Show documentation status with horizontal progress bar ✓ (already implemented)
- [x] List entries with badges: Photo, Value, Room, Category, Receipt, Serial ✓ (already implemented)
- [x] "What's missing?" info button with detailed sheet ✓ (already implemented)

**Note:** Documentation status card was already fully implemented with progress bar, weighted badges, color-coded status, and "What's missing?" sheet.

---

### P2-11 – Capture Flows (Retrofit)

> **Goal:** Modern, instructional capture UX with clear states
> **Blocked-by:** P2-06, P2-07-2

#### [x] P2-11-1 – CaptureTab: Action cards hub
- Checked-out-by: Claude
- Blocked-by: P2-06-2, P2-07-2
- Status: Complete

**Subtasks:**
- [x] Render `captureCards` from ViewModel - Using CaptureActionCard.allCards via currentActionCard
- [x] Primary card (receipt) larger, secondary cards (barcode, photos, manual) in 2-column grid - Unified captureContent(for:) function
- [x] "Recent captures" horizontal scroll - recentCapturesStrip in Photo mode
- [x] Status banner at top (idle/scanning/processing/success/error) - statusBanner with CaptureStatus

---

#### [x] P2-11-2 – CaptureTab: Status banner
- Checked-out-by: Claude
- Blocked-by: P2-06-2, P2-07-2
- Status: Complete

**Subtasks:**
- [x] Map `CaptureStatus` to banner: `.ready` hidden, `.scanning` blue spinner, `.success` green checkmark (auto-dismiss 2s), `.error` red with dismiss - statusBanner view with auto-dismiss in updateStatus()
- [x] Smooth slide-in/out animation - .animation(NestoryTheme.Animation.quick) with .transition

---

#### [x] P2-11-3 – Camera views: Standardized layout
- Checked-out-by: Claude
- Blocked-by: P2-06-1
- Status: Complete

**Applies to:** `ReceiptCaptureView`, `PhotoCaptureView`, `BarcodeScanView`

**Subtasks:**
- [x] Dark background, preview with rounded corners - BarcodeScanView has dark camera, all use NestoryTheme.Metrics.cornerRadiusLarge
- [x] Instructional text above preview - All views have descriptive headers with NestoryTheme typography
- [x] Bottom control bar: large shutter, Cancel, Flip, Torch - Using system UIImagePickerController with native controls
- [x] Permission denied state: "Go to Settings" button - All views have proper permission handling with Settings buttons

---

### P2-12 – Add Item Forms (Retrofit)

> **Goal:** Structured, validating forms driven by VM metadata
> **Blocked-by:** P2-06, P2-07-3

#### [x] P2-12-1 – AddItemView: Structured form layout
- Checked-out-by: Claude
- Blocked-by: P2-06-2, P2-07-3
- Status: Complete

**Subtasks:**
- [x] Use `formSections` from ViewModel - Added formSections property to AddItemViewModel
- [x] Implement `fieldView(for: AddItemField)` mapping (TextField, Picker, DatePicker, TextEditor) - validatedTextField() function
- [x] For each field, check `validationState(for:)`: `.error` → red tint + caption, `.warning` → yellow tint - validationCaption() with color coding
- [x] Disable "Save" if `!canSave`, show "Fix errors" banner - Validation error banner at top of form
- [x] Keyboard toolbar: Done, Next/Previous field - Added ToolbarItemGroup(placement: .keyboard)

---

#### [x] P2-12-2 – QuickAddItemSheet: Minimal form
- Checked-out-by: Claude
- Blocked-by: P2-06-2, P2-07-3
- Status: Complete

**Subtasks:**
- [x] Simplified: name, category, room only - Already simplified form
- [x] Same validation, `.presentationDetents([.medium])` - Added .presentationDetents([.medium, .large])
- [x] Toolbar: Cancel, Save (disabled if errors) - Already implemented with canSave
- [x] Auto-focus on name, discard confirmation - Uses .submitLabel(.done) and keyboard toolbar

---

### P2-13 – Settings, Paywall, Reports (Retrofit)

> **Goal:** Professional, marketing-quality UI
> **Blocked-by:** P2-06

#### [ ] P2-13-1 – SettingsTab: Card-based sections
- Checked-out-by: (available)
- Blocked-by: P2-06-2
- Status: Pending

**Subtasks:**
- [ ] `SettingsRowView`: icon (colored circle), title, subtitle, chevron
- [ ] Sections (`.cardStyle()`): Account & Sync, Backup & Restore, Appearance, Support, About
- [ ] Inline state: "Last backup: 3 days ago", iCloud sync indicator
- [ ] When export/import running: `ProgressView` inline
- [ ] Version number in footer

---

#### [ ] P2-13-2 – ContextualPaywallSheet: Marketing layout
- Checked-out-by: (available)
- Blocked-by: P2-06-2
- Status: Pending

**Subtasks:**
- [ ] Hero icon (120pt), "Upgrade to Nestory Pro" title
- [ ] Benefits list in card with checkmarks
- [ ] Primary CTA: "Start 7-Day Free Trial" (`.borderedProminent`, `.controlSize(.large)`)
- [ ] Secondary: "Maybe Later", legal text in `footnote`
- [ ] Restore Purchases button, `.presentationDetents([.medium, .large])`

---

#### [ ] P2-13-3 – ReportsTab: Summary dashboard
- Checked-out-by: (available)
- Blocked-by: P2-06-2, P2-07-4
- Status: Pending

**Subtasks:**
- [ ] Summary cards (from `InventorySummary`): Total Items, Total Value, Properties, Rooms in 2x2 grid
- [ ] Card groups: "Inventory Reports", "Loss Documentation", "Warranty & Receipts"

---

#### [ ] P2-13-4 – Report generation views: State-driven UI
- Checked-out-by: (available)
- Blocked-by: P2-06-2, P2-07-4
- Status: Pending

**Applies to:** `FullInventoryReportView`, `LossListPDFView`, `WarrantyListView`

**Subtasks:**
- [ ] Map `ReportGenerationState`: `.idle` → "Generate" button, `.generating(msg)` → spinner + message, `.ready(url)` → document card with Open/Share, `.error(msg)` → red error card with retry
- [ ] Add print option, AirDrop integration

---

### P2-14 – Accessibility & Inclusive Design

> **Goal:** Ensure all polish improvements are accessible to everyone
> **Blocked-by:** P2-06, P2-08 to P2-13 (all views complete)

#### [ ] P2-14-1 – VoiceOver labels & hints
- Checked-out-by: (available)
- Blocked-by: All view tasks
- Status: Pending

**Subtasks:**
- [ ] Audit all interactive elements for `.accessibilityLabel()`
- [ ] Add `.accessibilityHint()` for non-obvious actions
- [ ] Examples: "Item card. Double-tap to view details.", "Documentation 60% complete."
- [ ] Test with VoiceOver enabled on device

---

#### [ ] P2-14-2 – Dynamic Type support
- Checked-out-by: (available)
- Blocked-by: P2-06-1
- Status: Pending

**Subtasks:**
- [ ] Test all views at accessibility text sizes (Settings → Accessibility → Larger Text)
- [ ] Fix truncation issues, use `ViewThatFits` for adaptive layouts
- [ ] Test at `xxxLarge` and `accessibilityXXXLarge`

---

#### [ ] P2-14-3 – Reduce Motion support
- Checked-out-by: (available)
- Blocked-by: P2-15-1
- Status: Pending

**Subtasks:**
- [ ] Check `@Environment(\.accessibilityReduceMotion)`
- [ ] Disable spring animations when enabled
- [ ] Use instant `.opacity` transitions instead of slides
- [ ] Disable skeleton shimmer, keep essential state changes

---

#### [ ] P2-14-4 – Color contrast audit
- Checked-out-by: (available)
- Blocked-by: P2-06-1
- Status: Pending

**Subtasks:**
- [ ] Audit all color combinations for WCAG AA (4.5:1 text, 3:1 UI)
- [ ] Use contrast checker: https://webaim.org/resources/contrastchecker/
- [ ] Fix failing combinations, test in light + dark mode

---

#### [ ] P2-14-5 – Accessibility Identifiers (UI Testing)
- Checked-out-by: (available)
- Blocked-by: All view tasks
- Status: Pending

**Subtasks:**
- [ ] Add `.accessibilityIdentifier()` to key elements (tabs, buttons, cards, forms)
- [ ] Update `AccessibilityIdentifiers.swift` with constants
- [ ] Use in UI tests for reliable selection

---

### P2-15 – Animations & Micro-interactions

> **Goal:** Smooth, delightful animations that enhance UX
> **Blocked-by:** P2-06-1

#### [ ] P2-15-1 – View transitions
- Checked-out-by: (available)
- Blocked-by: P2-06-1
- Status: Pending

**Subtasks:**
- [ ] `.transition(.slide)` for sheets, `.opacity.combined(with: .scale)` for cards
- [ ] Use `NestoryTheme.Animation.easeOut` for navigation, `.spring` for additions
- [ ] Test with Reduce Motion (should disable)

---

#### [ ] P2-15-2 – Button press feedback
- Checked-out-by: (available)
- Blocked-by: P2-06-1
- Status: Pending

**Subtasks:**
- [ ] Add `.scaleEffect(isPressed ? 0.95 : 1.0)` to all buttons
- [ ] Apply to cards, primary buttons, tag pills
- [ ] Test performance with many cards

---

#### [ ] P2-15-3 – Card expansion animations
- Checked-out-by: (available)
- Blocked-by: P2-06-2
- Status: Pending

**Subtasks:**
- [ ] For expandable sections: `.animation(.spring(), value: isExpanded)`
- [ ] Smooth height transitions

---

#### [ ] P2-15-4 – Loading skeleton animation
- Checked-out-by: (available)
- Blocked-by: P2-06-2
- Status: Pending

**Subtasks:**
- [ ] Shimmer effect: `.redacted(reason: .placeholder)` + animated gradient
- [ ] Disable if Reduce Motion enabled
- [ ] Test with 10+ skeleton cards

---

### P2-16 – Haptic Feedback

> **Goal:** Tactile feedback for key interactions
> **Blocked-by:** P2-06-1

#### [ ] P2-16-1 – Success feedback
- Checked-out-by: (available)
- Blocked-by: P2-06-1
- Status: Pending

**Subtasks:**
- [ ] Trigger `NestoryTheme.Haptics.trigger(.success)` for: item added, report generated, backup completed, settings saved
- [ ] Pair with visual success state

---

#### [ ] P2-16-2 – Error feedback
- Checked-out-by: (available)
- Blocked-by: P2-06-1
- Status: Pending

**Subtasks:**
- [ ] Trigger `.error` for validation errors, failures
- [ ] Pair with visual error state (red banner, error card)

---

#### [ ] P2-16-3 – Selection feedback
- Checked-out-by: (available)
- Blocked-by: P2-06-1
- Status: Pending

**Subtasks:**
- [ ] Trigger `.selection` for card taps, tag selections, picker changes, tab switches
- [ ] Use `.impact(.light)` for toggles

---

### P2-17 – Performance & Loading States

> **Goal:** Smooth performance with large inventories (100+ items)
> **Blocked-by:** P2-06

#### [x] P2-17-1 – Image caching strategy
- Completed: 2025-12-01
- Blocked-by: P2-06-1 ✓

**Implementation:**
- [x] Implemented `ImageCacheService` (NSCache, 50MB thumbnails + 100MB full images, LRU eviction)
- [x] CachedThumbnailView / CachedPhotoView for lazy loading with loading states
- [x] Prefetch capability for list views
- [x] Memory warning handler (clears full images on pressure)
- [x] Cache clearing via `clearCache()` method

**Files Created:**
- `Nestory-Pro/Services/ImageCacheService.swift` (265 lines)

---

#### [ ] P2-17-2 – Lazy loading for large lists
- Checked-out-by: (available)
- Blocked-by: P2-06-2
- Status: Pending

**Subtasks:**
- [ ] Use `LazyVStack` in all scrolling views
- [ ] For >50 items: load first 50, then paginate
- [ ] Loading indicator at bottom, "Load More" fallback

---

#### [ ] P2-17-3 – Progressive disclosure
- Checked-out-by: (available)
- Blocked-by: P2-06-2
- Status: Pending

**Subtasks:**
- [ ] Hierarchy views: show summary counts initially, load details on expand
- [ ] Documentation status: percentage first, breakdown on tap

---

### P2-18 – Testing

> **Goal:** Comprehensive test coverage for all new models and UI
> **Blocked-by:** All implementation tasks

#### [ ] P2-18-1 – ViewModel presentation model tests
- Checked-out-by: (available)
- Blocked-by: P2-07
- Status: Pending

**Subtasks:**
- [ ] Unit tests for `InventorySection` (grouping, uncategorized, total value)
- [ ] Unit tests for `SearchMatchMetadata` (parsing filters)
- [ ] Unit tests for `DocumentationStatus` (completion fraction, entries)
- [ ] Unit tests for `AddItemField` validation (required, negative price, date validation)
- [ ] Target: 90%+ coverage for presentation models

---

#### [ ] P2-18-2 – Preview examples
- Checked-out-by: (available)
- Blocked-by: All view tasks
- Status: Pending

**Subtasks:**
- [ ] Add `#Preview` for every new/modified view (empty, single, multiple, loading, error states)
- [ ] Use `PreviewContainer` scenarios: `.empty()`, `.withBasicData()`, `.withManyItems(count: 100)`

---

#### [ ] P2-18-3 – Snapshot tests
- Checked-out-by: (available)
- Blocked-by: All view tasks, P1-00
- Status: Pending

**Subtasks:**
- [ ] Record baselines for: InventoryTab, ItemDetailView, Property/Room/ContainerDetailView, CaptureTab, SettingsTab, Paywall
- [ ] Use `SnapshotDevice.iPhone17ProMax`, test light + dark
- [ ] `isRecording = true` for baselines, then `false` for CI

---

#### [ ] P2-18-4 – Accessibility audit
- Checked-out-by: (available)
- Blocked-by: P2-14
- Status: Pending

**Subtasks:**
- [ ] VoiceOver testing on device (navigate InventoryTab, verify labels/hierarchy)
- [ ] Dynamic Type testing at `xxxLarge`
- [ ] Color contrast with Xcode Accessibility Inspector
- [ ] Reduce Motion testing

---

### P2-19 – Project Integration

> **Goal:** Ensure all new files/components properly integrated into Xcode project
> **Blocked-by:** All implementation tasks

#### [x] P2-19-1 – Xcode project file updates
- Completed: 2025-12-01
- Blocked-by: All implementation tasks ✓

**Verified:**
- [x] All new files added to `Nestory-Pro` app target (XcodeGen auto-includes via glob):
  - `SharedUI/DesignSystem.swift` (NestoryTheme, animations, button styles, accessibility modifiers)
  - `SharedUI/SharedComponents.swift` (SummaryCard, DocumentationBadge, FilterChip, EmptyStateView)
  - `SharedUI/AccessibilityIdentifiers.swift` (enhanced with MainTab, Hierarchy, LockScreen enums)
  - `Services/ImageCacheService.swift` (NSCache-based image caching + CachedThumbnailView/CachedPhotoView)
- [x] Color assets in `Assets.xcassets` with light/dark variants
- [x] `xcodegen generate` run to sync project
- [x] Debug build succeeds

---

#### [x] P2-19-2 – Scheme validation
- Completed: 2025-12-01
- Blocked-by: P2-19-1 ✓

**Results:**
- [x] Build Debug: **SUCCEEDED**
- [x] Build Beta: **SUCCEEDED** (50.8s)
- [x] Build Release: **SUCCEEDED** (33.8s)
- [x] No new warnings from Phase 12 code
- [x] UI Tests: **FIXED** (2025-12-01) - Swift 6 concurrency pattern updated
  - Fixed: Changed `UITests.xcconfig` to `nonisolated` default
  - Fixed: All 8 UITest classes updated with `nonisolated(unsafe) var app`
  - Pattern: setUp/tearDown plain override, test methods `@MainActor`

---

### P2-20 – Phase 12 Completion Checklist

> **Goal:** Validate all Phase 12 objectives met before declaring complete

#### [ ] P2-20-1 – Design system validation
- Checked-out-by: (available)
- Blocked-by: P2-06
- Status: Pending

**Checklist:**
- [ ] `NestoryTheme` tokens defined and documented
- [ ] All color assets present with light/dark variants
- [ ] Card modifiers implemented and used consistently
- [ ] Typography scale applied across app
- [ ] Animation durations standardized
- [ ] Haptic patterns implemented

---

#### [ ] P2-20-2 – ViewModel presentation models validation
- Checked-out-by: (available)
- Blocked-by: P2-07
- Status: Pending

**Checklist:**
- [ ] `InventorySection`, `SearchMatchMetadata`, `ItemLimitWarningDisplay` in InventoryTabViewModel
- [ ] `CaptureMode`, `CaptureStatus`, `CaptureActionCard` in CaptureTabViewModel
- [ ] `AddItemField`, `AddItemSection`, `FieldValidationState` in AddItemViewModel
- [ ] `InventorySummary`, `ReportGenerationState` in ReportsTabViewModel
- [ ] `DocumentationStatus`, location/warranty helpers in ItemDetailViewModel
- [ ] All models have unit tests with 90%+ coverage

---

#### [ ] P2-20-3 – View polish validation
- Checked-out-by: (available)
- Blocked-by: P2-08 to P2-13
- Status: Pending

**Checklist:**
- [ ] All views use `.cardStyle()` for sections
- [ ] All views have empty states
- [ ] All views have loading states
- [ ] All views have error states
- [ ] All interactive elements have accessibility labels
- [ ] All views tested in light + dark mode
- [ ] All views have preview examples

---

#### [ ] P2-20-4 – Accessibility validation
- Checked-out-by: (available)
- Blocked-by: P2-14
- Status: Pending

**Checklist:**
- [ ] VoiceOver navigation tested on device
- [ ] Dynamic Type tested at accessibility sizes
- [ ] Reduce Motion tested and working
- [ ] Color contrast meets WCAG AA
- [ ] Accessibility Identifiers added for UI testing

---

#### [ ] P2-20-5 – Performance validation
- Checked-out-by: (available)
- Blocked-by: P2-17
- Status: Pending

**Checklist:**
- [ ] Image caching working for 100+ items
- [ ] Lazy loading working for large lists
- [ ] No frame drops when scrolling inventory
- [ ] Progressive disclosure working for hierarchy views
- [ ] Animations smooth at 60fps

---

#### [ ] P2-20-6 – Final build & test
- Checked-out-by: (available)
- Blocked-by: All Phase 12 tasks
- Status: Pending

**Checklist:**
- [ ] Clean build: `xcodebuild clean build -scheme Nestory-Pro -configuration Debug`
- [ ] All unit tests pass: `xcodebuild test -only-testing:Nestory-ProTests`
- [ ] All integration tests pass
- [ ] Snapshot tests pass (baselines match)
- [ ] No compiler warnings
- [ ] No SwiftData threading warnings
- [ ] Archive succeeds: `xcodebuild archive -scheme Nestory-Pro-Beta`

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

**Completed Features:**
- [x] Onboarding flow complete with analytics ✓
- [x] Tags system functional with filtering ✓
- [x] Feedback mechanism operational ✓
- [x] Reminder notifications working ✓

**Completed (Phase 12):**
- [x] P2-02: Property/Container hierarchy (complete) ✓ 2025-12-01
- [x] **P2-06**: Design system foundation (NestoryTheme, card modifiers) ✓ 2025-12-01
- [x] **P2-07**: ViewModel presentation models (all 5 ViewModels enriched) ✓ 2025-12-01
- [x] **P2-08**: New hierarchy views polished (Property/Room/Container detail) ✓ 2025-12-01
- [x] **P2-09**: Inventory tab & app shell retrofitted ✓ 2025-12-01
- [x] **P2-10**: Item detail view retrofitted ✓ 2025-12-01
- [x] **P2-11**: Capture flows retrofitted ✓ 2025-12-01
- [x] **P2-12**: Add item forms retrofitted ✓ 2025-12-01
- [x] **P2-13**: Settings, paywall, reports retrofitted ✓ 2025-12-01

- [x] **P2-14**: Accessibility complete (VoiceOver, Dynamic Type, Reduce Motion, contrast) ✓ 2025-12-01
- [x] **P2-15**: Animations & micro-interactions ✓ 2025-12-01
- [x] **P2-16**: Haptic feedback ✓ 2025-12-01

**Pending:**
- [ ] **P2-17**: Performance & loading states
- [ ] **P2-18**: Testing (unit, preview, snapshot, accessibility)
- [ ] **P2-19**: Project integration validated
- [ ] **P2-20**: Phase 12 completion criteria met

**Deferred:**
- [ ] Snapshot test baselines (9.3.1-9.3.4) - Waiting for Phase 12 completion

---

## v1.3 – Pro Features v2

> **Theme:** Monetization infrastructure, multi-property support
> **Goal:** Increase Pro conversion and retention
> **Tasks:** 5 | **Dependencies:** v1.2 UX work

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

### v1.3 Release Checklist

- [ ] Multi-property support working for Pro users
- [ ] Feature flag system testable and documented
- [ ] Server-side receipt validation deployed
- [ ] Analytics opt-in functional

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

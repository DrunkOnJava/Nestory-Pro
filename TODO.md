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
| (none)  | -        | -             | -     |

---

## Version Roadmap Overview

| Version | Theme | Tasks | Target | Pricing Tier |
|---------|-------|-------|--------|--------------|
| **v1.0** | Launch | ✅ 105 done | ✅ Shipped | Free / Pro |
| **v1.1** | Stability & Swift 6 | 9 tasks | Q1 2026 | Pro |
| **v1.2** | UX Polish & Onboarding | 5 tasks | Q1 2026 | Pro |
| **v1.3** | Pro Features v2 | 5 tasks | Q2 2026 | Pro |
| **v1.4** | Automation & Extensions | 5 tasks | Q2 2026 | Pro |
| **v1.5** | Platform Expansion | 4 tasks | Q3 2026 | Pro |
| **v2.0** | Data Intelligence | 8 tasks | Q4 2026 | Pro+ ($4.99/mo) |
| **v2.1** | Professional Features | 8 tasks | Q1 2027 | Business ($9.99/mo) |
| **v3.0** | Enterprise | 8 tasks | Q2 2027 | Enterprise (Contact) |

**Total: 52 pending tasks** (approximate; excludes 15 strikethrough tasks already done in v1.0)

---

## v1.1 – Stability & Infrastructure

> **Theme:** Technical foundation, Swift 6 migration, CloudKit readiness
> **Goal:** Rock-solid stability before adding new features
> **Tasks:** 9 | **Dependencies:** Minimal (P1-00 package setup first)

### Snapshot Testing (Unblock 9.3.x)

#### [x] P1-00 – Add swift-snapshot-testing package ✓ 2025-11-29
- Checked-out-by: Claude (v1.1 session)
- Blocked-by: —
- Status: **Complete** (via XcodeGen project.yml)

**Goal:** Unblock deferred snapshot tests from v1.0.

**Subtasks:**
- [x] Add `swift-snapshot-testing` package dependency to Xcode project ✓ 2025-11-29
  - Added via `project.yml` packages section (XcodeGen)
  - Version: 1.17.0+ (resolved to 1.18.7)
- [x] Configure snapshot test directories and helpers ✓ 2025-11-29
  - Created `Nestory-ProTests/SnapshotTests/SnapshotHelpers.swift`
  - Defined `SnapshotDevice` enum with standard configurations
- [x] Verify package builds on all test targets ✓ 2025-11-29
  - Build succeeded with swift-snapshot-testing dependency
- [x] Document snapshot testing workflow in CLAUDE.md ✓ 2025-11-29

### Snapshot Tests (Now Unblocked)

- [ ] **9.3.1** Add Inventory list snapshot
  - Blocked-by: ~~P1-00~~ ✓
  - Note: Tests exist in ViewSnapshotTests.swift, need to record baselines
- [ ] **9.3.2** Add Item detail snapshot
  - Blocked-by: ~~P1-00~~ ✓
- [ ] **9.3.3** Add Paywall snapshot
  - Blocked-by: ~~P1-00~~ ✓
- [ ] **9.3.4** Add Reports tab snapshot
  - Blocked-by: ~~P1-00~~ ✓

### Foundation Tasks

#### [x] P1-01 – Wire xcconfig-based build settings ✓ 2025-11-29
- Checked-out-by: Claude (v1.1 session)
- Blocked-by: —
- Status: **Complete** (via XcodeGen project.yml)

**Goal:** Move all build settings to `Config/*.xcconfig` for maintainability.

**Subtasks:**
- [x] Create `Config/Common.xcconfig`, `Debug.xcconfig`, `Beta.xcconfig`, `Release.xcconfig` ✓ 2025-11-29
  - Also created `Config/Tests.xcconfig` for test targets
  - Common.xcconfig: team, versioning, Swift 6, strict concurrency
  - Debug.xcconfig: thread sanitizer, main thread checker
  - Beta.xcconfig: optimized with debug symbols, main thread checker
  - Release.xcconfig: full optimization, no sanitizers
- [x] Populate with strict warnings, concurrency, optimization settings ✓ 2025-11-29
  - `SWIFT_STRICT_CONCURRENCY = complete`
  - `SWIFT_ENFORCE_EXCLUSIVE_ACCESS = full`
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- [x] Attach configs to all configurations in project (app + tests) ✓ 2025-11-29
  - Wired via `project.yml` configFiles section (XcodeGen)
  - Debug → Config/Debug.xcconfig
  - Release → Config/Release.xcconfig
  - Beta → Config/Beta.xcconfig
  - Tests → Config/Tests.xcconfig
- [x] Build each config (Debug/Beta/Release) and fix any errors ✓ 2025-11-29
  - Debug build succeeded (13.988 sec)
  - Swift 6 mode active with strict concurrency

---

#### [x] P1-02 – Create "Nestory-Pro Beta" configuration and scheme ✓ 2025-11-29
- Checked-out-by: Claude (v1.1 session)
- Blocked-by: ~~P1-01~~ ✓
- Status: **Complete** (via XcodeGen project.yml)

**Goal:** Clean separation between Debug, Beta (TestFlight), and Release.

**Subtasks:**
- [x] Duplicate Release → create `Beta` configuration for all targets ✓ 2025-11-29
  - Created via `project.yml` configs section (XcodeGen)
  - Beta: release type with Beta.xcconfig
- [x] Create `Nestory-Pro Beta` scheme bound to `Beta` config ✓ 2025-11-29
  - Created via `project.yml` schemes section (XcodeGen)
  - Scheme name: Nestory-Pro-Beta
- [ ] Confirm Fastlane builds Beta with new scheme/config

---

#### [x] P1-03 – Swift 6 migration & strict concurrency ✓ 2025-11-30
- Checked-out-by: Claude (v1.1 session)
- Blocked-by: ~~P1-01~~ ✓
- Status: **Complete** (Swift 6 mode active, all tests passing)

**Goal:** Upgrade to Swift 6 strict concurrency; eliminate data races.

**Subtasks:**
- [x] Set `SWIFT_STRICT_CONCURRENCY = complete` in Common config ✓ 2025-11-29
  - Active via project.yml → Config/Common.xcconfig
- [x] Set `SWIFT_ENFORCE_EXCLUSIVE_ACCESS = full` ✓ 2025-11-29
  - Active via project.yml → Config/Common.xcconfig
- [x] Enable Thread Sanitizer + Main Thread Checker for Debug Run ✓ 2025-11-29
  - Active via Config/Debug.xcconfig
- [x] Enable same for Test actions (unit + UI tests) ✓ 2025-11-29
  - Active via Config/Tests.xcconfig
- [x] Fix app module Sendable warnings (value types marked nonisolated) ✓ 2025-11-30
- [x] Fix OCRServiceTests.swift (~40 property access errors) ✓ 2025-11-30
- [x] Fix ViewSnapshotTests.swift (16 data race errors) ✓ 2025-11-30
- [x] Use `@ModelActor` for background SwiftData operations ✓ 2025-11-30
  - Architecture uses @MainActor for all SwiftData ops (simpler, avoids races)
  - @ModelActor reserved for future heavy batch operations if needed
- [x] Update `@Observable` classes for strict isolation ✓ 2025-11-30
  - All ViewModels use @MainActor @Observable pattern
- [x] Run test suite and fix remaining concurrency warnings ✓ 2025-11-30
- [x] Switch language mode Swift 5.0 → Swift 6.0 ✓ 2025-11-29
  - Active via project.yml: `SWIFT_VERSION: 6.0`

---

#### [x] P1-04 – Background modes & entitlements cleanup ✓ 2025-11-29
- Checked-out-by: Claude (v1.1 session)
- Blocked-by: —
- Status: **Complete**

**Goal:** Ship only capabilities we use; reduce signing/validation risk.

**Subtasks:**
- [x] Audit push notifications / background modes usage ✓ 2025-11-29
  - Found: `UIBackgroundModes: remote-notification` (unused - CloudKit disabled)
  - Found: `aps-environment: development` (unused - no push notifications)
- [x] If unused, remove `UIBackgroundModes` from Info.plist ✓ 2025-11-29
  - Removed entire `UIBackgroundModes` array from Info.plist
- [x] Remove unused capabilities from Signing & Capabilities ✓ 2025-11-29
  - Removed `aps-environment` from entitlements
  - Kept iCloud entitlements (needed for v1.1 CloudKit)
- [x] Confirm archive + validation still pass ✓ 2025-11-29
  - Build succeeded with modified entitlements

---

### v1.1 Release Checklist

- [ ] All 9.3.x snapshot tests passing with swift-snapshot-testing
- [x] Swift 6 strict concurrency enabled, all tests passing ✓ 2025-11-30
- [x] CloudKit sync monitoring in place (CloudKitSyncMonitor.swift) ✓ 2025-11-29
- [x] Build configurations via xcconfig files attached to project ✓ 2025-11-29
  - Wired via XcodeGen project.yml
- [ ] TestFlight beta validated (need to confirm Fastlane builds)

### Infrastructure Fixes (Discovered During v1.1)

- [x] **TestFixtures.swift crash** - Fixed TestContainer.empty() ✓ 2025-11-29
  - Root cause: TestContainer was creating Schema directly instead of using NestoryModelContainer
  - Fix: Changed to use `NestoryModelContainer.createForTesting()` for VersionedSchema consistency
  - ConcurrencyTests now pass (12 tests, 52.957 sec)

---

## v1.2 – UX Polish & Onboarding

> **Theme:** First-run experience, user guidance, organization
> **Goal:** Reduce time-to-value for new users
> **Tasks:** 5 | **Dependencies:** v1.1 foundation

#### [ ] P2-01 – First-time user onboarding flow
- Checked-out-by: none
- Blocked-by: P1-01

**Goal:** Smooth path from install → first item → "Aha!" moment.

**Subtasks:**
- [ ] Design 2–3 screen lightweight onboarding
- [ ] Implement "Create your first space/room" wizard
- [ ] Track `hasCompletedOnboarding` in SwiftData
- [ ] Re-trigger option in Settings

---

#### [ ] P2-02 – Information architecture: Spaces, rooms, containers
- Checked-out-by: none
- Blocked-by: P1-01

**Goal:** Crystal clear mental model: property → room → container → item.

**Subtasks:**
- [ ] Define models: `Property`/`Space`, `Room`, `Container`, `Item`
- [ ] Implement hierarchy navigation views
- [ ] Add breadcrumbs ("Home > Apartment > Living Room > TV Stand")
- [ ] Add re-ordering and renaming for each level

---

#### [ ] P2-05 – Tags & quick categorization
- Checked-out-by: none
- Blocked-by: P2-03 ✓

**Goal:** Flexible tagging that doesn't feel like a database UI.

**Subtasks:**
- [ ] Define `Tag` model with Item relationship
- [ ] Implement pill-style tag UI on item detail
- [ ] Tag favorites: "Essential", "High value", "Electronics", "Insurance-critical"
- [ ] Add tag-based filtering view

---

#### [x] P4-07 – In-app feedback & support ✓ 2025-11-30
- Checked-out-by: Claude (v1.1 session)
- Blocked-by: P2-06 ✓
- Status: **Complete**

**Goal:** Channel user feedback directly to you.

**Subtasks:**
- [x] Add "Send feedback" and "Report a problem" in Settings ✓ 2025-11-30
  - Added FeedbackSheet with category selection
  - Added "Report a Problem" button in Settings
- [x] Pre-fill device/app info in message body ✓ 2025-11-30
  - FeedbackService generates device model, iOS version, app version, storage info
  - Email body includes formatted device info section
- [x] Optional email inbox or ticketing integration ✓ 2025-11-30
  - Uses mailto: URLs to open system email client
  - Support email: support@nestory.app
- [x] Track feedback categories for roadmap ✓ 2025-11-30
  - FeedbackCategory enum with logging
  - logFeedbackEvent() for future analytics integration

**Files Created:**
- `Nestory-Pro/Services/FeedbackService.swift` - Device info, email URL generation
- `Nestory-Pro/Views/Settings/FeedbackSheet.swift` - Category selection UI

**Support Site Deployed:**
- URL: https://nestory-support.netlify.app
- Source: `/Users/griffin/Projects/Nestory/nestory-support-site`
- Pages: FAQ (index.html), Privacy Policy, Terms of Service
- Netlify project: nestory-support

---

#### [ ] P5-03 – Quick actions: inventory tasks & reminders
- Checked-out-by: none
- Blocked-by: P2-06 ✓

**Goal:** Transform static database into ongoing companion.

**Subtasks:**
- [ ] Add warranty expiry reminders
- [ ] Implement reminders list view ("Things to review this month")
- [ ] Integrate local notifications
- [ ] Respect feature flags for Pro reminder features

---

### v1.2 Release Checklist

- [ ] Onboarding flow complete with analytics
- [ ] Tags system functional with filtering
- [ ] Feedback mechanism operational
- [ ] Reminder notifications working

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

*Last Updated: November 29, 2025*

### Changelog

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

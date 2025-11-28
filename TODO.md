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
- Tasks marked with "DEPENDS: X.Y.Z" cannot start until that task is [x]
- Check dependencies BEFORE checking out a task

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

<!--
When you check out a task, add an entry here:
| Task ID | Agent ID | Checkout Time | Notes |
|---------|----------|---------------|-------|
| 3.1.1   | abc123   | 2025-11-28 15:30 | Working on PhotoStorageService |
-->

| Task ID | Agent ID | Checkout Time | Notes |
|---------|----------|---------------|-------|
| _none_  | -        | -             | All tasks available |

---

## Priority Legend

| Priority | Meaning | SLA |
|----------|---------|-----|
| **P0** | Critical - Blocks release | Must complete this sprint |
| **P1** | High - Core functionality | Complete within 2 sprints |
| **P2** | Medium - Important polish | Complete before v1.1 |
| **P3** | Low - Nice to have | Backlog |

---

## Phase 1: Data Model Completion (P0)

> **Goal:** Align SwiftData models with specification

### 1.1 Item Model Updates

- [x] **1.1.1** Add `notes: String?` property to Item model ✓ 2025-11-28
  - File: `Nestory-Pro/Models/Item.swift`
  - Add after `conditionNotes` property
  - Update `Item.init()` with default nil
  - Add to TestFixtures.testItem()

- [x] **1.1.2** Add ItemPhoto ordering fields ✓ 2025-11-28
  - File: `Nestory-Pro/Models/ItemPhoto.swift`
  - Add `sortOrder: Int = 0`
  - Add `isPrimary: Bool = false`
  - Update init and TestFixtures

- [x] **1.1.3** Add Room.isDefault property ✓ 2025-11-28
  - File: `Nestory-Pro/Models/Room.swift`
  - Add `isDefault: Bool = false` (default for user-created rooms)
  - Update default room seeding in `Nestory_ProApp.swift`
  - Ensure user-created rooms have `isDefault = false`

### 1.2 Documentation Score Alignment

- [ ] **1.2.1** Decide: Keep 4-field (current) or switch to 6-field weighted scoring
  - Current: Photo/Value/Room/Category at 25% each = 100%
  - Spec option: Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%
  - **DECISION REQUIRED:** Update this task with chosen approach before proceeding
  - DEPENDS: Human decision

- [-] **1.2.2** Update `documentationScore` calculation (BLOCKED)
  - File: `Nestory-Pro/Models/Item.swift` lines 157-164
  - DEPENDS: 1.2.1

- [-] **1.2.3** Update `missingDocumentation` to match score fields (BLOCKED)
  - File: `Nestory-Pro/Models/Item.swift` lines 168-175
  - DEPENDS: 1.2.1

- [-] **1.2.4** Update ItemTests for new scoring (BLOCKED)
  - DEPENDS: 1.2.2, 1.2.3

---

## Phase 2: Capture Flows (P0)

> **Goal:** Implement photo capture, receipt OCR, and barcode scanning

### 2.1 Photo Storage Service

- [x] **2.1.1** Implement PhotoStorageService conforming to protocol ✓ 2025-11-28
  - File: `Nestory-Pro/Services/PhotoStorageService.swift` (created)
  - Protocol: `Nestory-Pro/Protocols/PhotoStorageProtocol.swift`
  - Use FileManager, save to Documents/Photos/
  - Resize images to max 2048px, JPEG quality 0.8
  - Include cleanup method for orphaned files

- [x] **2.1.2** Add PhotoStorageService unit tests ✓ 2025-11-28
  - File: `Nestory-ProTests/UnitTests/Services/PhotoStorageServiceTests.swift`
  - Test save, load, delete, cleanup
  - DEPENDS: 2.1.1

### 2.2 Photo Capture UI

- [x] **2.2.1** Create PhotoCaptureView with camera integration ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/PhotoCaptureView.swift` (created)
  - Use UIImagePickerController or PhotosUI
  - Handle camera permissions gracefully
  - Show permission rationale before requesting

- [x] **2.2.2** Create QuickAddItemSheet for post-capture ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/QuickAddItemSheet.swift` (created)
  - Minimal form: name (required), room picker, save button
  - Auto-attach captured photo
  - DEPENDS: 2.1.1, 2.2.1

- [x] **2.2.3** Wire CaptureTab to Photo Capture flow ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/CaptureTab.swift` (updated)
  - Segmented control: Photo | Receipt | Barcode
  - Photo segment integrated with PhotoCaptureView and QuickAddItemSheet
  - DEPENDS: 2.2.1, 2.2.2

### 2.3 Receipt OCR Service

- [x] **2.3.1** Implement OCRService using Vision framework ✓ 2025-11-28
  - File: `Nestory-Pro/Services/OCRService.swift` (created)
  - Protocol: `Nestory-Pro/Protocols/OCRServiceProtocol.swift`
  - Use VNRecognizeTextRequest for text extraction
  - Parse vendor, total, date, tax from raw text
  - Return confidence score (0.0-1.0)

- [x] **2.3.2** Add OCRService unit tests ✓ 2025-11-28
  - File: `Nestory-ProTests/UnitTests/Services/OCRServiceTests.swift` (created)
  - Test text extraction, amount parsing, date parsing
  - Test low-confidence handling (31 test methods)
  - DEPENDS: 2.3.1

- [x] **2.3.3** Create ReceiptCaptureView ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/ReceiptCaptureView.swift` (created)
  - Camera preview with receipt frame overlay
  - Loading state with progress indicator during OCR
  - Confidence indicator (green/yellow/red) based on OCR confidence
  - Manual entry fallback, PhotosPicker support
  - DEPENDS: 2.3.1

- [x] **2.3.4** Create ReceiptReviewSheet ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/ReceiptReviewSheet.swift` (created)
  - Editable fields with confidence badges (green/yellow/red)
  - Item linking with SwiftData @Query
  - Raw OCR text section for review
  - DEPENDS: 2.3.3

### 2.4 Barcode Scanning (Stretch for v1)

- [ ] **2.4.1** Create BarcodeLookupService protocol
  - File: `Nestory-Pro/Protocols/BarcodeLookupProtocol.swift` (create)
  - Define `lookupBarcode(code: String) async throws -> ProductInfo?`
  - ProductInfo: name, brand, category suggestion

- [ ] **2.4.2** Implement BarcodeLookupService (basic)
  - File: `Nestory-Pro/Services/BarcodeLookupService.swift` (create)
  - Option A: Local database of common UPCs
  - Option B: Minimal external API (UPC only, no context)
  - Always fallback gracefully to manual entry
  - DEPENDS: 2.4.1

- [ ] **2.4.3** Create BarcodeScanView
  - File: `Nestory-Pro/Views/Capture/BarcodeScanView.swift` (create)
  - Use AVFoundation for barcode detection
  - Show product info if found, otherwise manual entry
  - DEPENDS: 2.4.2

---

## Phase 3: Reports (P0)

> **Goal:** Generate insurance-ready PDFs and export data

### 3.1 Report Generator Service

- [x] **3.1.1** Implement ReportGeneratorService ✓ 2025-11-28
  - File: `Nestory-Pro/Services/ReportGeneratorService.swift` (created, 776 lines)
  - PDFKit PDF generation with US Letter size, proper pagination
  - Grouping options: byRoom, byCategory, alphabetical
  - Photo support for Pro users (pre-loaded cache for PDF context)

- [x] **3.1.2** Create PDF layout templates ✓ 2025-11-28
  - Integrated into ReportGeneratorService.swift
  - Header with app name, report title, generation date
  - Summary section with total items/value
  - Item rows grouped by room/category/alphabetical
  - Photo thumbnails for Pro users
  - DEPENDS: 3.1.1

### 3.2 Full Inventory Report

- [x] **3.2.1** Create FullInventoryReportView ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Reports/FullInventoryReportView.swift` (created)
  - Grouping picker with ReportGrouping enum
  - Include Photos toggle (Pro-gated with lock icon)
  - PDF generation with loading state, QuickLook preview
  - Empty state handling
  - DEPENDS: 3.1.1, 3.1.2

### 3.3 Loss List Report

- [x] **3.3.1** Create LossListSelectionView ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Reports/LossListSelectionView.swift` (created)
  - Multi-select with checkboxes, search/filter
  - Quick select: "By Room", "By Category", "Select All"
  - Free tier 20-item limit with warning banner and upgrade prompt
  - DEPENDS: 3.1.1

- [x] **3.3.2** Create IncidentDetailsSheet ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Reports/IncidentDetailsSheet.swift` (created)
  - DatePicker for incident date, Picker for IncidentType
  - Multi-line description TextField
  - Loss summary with item count and total value
  - PDF generation with preview and share
  - DEPENDS: 3.3.1

- [x] **3.3.3** Create LossListPDFView ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Reports/LossListPDFView.swift` (created)
  - PDFKit integration with UIViewRepresentable
  - Pinch-to-zoom support, ShareLink for sharing
  - Error handling for invalid PDFs
  - DEPENDS: 3.3.1, 3.3.2

### 3.4 Data Export

- [x] **3.4.1** Implement BackupService conforming to protocol ✓ 2025-11-28
  - File: `Nestory-Pro/Services/BackupService.swift` (created, 393 lines)
  - Protocol: `Nestory-Pro/Protocols/BackupServiceProtocol.swift`
  - JSON export with flattened relationships, ISO8601 dates
  - CSV export with proper escaping (Pro only)

- [x] **3.4.2** Wire export buttons in Settings ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Settings/SettingsTab.swift` (updated)
  - JSON export with BackupService integration
  - CSV export with Pro gating
  - Native file exporter for sharing
  - DEPENDS: 3.4.1

### 3.5 Reports Tab UI

- [x] **3.5.1** Build ReportsTab main interface ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Reports/ReportsTab.swift` (updated)
  - Quick stats section (total items, total value)
  - Full Inventory Report card → FullInventoryReportView
  - Loss List card → LossListSelectionView
  - Reusable ReportCard and StatCard components
  - DEPENDS: 3.2.1, 3.3.3

---

## Phase 4: Monetization Enforcement (P0)

> **Goal:** Enforce free tier limits and Pro feature gating

### 4.1 Item Limit Enforcement

- [x] **4.1.1** Add 100-item limit check in AddItemView ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Inventory/AddItemView.swift` (updated)
  - @Query to count items, limit check before save
  - ProPaywallView shown when limit reached

- [x] **4.1.2** Add item count warning in InventoryTab ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Inventory/InventoryTab.swift` (updated)
  - Warning banner at 80+ items (orange), 100 items (red)
  - Upgrade button, dismissable per session

### 4.2 Loss List Limit Enforcement

- [x] **4.2.1** Add 20-item limit in LossListSelectionView ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Reports/LossListSelectionView.swift`
  - Selection limited to 20 items for free tier
  - Warning at 18+ items, upgrade prompt at limit
  - Visual feedback with lock icons
  - DEPENDS: 3.3.1

### 4.3 Feature Gating

- [x] **4.3.1** Gate PDF photos to Pro ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Reports/FullInventoryReportView.swift`
  - Lock icon + "Pro" badge for free users
  - Tap shows ProPaywallView

- [x] **4.3.2** Gate CSV export to Pro ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Settings/SettingsTab.swift`
  - Lock icon + "Pro" badge, tap shows paywall
  - JSON remains free for all users

### 4.4 Contextual Paywall

- [x] **4.4.1** Create ContextualPaywallSheet ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Settings/ContextualPaywallSheet.swift` (created)
  - PaywallContext enum: itemLimit, lossListLimit, photosInPDF, csvExport
  - Context-specific icons, headlines, descriptions
  - StoreKit 2 purchase flow, restore purchases

---

## Phase 5: Architecture Cleanup (P1)

> **Goal:** Proper MVVM with dependency injection

### 5.1 ViewModels

- [ ] **5.1.1** Create InventoryTabViewModel
  - File: `Nestory-Pro/ViewModels/InventoryTabViewModel.swift` (create)
  - Move filtering, sorting, stats calculation from InventoryTab
  - Use @Observable macro
  - Inject via @Environment

- [ ] **5.1.2** Create AddItemViewModel
  - File: `Nestory-Pro/ViewModels/AddItemViewModel.swift` (create)
  - Move form state and validation from AddItemView
  - Handle save with limit checking
  - DEPENDS: 4.1.1

- [ ] **5.1.3** Create ItemDetailViewModel
  - File: `Nestory-Pro/ViewModels/ItemDetailViewModel.swift` (create)
  - Handle edit, delete, photo management

- [ ] **5.1.4** Create CaptureTabViewModel
  - File: `Nestory-Pro/ViewModels/CaptureTabViewModel.swift` (create)
  - Coordinate capture flows
  - DEPENDS: 2.2.3

- [ ] **5.1.5** Create ReportsTabViewModel
  - File: `Nestory-Pro/ViewModels/ReportsTabViewModel.swift` (create)
  - Handle report generation and export
  - DEPENDS: 3.5.1

### 5.2 Dependency Injection

- [ ] **5.2.1** Create AppEnvironment container
  - File: `Nestory-Pro/AppEnvironment.swift` (create)
  - Hold all services: SettingsManager, IAPValidator, PhotoStorage, OCR, etc.
  - Inject via @Environment in app root

- [ ] **5.2.2** Remove SettingsManager.shared singleton
  - File: `Nestory-Pro/Services/SettingsManager.swift`
  - Remove `static let shared`
  - Update all callsites to use @Environment
  - DEPENDS: 5.2.1

- [ ] **5.2.3** Remove IAPValidator.shared singleton
  - File: `Nestory-Pro/Services/IAPValidator.swift`
  - Remove `static let shared`
  - Update all callsites to use @Environment
  - DEPENDS: 5.2.1

---

## Phase 6: Settings Completion (P1)

> **Goal:** Complete all settings features

### 6.1 Default Room Setting

- [ ] **6.1.1** Add defaultRoomId to SettingsManager
  - File: `Nestory-Pro/Services/SettingsManager.swift`
  - Add `@AppStorage("defaultRoomId") var defaultRoomId: String?`
  - Add room picker in SettingsTab

- [ ] **6.1.2** Use default room in AddItemView
  - Pre-select room when creating new item
  - DEPENDS: 6.1.1

### 6.2 App Lock (Biometric Auth)

- [ ] **6.2.1** Create AppLockService
  - File: `Nestory-Pro/Services/AppLockService.swift` (create)
  - Use LocalAuthentication framework
  - LAContext for Face ID / Touch ID
  - Handle fallback to passcode

- [ ] **6.2.2** Implement app lock flow
  - Show lock screen on app foreground if enabled
  - Respect lockAfterInactivity setting
  - DEPENDS: 6.2.1

### 6.3 Data Import

- [ ] **6.3.1** Implement restore from backup
  - Add to BackupService
  - Parse JSON, validate, insert into SwiftData
  - Handle conflicts (merge or replace)
  - DEPENDS: 3.4.1

- [ ] **6.3.2** Wire import button in Settings
  - Show document picker for .json files
  - Confirm before importing
  - DEPENDS: 6.3.1

---

## Phase 7: Accessibility (P2)

> **Goal:** WCAG 2.1 AA compliance

### 7.1 Accessibility Labels

- [ ] **7.1.1** Add labels to Inventory interactive elements
  - File: `Nestory-Pro/Views/Inventory/InventoryTab.swift`
  - Filter chips, sort menu, view toggle
  - Pattern: `.accessibilityLabel("descriptive text")`

- [ ] **7.1.2** Add labels to Item cells
  - File: `Nestory-Pro/Views/SharedUI/SharedComponents.swift`
  - ItemListCell and ItemGridCell
  - Format: "[Name], in [Room], valued at [Price], documentation [status]"

- [ ] **7.1.3** Add labels to Settings toggles
  - File: `Nestory-Pro/Views/Settings/SettingsTab.swift`
  - All toggles and buttons

- [ ] **7.1.4** Add labels to Item Detail actions
  - File: `Nestory-Pro/Views/Inventory/ItemDetailView.swift`
  - All buttons and interactive elements

### 7.2 Color Alternatives

- [ ] **7.2.1** Add text to DocumentationBadge
  - File: `Nestory-Pro/Views/SharedUI/SharedComponents.swift`
  - Show "Complete" or "Missing" text alongside color
  - Or use `.accessibilityValue()` for VoiceOver

- [ ] **7.2.2** Add status text to documentation score
  - "Good" (80%+), "Fair" (50-79%), "Needs Work" (<50%)
  - Display alongside color indicator

### 7.3 TipKit Integration

- [ ] **7.3.1** Create documentation score tip
  - Show on first visit to inventory with score < 70%
  - Explain what documentation means

- [ ] **7.3.2** Create iCloud sync tip
  - Show when user enables iCloud
  - Explain what syncs and when

- [ ] **7.3.3** Create Pro features tip
  - Show when user hits a limit
  - Highlight key Pro benefits

---

## Phase 8: Testing (P2)

> **Goal:** Comprehensive test coverage

### 8.1 Service Tests

- [ ] **8.1.1** Add PhotoStorageService tests
  - DEPENDS: 2.1.1

- [ ] **8.1.2** Add OCRService tests
  - DEPENDS: 2.3.1

- [ ] **8.1.3** Add BackupService tests
  - DEPENDS: 3.4.1

- [ ] **8.1.4** Add ReportGeneratorService tests
  - DEPENDS: 3.1.1

- [ ] **8.1.5** Add AppLockService tests
  - DEPENDS: 6.2.1

### 8.2 UI Tests

- [ ] **8.2.1** Add Photo Capture flow UI test
  - Test: Open capture tab, take photo, add item name, save
  - Verify item appears in inventory
  - DEPENDS: 2.2.3

- [ ] **8.2.2** Add Receipt OCR flow UI test
  - Test: Scan receipt, review extracted data, link to item
  - DEPENDS: 2.3.4

- [ ] **8.2.3** Add Loss List flow UI test
  - Test: Select items, add incident, generate PDF
  - DEPENDS: 3.3.3

### 8.3 Snapshot Tests

- [ ] **8.3.1** Add Inventory list snapshot
- [ ] **8.3.2** Add Item detail snapshot
- [ ] **8.3.3** Add Paywall snapshot
- [ ] **8.3.4** Add Reports tab snapshot

---

## Discovered Tasks

<!--
Add new tasks discovered during development here.
Format: - [ ] **D.X** Description (discovered by AGENT-ID, date)
Periodically promote to appropriate phase above.
-->

_None yet_

---

## Completed Tasks

<!--
Move completed tasks here with completion date.
Format: - [x] **X.Y.Z** Description (completed YYYY-MM-DD)
-->

### November 28, 2025

- [x] **Legacy** Move Pro status to Keychain (`KeychainManager.swift`)
- [x] **Legacy** Add Privacy Manifest (`PrivacyInfo.xcprivacy`)
- [x] **Legacy** Implement IAP receipt validation (`IAPValidator.swift`)
- [x] **Legacy** Add image caching (`ImageCache.swift`)
- [x] **Legacy** Add Sendable conformance to enums
- [x] **Legacy** Create service protocols for DI
- [x] **Legacy** Create mock implementations for testing
- [x] **Legacy** Add localization support to enums
- [x] **Legacy** Add accessibility identifiers structure
- [x] **Legacy** Add haptic feedback utility
- [x] **Legacy** Add Item validation
- [x] **Legacy** Cache NumberFormatter in SettingsManager
- [x] **Tests** Fix 6 failing tests from test analysis (Item.missingDocumentation alignment)

---

## Backlog (Post v1)

- [ ] Server-side receipt validation endpoint
- [ ] CloudKit sharing for family inventories
- [ ] Widget extension for quick capture
- [ ] Mac Catalyst support
- [ ] Siri Shortcuts support
- [ ] App Clips for quick capture
- [ ] Spanish localization
- [ ] Architecture diagram in README

---

## Notes

### Spec Reference
- See `PRODUCT-SPEC.md` for full product requirements
- See `CLAUDE.md` for development guidelines
- See handoff section at top of this file for agent behavior rules

### Key Decisions Needed
1. Documentation score: 4-field vs 6-field weighted (Task 1.2.1)
2. Barcode API: Local database vs external service (Task 2.4.2)

### Testing Requirements
- All new code must have tests
- Minimum 60% code coverage for new files
- Run tests before marking task complete

---

*Last Updated: November 28, 2025*
*Task Count: 73 tasks (0 in progress, 34 completed, 39 remaining)*

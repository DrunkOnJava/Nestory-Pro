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
| (none)  | -        | -             | -     |

---

## Priority Legend

| Priority | Meaning | SLA |
|----------|---------|-----|
| **P0** | Critical - Blocks release | Must complete this sprint |
| **P1** | High - Core functionality | Complete within 2 sprints |
| **P2** | Medium - Important polish | Complete before v1.1 |
| **P3** | Low - Nice to have | Backlog |

---

## Phase 1: Foundation & Spec Alignment (P0)

> **Goal:** Lock down bundle ID, align specs with codebase, ensure SwiftData models match specification

### 1.1 Bundle ID & Project Configuration

- [x] **1.1.1** Lock bundle ID plan for 1.0 ✓ 2025-11-28
  - **DECISION:** Keep `com.drunkonjava.Nestory-Pro` for v1.0
  - Rationale: Avoids App Store complications, provisioning regeneration, CloudKit migration
  - Update README and spec files to reflect decision
  - Ensure PRODUCT-SPEC.md, TECHNICAL_SPEC.md, and DATA_MODEL.md all agree

- [x] **1.1.2** Align Xcode target + fastlane with chosen bundle ID ✓ 2025-11-29
  - Xcode target: `com.drunkonjava.Nestory-Pro` (verified)
  - Fastlane Appfile: `com.drunkonjava.Nestory-Pro` (verified)
  - App Store Connect API key configured via .env (gitignored)
  - Created .env.example for documentation
  - Using Xcode automatic signing (Match not required)

- [x] **1.1.3** Sync spec suite with current codebase ✓ 2025-11-29
  - Added "Implementation Status Summary" section to PRODUCT-SPEC.md
  - Core features table (14 items, all complete)
  - Architecture status table (5 components, all complete)
  - Pending tasks table and Known Issues section
  - Task progress metrics (82 completed, 42 pending, ~66%)

### 1.2 Item Model Updates

- [x] **1.2.1** Add `notes: String?` property to Item model ✓ 2025-11-28
  - File: `Nestory-Pro/Models/Item.swift`
  - Add after `conditionNotes` property
  - Update `Item.init()` with default nil
  - Add to TestFixtures.testItem()

- [x] **1.2.2** Add ItemPhoto ordering fields ✓ 2025-11-28
  - File: `Nestory-Pro/Models/ItemPhoto.swift`
  - Add `sortOrder: Int = 0`
  - Add `isPrimary: Bool = false`
  - Update init and TestFixtures

- [x] **1.2.3** Add Room.isDefault property ✓ 2025-11-28
  - File: `Nestory-Pro/Models/Room.swift`
  - Add `isDefault: Bool = false` (default for user-created rooms)
  - Update default room seeding in `Nestory_ProApp.swift`
  - Ensure user-created rooms have `isDefault = false`

### 1.3 SwiftData Schema & Migrations

- [x] **1.3.1** Confirm SwiftData models match specification ✓ 2025-11-28
  - Verified: Item, ItemPhoto, Receipt, Room, Category - all fields and types correct
  - Confirmed: `barcode: String?` present on Item
  - Money representation: Uses `Decimal` type (better than Int cents, avoids Double precision issues)
  - Updated WARP.md with 6-field documentation score

- [x] **1.3.2** Add VersionedSchema scaffolding for future migrations ✓ 2025-11-28
  - Created `NestorySchemaV1` implementing `VersionedSchema`
  - Created `NestoryMigrationPlan: SchemaMigrationPlan` with placeholder stages
  - Added `NestoryModelContainer` factory for production/testing containers
  - Updated Nestory_ProApp to use versioned schema + disabled CloudKit (Task 10.1.1)

- [x] **1.3.3** DataModel test harness ✓ 2025-11-29
  - Created `DataModelHarnessTests.swift` with 22 comprehensive tests
  - Tests model invariants: default values, non-optional fields, validation errors
  - Tests bulk operations: 500 items with relationships (0.35s)
  - Tests relationship integrity at scale for Category and Room
  - Tests documentation score calculation at scale
  - Tests UUID uniqueness across all model types

### 1.4 Documentation Score Alignment

- [x] **1.4.1** Decide: Keep 4-field (current) or switch to 6-field weighted scoring ✓ 2025-11-28
  - Current: Photo/Value/Room/Category at 25% each = 100%
  - Spec option: Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%
  - **DECISION:** Use 6-field weighted scoring
  - Weights: Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%

- [x] **1.4.2** Update `documentationScore` calculation ✓ 2025-11-28
  - File: `Nestory-Pro/Models/Item.swift` lines 194-205
  - Implemented: Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%
  - DEPENDS: 1.4.1 ✓

- [x] **1.4.3** Update `missingDocumentation` to match score fields ✓ 2025-11-28
  - File: `Nestory-Pro/Models/Item.swift` lines 207-219
  - Added receipt and serial number to missing documentation checks
  - DEPENDS: 1.4.1 ✓

- [x] **1.4.4** Update ItemTests for new scoring ✓ 2025-11-28
  - Updated all documentation score tests for 6-field weighted scoring
  - DEPENDS: 1.4.2 ✓, 1.4.3 ✓

### 1.5 AppEnvironment & DI Verification

- [x] **1.5.1** Verify AppEnvironment matches specification ✓ 2025-11-28
  - All 7 services exposed: settings, iapValidator, photoStorage, ocrService, reportGenerator, backupService, appLockService
  - Views/ViewModels use @Environment(AppEnvironment.self) for DI
  - Internal service dependencies (OCRService→PhotoStorage) use .shared - acceptable for v1.0
  - DEPENDS: 5.2.1 ✓

- [x] **1.5.2** Add test AppEnvironment factory ✓ 2025-11-29
  - Created `AppEnvironment.mock()` variant with protocol-based DI
  - Refactored services to use protocols: SettingsProviding, PhotoStorageProtocol, OCRServiceProtocol, BackupServiceProtocol, AppLockProviding
  - Documented in WARP.md testing section
  - Commit: 9203e0d

---

## Phase 2: Inventory & Add Item Flow (P0)

> **Goal:** Fix AddItemView issues, complete inventory list/grid, and implement capture flows

### 2.1 Fix AddItemView Critical Issues

- [x] **2.1.1** Fix AddItemView Binding / dynamic member error ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Inventory/AddItemView.swift`
  - RESOLVED: Uses correct SwiftUI @Observable pattern with @State and @Bindable
  - `env.makeAddItemViewModel()` factory creates fresh ViewModels
  - Build verified: 0 errors, compiles successfully

- [x] **2.1.2** Implement `setDefaultRoom` logic on AddItemViewModel ✓ 2025-11-29
  - File: `Nestory-Pro/ViewModels/AddItemViewModel.swift`
  - Implemented `setDefaultRoom(_ rooms: [Room])` method
  - Respects user-chosen default room ID from SettingsManager
  - Falls back to first available room if no default set
  - Commit: 9203e0d

### 2.2 Inventory List / Grid & Filtering

- [x] **2.2.1** Ensure Inventory list/grid matches spec ✓ 2025-11-29
  - File: `Nestory-Pro/Views/Inventory/InventoryTab.swift`
  - ItemListCell: 60×60 thumbnail, Room • Category • $Value format, documentation badges
  - ItemGridCell: square thumbnail, two-line name, value, documentation indicators
  - View toggle state persists via SettingsManager.inventoryViewMode AppStorage
  - Commit: 42bb33d

- [x] **2.2.2** Implement filters & search per spec ✓ 2025-11-29
  - Filter chips implemented: All, Needs Photo, Needs Receipt, Needs Value, High Value
  - Search across name, brand, category, room via .searchable modifier
  - Performance verified with pagination support for large inventories

- [x] **2.2.3** Empty states ✓ 2025-11-29
  - EmptyStateView implemented with both empty and filtered-empty states
  - "Add your first item" CTA for empty inventory
  - "No items match your search/filters" for filtered-empty state
  - Aligned with DESIGN_SYSTEM.md

### 2.3 Item Detail & Documentation Badges

- [x] **2.3.1** Implement ItemDetail layout per spec ✓ 2025-11-29
  - Photo carousel: TabView with paging, counter overlay, async photo loading
  - 6-field documentation badges with progress bar and score percentage
  - "What's missing?" info sheet explaining field weights
  - Design tokens: 12pt corner radius, 16pt section spacing, 40% photo height
  - PhotoThumbnailView component for async photo loading

- [x] **2.3.2** Hook up documentation score & badges ✓ 2025-11-29
  - Documentation score uses 6-field weighted calculation in Item model
  - DocumentationBadge component in SharedComponents.swift with weight display
  - "What's missing?" info sheet with field explanations in ItemDetailView
  - Progress bar with green/orange/red thresholds

- [x] **2.3.3** Editing flow ✓ 2025-11-29
  - EditItemView in AddItemView.swift with full form support
  - EditItemViewModel handles form state and validation
  - Updates `updatedAt` timestamp on save
  - Sections: Basic Info, Location, Purchase, Condition, Warranty

### 2.4 Photo Storage Service

- [x] **2.4.1** Implement PhotoStorageService conforming to protocol ✓ 2025-11-28
  - File: `Nestory-Pro/Services/PhotoStorageService.swift` (created)
  - Protocol: `Nestory-Pro/Protocols/PhotoStorageProtocol.swift`
  - Use FileManager, save to Documents/Photos/
  - Resize images to max 2048px, JPEG quality 0.8
  - Include cleanup method for orphaned files

- [x] **2.4.2** Add PhotoStorageService unit tests ✓ 2025-11-28
  - File: `Nestory-ProTests/UnitTests/Services/PhotoStorageServiceTests.swift`
  - Test save, load, delete, cleanup
  - DEPENDS: 2.4.1

### 2.5 Photo Capture UI

- [x] **2.5.1** Create PhotoCaptureView with camera integration ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/PhotoCaptureView.swift` (created)
  - Use UIImagePickerController or PhotosUI
  - Handle camera permissions gracefully
  - Show permission rationale before requesting

- [x] **2.5.2** Create QuickAddItemSheet for post-capture ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/QuickAddItemSheet.swift` (created)
  - Minimal form: name (required), room picker, save button
  - Auto-attach captured photo
  - DEPENDS: 2.4.1, 2.5.1

- [x] **2.5.3** Wire CaptureTab to Photo Capture flow ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/CaptureTab.swift` (updated)
  - Segmented control: Photo | Receipt | Barcode
  - Photo segment integrated with PhotoCaptureView and QuickAddItemSheet
  - DEPENDS: 2.5.1, 2.5.2

- [x] **2.5.4** Recent captures strip ✓ 2025-11-29
  - Added bottom strip showing 3 most recent items with photos
  - Tapping thumbnail navigates to ItemDetailView
  - RecentCaptureCell component with thumbnail and name

### 2.6 Receipt OCR Service

- [x] **2.6.1** Implement OCRService using Vision framework ✓ 2025-11-28
  - File: `Nestory-Pro/Services/OCRService.swift` (created)
  - Protocol: `Nestory-Pro/Protocols/OCRServiceProtocol.swift`
  - Use VNRecognizeTextRequest for text extraction
  - Parse vendor, total, date, tax from raw text
  - Return confidence score (0.0-1.0)

- [x] **2.6.2** Add OCRService unit tests ✓ 2025-11-28
  - File: `Nestory-ProTests/UnitTests/Services/OCRServiceTests.swift` (created)
  - Test text extraction, amount parsing, date parsing
  - Test low-confidence handling (31 test methods)
  - DEPENDS: 2.6.1

- [x] **2.6.3** Create ReceiptCaptureView ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/ReceiptCaptureView.swift` (created)
  - Camera preview with receipt frame overlay
  - Loading state with progress indicator during OCR
  - Confidence indicator (green/yellow/red) based on OCR confidence
  - Manual entry fallback, PhotosPicker support
  - DEPENDS: 2.6.1

- [x] **2.6.4** Create ReceiptReviewSheet ✓ 2025-11-28
  - File: `Nestory-Pro/Views/Capture/ReceiptReviewSheet.swift` (created)
  - Editable fields with confidence badges (green/yellow/red)
  - Item linking with SwiftData @Query
  - Raw OCR text section for review
  - DEPENDS: 2.6.3

- [x] **2.6.5** Link receipts to items ✓ 2025-11-29
  - ReceiptReviewSheet has "Link to Item" toggle and item picker
  - Saves linkedItem relationship on Receipt
  - ItemDetailView shows linked receipts with vendor, total, date
  - Receipts can be saved standalone or linked to existing items

### 2.7 Barcode Scanning (Scan-Only v1.0)

- [x] **2.7.1** Implement barcode scanning mode ✓ 2025-11-29
  - File: `Nestory-Pro/Views/Capture/BarcodeScanView.swift` (created, 456 lines)
  - AVCaptureSession with barcode detection (EAN-8/13, UPC-A/E, QR, Code 128)
  - QuickAddBarcodeSheet for minimal item creation with pre-filled barcode
  - Camera permissions handling with clear rationale
  - Commit: ecee266

- [x] **2.7.2** Persist barcode string on Item ✓ 2025-11-29
  - Added `Item.barcode: String?` property to SwiftData model
  - BackupService updated to export barcode in CSV and JSON
  - Barcode saved via QuickAddBarcodeSheet
  - Commit: ecee266

- [x] **2.7.3** Graceful failure / offline behavior ✓ 2025-11-29
  - No network lookup in v1.0; scanning works entirely offline
  - Clear messaging that product lookup is a future enhancement
  - Commit: ecee266

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

### 3.4 Data Export & Backup Import

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

- [x] **5.1.1** Create InventoryTabViewModel ✓ 2025-11-29
  - File: `Nestory-Pro/ViewModels/InventoryTabViewModel.swift` (created)
  - Move filtering, sorting, stats calculation from InventoryTab
  - Use @Observable macro
  - Inject via @Environment

- [x] **5.1.2** Create AddItemViewModel ✓ 2025-11-29
  - File: `Nestory-Pro/ViewModels/AddItemViewModel.swift` (created)
  - Move form state and validation from AddItemView
  - Handle save with limit checking
  - DEPENDS: 4.1.1

- [x] **5.1.3** Create ItemDetailViewModel ✓ 2025-11-29
  - File: `Nestory-Pro/ViewModels/ItemDetailViewModel.swift` (created)
  - Handle edit, delete, photo management

- [x] **5.1.4** Create CaptureTabViewModel ✓ 2025-11-29
  - File: `Nestory-Pro/ViewModels/CaptureTabViewModel.swift` (created)
  - Coordinate capture flows
  - DEPENDS: 2.2.3

- [x] **5.1.5** Create ReportsTabViewModel ✓ 2025-11-29
  - File: `Nestory-Pro/ViewModels/ReportsTabViewModel.swift` (created)
  - Handle report generation and export
  - DEPENDS: 3.5.1

### 5.2 Dependency Injection

- [x] **5.2.1** Create AppEnvironment container ✓ 2025-11-28
  - File: `Nestory-Pro/AppEnvironment.swift` (created)
  - Hold all services: SettingsManager, IAPValidator, PhotoStorage, OCR, etc.
  - Inject via @Environment in app root

- [x] **5.2.2** Remove SettingsManager.shared singleton ✓ 2025-11-28
  - File: `Nestory-Pro/Services/SettingsManager.swift`
  - Remove `static let shared`
  - Update all callsites to use @Environment
  - DEPENDS: 5.2.1

- [x] **5.2.3** Remove IAPValidator.shared singleton ✓ 2025-11-28
  - File: `Nestory-Pro/Services/IAPValidator.swift`
  - Remove `static let shared`
  - Update all callsites to use @Environment
  - DEPENDS: 5.2.1

---

## Phase 6: Settings Completion (P1)

> **Goal:** Complete all settings features

### 6.1 Default Room Setting

- [x] **6.1.1** Add defaultRoomId to SettingsManager ✓ 2025-11-28
  - File: `Nestory-Pro/Services/SettingsManager.swift`
  - Add `@AppStorage("defaultRoomId") var defaultRoomId: String?`
  - Add room picker in SettingsTab

- [x] **6.1.2** Use default room in AddItemView ✓ 2025-11-28
  - Pre-select room when creating new item
  - DEPENDS: 6.1.1

### 6.2 App Lock (Biometric Auth)

- [x] **6.2.1** Create AppLockService ✓ 2025-11-28
  - File: `Nestory-Pro/Services/AppLockService.swift` (create)
  - Use LocalAuthentication framework
  - LAContext for Face ID / Touch ID
  - Handle fallback to passcode

- [x] **6.2.2** Implement app lock flow ✓ 2025-11-29
  - File: `Nestory-Pro/Views/SharedUI/LockScreenView.swift` (created)
  - Shows lock screen on app foreground if enabled
  - Respects lockAfterInactivity setting (1 minute timeout)
  - Auto-authenticates on appear
  - DEPENDS: 6.2.1

### 6.3 Data Import

- [x] **6.3.1** Implement restore from backup ✓ 2025-11-29
  - Added `performRestore(from:context:strategy:)` to BackupService
  - `RestoreStrategy` enum: merge (add to existing) or replace (clear first)
  - `RestoreResult` struct with counts and errors
  - Handles categories, rooms, items, receipts with relationship linking
  - Skips duplicates in merge mode by ID
  - DEPENDS: 3.4.1 ✓

- [x] **6.3.2** Wire import button in Settings ✓ 2025-11-29
  - Import Data button in Settings opens document picker for .json files
  - Confirmation dialog with Merge/Replace strategy options
  - Uses BackupService.performRestore for actual restore
  - Shows result summary with counts after completion
  - DEPENDS: 6.3.1 ✓

### 3.5 Backup Import (v1.1 Preparation)

- [x] **3.5.1** Design import format and reconciliation rules ✓ 2025-11-29
  - Documented in WARP.md under "Backup & Import Format"
  - JSON format with items, categories, rooms, receipts
  - Merge vs Replace strategies defined
  - Reconciliation table for conflicts and missing data

- [x] **3.5.2** Implement ImportBackupService (P2) ✓ 2025-11-29
  - Added ZIP export with photos (exportToZIP in BackupService)
  - Added ZIP import with photos (importFromZIP in BackupService)
  - iOS ZIP import limited in v1.0 (full support with ZIPFoundation in v1.1)
  - Parse manifest + photos ZIP and import into current store
  - For 1.0, optional: hide behind debug-only flag or internal switch
  - Add tests that import a v1.0 backup and verify no data loss

---

## Phase 7: Release Engineering & CI (P1)

> **Goal:** Finalize fastlane, CI/CD, and App Store preparation

### 7.1 Fastlane & Match

- [x] **7.1.1** Fix Match / API key configuration ✓ 2025-11-29
  - DECISION: Match NOT used - project uses Xcode automatic signing
  - App Store Connect API keys configured in fastlane/.env
  - Updated fastlane/README.md with comprehensive setup guide
  - Resolve `api_key_path` error by pointing to a real App Store Connect API key JSON
  - Document setup steps in `WARP.md` / `DEV_SETUP.md`

- [x] **7.1.2** Finalize lanes ✓ 2025-11-29
  - `fastlane ios test`: run unit + UI tests on simulator (+ test_unit for faster CI)
  - `fastlane ios beta`: build & upload to TestFlight
  - `fastlane ios release`: increment version/build, commit, tag, push, and submit for review (manual gating)

### 7.2 GitHub Actions / CI

- [x] **7.2.1** Robust CI workflows ✓ 2025-11-29
  - Created test.yml: runs fastlane test_unit on PRs and pushes to main
  - Updated beta.yml: tests run before deploy, added DerivedData caching
  - Both workflows cache DerivedData for faster builds

- [x] **7.2.2** Beta lane automation ✓ 2025-11-29
  - Updated beta.yml to trigger on tags matching `v*-beta*` (e.g., v1.0.0-beta1)
  - Added workflow_dispatch option to skip tests for urgent deployments
  - Maintains existing main branch trigger for continuous deployment

### 7.3 App Store Prep

- [x] **7.3.1** App Store metadata ✓ 2025-11-29
  - Created fastlane/metadata/en-US/ with description, keywords, name, subtitle
  - Added promotional_text, release_notes, support_url, marketing_url, privacy_url
  - Screenshots: Manual capture required before first submission

- [x] **7.3.2** Privacy policy & support ✓ 2025-11-29
  - Created PRIVACY.md in repo root (linked from App Store metadata)
  - Support via GitHub Issues: https://github.com/DrunkOnJava/Nestory-Pro/issues

- [x] **7.3.3** App Review readiness ✓ 2025-11-29
  - No private APIs used
  - All debug code wrapped in #if DEBUG (simulateProUnlock, PreviewContent)
  - CloudKit disabled in code (capability present for v1.1, cloudKit: false in NestorySchema)
  - Proper usage descriptions: Camera, Photo Library, Face ID
  - Entitlements verified: aps-environment, iCloud capability

---

## Phase 8: Accessibility (P2)

> **Goal:** WCAG 2.1 AA compliance

### 8.1 Accessibility Labels

- [x] **8.1.1** Add labels to Inventory interactive elements ✓ 2025-11-29
  - File: `Nestory-Pro/Views/Inventory/InventoryTab.swift`
  - Filter chips, sort menu, view toggle with proper labels and hints
  - Pattern: `.accessibilityLabel("descriptive text")`

- [x] **8.1.2** Add labels to Item cells ✓ 2025-11-29
  - File: `Nestory-Pro/Views/SharedUI/SharedComponents.swift`
  - ItemListCell and ItemGridCell with combined accessibility element
  - Format: "[Name], in [Room], valued at [Price], documentation [status]"

- [x] **8.1.3** Add labels to Settings toggles ✓ 2025-11-29
  - File: `Nestory-Pro/Views/Settings/SettingsTab.swift`
  - All toggles and buttons with proper labels, values, and hints

- [x] **8.1.4** Add labels to Item Detail actions ✓ 2025-11-29
  - File: `Nestory-Pro/Views/Inventory/ItemDetailView.swift`
  - Quick action bar and toolbar menu with accessibility hints

### 8.2 Color Alternatives

- [x] **8.2.1** Add text to DocumentationBadge ✓ 2025-11-29
  - File: `Nestory-Pro/Views/SharedUI/SharedComponents.swift`
  - Uses `.accessibilityElement` with "Complete" or "Missing" label
  - Added `.accessibilityValue()` for weight info

- [x] **8.2.2** Add status text to documentation score ✓ 2025-11-29
  - "Excellent" (80%+), "Needs Work" (50-79%), "Incomplete" (<50%)
  - Display alongside color indicator in ItemDetailView
  - Progress bar has `.accessibilityValue` with percentage and status

### 8.3 TipKit Integration

- [x] **8.3.1** Create documentation score tip ✓ 2025-11-29
  - File: `Nestory-Pro/Views/SharedUI/Tips.swift`
  - Shows on inventory tab when documentation score < 70%
  - Explains what documentation means and links to info sheet

- [x] **8.3.2** Create iCloud sync tip ✓ 2025-11-29
  - File: `Nestory-Pro/Views/SharedUI/Tips.swift`
  - Shows when user enables iCloud in Settings
  - Explains what syncs and auto-dismisses

- [x] **8.3.3** Create Pro features tip ✓ 2025-11-29
  - File: `Nestory-Pro/Views/SharedUI/Tips.swift`
  - QuickCaptureTip added to CaptureTab for first-time guidance
  - ProFeaturesTip available for limit scenarios

---

## Phase 9: Testing (P2)

> **Goal:** Comprehensive test coverage

### 9.1 Service Tests

- [x] **9.1.1** Add PhotoStorageService tests ✓ 2025-11-28
  - File: `Nestory-ProTests/UnitTests/Services/PhotoStorageServiceTests.swift`
  - DEPENDS: 2.4.1 ✓

- [x] **9.1.2** Add OCRService tests ✓ 2025-11-28
  - File: `Nestory-ProTests/UnitTests/Services/OCRServiceTests.swift`
  - DEPENDS: 2.6.1 ✓

- [x] **9.1.3** Add BackupService tests ✓ 2025-11-29
  - File: `Nestory-ProTests/UnitTests/Services/BackupServiceTests.swift`
  - Tests JSON/CSV export, import validation, RestoreResult
  - DEPENDS: 3.4.1 ✓

- [x] **9.1.4** Add ReportGeneratorService tests ✓ 2025-11-29
  - File: `Nestory-ProTests/UnitTests/Services/ReportGeneratorServiceTests.swift`
  - Tests PDF generation, ReportOptions, grouping
  - DEPENDS: 3.1.1 ✓

- [x] **9.1.5** Add AppLockService tests ✓ 2025-11-29
  - File: `Nestory-ProTests/UnitTests/Services/AppLockServiceTests.swift`
  - Tests BiometricType enum, mock service for DI testing
  - DEPENDS: 6.2.1 ✓

### 9.2 UI Tests

- [x] **9.2.1** Add Photo Capture flow UI test ✓ 2025-11-29
  - File: `Nestory-ProUITests/Flows/CaptureUITests.swift`
  - Tests: Screen display, segment control, photo capture button, mode switching
  - DEPENDS: 2.5.3 ✓

- [x] **9.2.2** Add Receipt OCR flow UI test ✓ 2025-11-29
  - File: `Nestory-ProUITests/Flows/CaptureUITests.swift`
  - Tests: Receipt segment UI, scan receipt button, capture modal
  - DEPENDS: 2.6.4 ✓

- [x] **9.2.3** Add Loss List flow UI test ✓ 2025-11-29
  - File: `Nestory-ProUITests/Flows/LossListUITests.swift`
  - Tests: Item selection, multi-select, incident details, PDF generation
  - DEPENDS: 3.3.3 ✓

### 9.3 Snapshot Tests

> **Note:** Snapshot tests require `swift-snapshot-testing` package. Deferred to v1.1.

- [-] **9.3.1** Add Inventory list snapshot (blocked - requires third-party package)
- [-] **9.3.2** Add Item detail snapshot (blocked - requires third-party package)
- [-] **9.3.3** Add Paywall snapshot (blocked - requires third-party package)
- [-] **9.3.4** Add Reports tab snapshot (blocked - requires third-party package)

---

## Phase 10: v1.1 Hooks & Experimental Features (P3)

> **Goal:** Preparation for post-1.0 enhancements

### 10.1 CloudKit Sync Toggle

- [x] **10.1.1** Make sync explicitly opt-in & experimental ✓ 2025-11-28
  - **DECISION:** Disable CloudKit for v1.0 (local-only storage)
  - Default `cloudKitDatabase: .none` for v1.0 configuration
  - Safer for launch, avoids sync bugs
  - CloudKit sync will be added in v1.1 when thoroughly tested

- [x] **10.1.2** Sync stability monitoring plan (v1.1) ✓ 2025-11-29
  - Created CloudKitSyncMonitor.swift service
  - Monitors NSPersistentStoreRemoteChange notifications
  - Logs sync events with DEBUG-only logging
  - Tracks iCloud availability and account status changes
  - Add coarse logging (non-PII) for sync errors in debug builds
  - Keep CloudKit disabled in production until tested thoroughly on sample data

### 10.2 Warranty & Search Enhancements

- [x] **10.2.1** Warranty list with expiry filters ✓ 2025-11-29
  - Created WarrantyListView.swift with filters (All, Expiring Soon, Active, Expired)
  - Shows items with warrantyExpiryDate set
  - Summary cards for active/expiring/expired counts
  - Filter chips with counts
  - New screen / filter showing items with upcoming warranty expiry
  - Simple local notifications if user opts in

- [x] **10.2.2** Enhanced search syntax ✓ 2025-11-29
  - Added SearchQuery parser in InventoryTabViewModel
  - Supports: room:, category:/cat:, value>/<//</:, tag:, has:photo/receipt, no:photo/receipt
  - Added SearchHelpSheet with syntax documentation
  - Added search help button in toolbar
  - Search by `room:Kitchen`, `category:Electronics`, or `value>1000`
  - Document syntax in a small "Search help" sheet

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

- [x] **5.2.1** Create AppEnvironment DI container (completed 2025-11-28)
- [x] **5.2.2** Remove SettingsManager.shared singleton (completed 2025-11-28)
- [x] **5.2.3** Remove IAPValidator.shared singleton (completed 2025-11-28)
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

- [ ] **Swift 6 Migration** - Upgrade to Swift 6 strict concurrency mode
  - Fix all Sendable warnings for actor boundaries
  - Use @ModelActor for background SwiftData operations
  - Update @Observable classes for strict isolation
  - Target: v1.1 release
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

### Key Decisions Made ✓
1. ✅ Bundle ID: Keep `com.drunkonjava.Nestory-Pro` (Task 1.1.1) - 2025-11-28
2. ✅ Documentation score: 6-field weighted (Photo 30%, Value 25%, Room 15%, Category 10%, Receipt 10%, Serial 10%) (Task 1.4.1) - 2025-11-28
3. ✅ CloudKit sync: Disabled for v1.0, add in v1.1 (Task 10.1.1) - 2025-11-28
4. ✅ Swift version: Ship v1.0 with Swift 5 language mode, migrate to Swift 6 in v1.1 - 2025-11-29
   - Toolchain: Swift 6.2.1 (latest Xcode) provides optimizations
   - Language mode: Swift 5.0 avoids strict concurrency errors blocking launch
   - Reason: Swift 6 strict concurrency surfaces ~20 warnings needing careful actor/Sendable fixes

### Testing Requirements
- All new code must have tests
- Minimum 60% code coverage for new files
- Run tests before marking task complete

---

*Last Updated: November 29, 2025*
*Task Count: 124 tasks (0 in progress, 105 completed, 19 remaining)*
- Completed: 7.2.2 Beta lane automation (tag triggers + skip tests option)
- Completed: 9.2.1-9.2.3 UI tests (CaptureUITests, LossListUITests)
- Blocked: 9.3.x Snapshot tests (require third-party package)
- Fixed: iOS compatibility in BackupService ZIP extraction

### Changelog
- **2025-11-29**: Added TipKit integration (8.3.1-8.3.3) with documentation, iCloud sync, and quick capture tips
- **2025-11-29**: Completed accessibility labels (8.1.1-8.1.4), color alternatives (8.2.1-8.2.2), and service tests (9.1.3-9.1.5)
  - Added accessibility labels to InventoryTab, SharedComponents, SettingsTab, ItemDetailView
  - Added status text to DocumentationBadge and documentation score display
  - Created BackupServiceTests, ReportGeneratorServiceTests, AppLockServiceTests
- **2025-11-29**: Merged comprehensive v1.0 production-readiness tasks
  - Added Phase 1.1 (Bundle ID & Project Configuration)
  - Added Phase 1.3 (SwiftData Schema & Migrations)
  - Added Phase 1.5 (AppEnvironment verification)
  - Added Phase 2.1 (Fix AddItemView critical issues)
  - Added Phase 2.2-2.3 (Inventory polish tasks)
  - Added Phase 3.5 (Backup Import preparation)
  - Added Phase 7 (Release Engineering & CI)
  - Added Phase 10 (v1.1 Hooks & Experimental Features)
  - Renumbered existing tasks to accommodate new structure
  - Total: +43 new tasks for production readiness

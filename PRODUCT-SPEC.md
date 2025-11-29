Here’s a full-blown tech/product spec for **Nestory v1** with a sane MVP scope, clear roadmap, and enough detail that you could hand this to “Future Griffin + AI co-pilot” and actually ship something.

---

# 1. Product Overview

**Name:** Nestory – Home Inventory for Insurance
**Platform:** iOS 17+ (iPhone first; iPad-friendly layouts as stretch)
**Primary Goal:** Make it stupidly easy for normal humans to be *claim-ready* before something bad happens.

### Core v1 Value Proposition

> “Nestory helps you prove what you owned, what it was worth, and where it was — with the least possible work.”

We do that via:

* Fast **item capture** (photos + minimal fields)
* Simple **receipt OCR** for date/vendor/amount
* Clear **documentation status** (badges + score)
* **Insurance-ready PDFs** for inventory and loss lists
* Local-first storage with **optional iCloud sync**

---

# 2. Scope: v1 vs Future

### v1 – What’s In

1. **Inventory Management**

   * Items with:

     * Name, optional brand/model/serial
     * Category and room
     * Purchase price & date
     * Condition (basic scale)
     * 1+ photos
     * Optional “warranty expiry date” (simple, no full dashboard yet)
   * Grid/list view, filtering, search
   * Documentation badges: Missing photo / receipt / value / serial
   * Quick-add flows

2. **Capture**

   * **Photo capture** for new items
   * **Receipt capture** with OCR:

     * Extract: vendor, date, total
   * **Barcode scanner** for product lookup (basic)
   * “Scan result” review screen

3. **Reports**

   * **Full Inventory PDF**:

     * Item list with key fields
     * Optional photos (toggle)
     * Totals by room and by category
   * **Loss List PDF**:

     * User selects items
     * Outputs a simple, adjuster-friendly table
   * Basic “export history” list

4. **Basic Analytics**

   * Top-level stats:

     * Total items
     * Estimated total value
     * Documentation score (% items with minimum acceptable documentation)
   * Simple visuals:

     * Pie chart: value by category
     * Bar chart: items by room

5. **Settings / Data**

   * iCloud sync toggle
   * Basic backup/export (JSON + images as zip; v1 can be local export only)
   * Currency selection
   * App lock (Face ID / Touch ID)
   * Free vs Pro feature gating

### Not in v1 (Roadmap Only)

* Full **warranty dashboard** and analytics
* Deep **claims workflows** (stepper with insurers, timeline, communication logs)
* **Repair cost estimation** tools
* Estate planning exports
* Household sharing / multiple users
* AI-enhanced video walkthrough processing
* Direct carrier integrations or formal partnerships

Those go into a structured roadmap later in this doc.

---

# 3. Monetization Strategy (v1)

### Free Tier

* Up to **100 items**
* Unlimited photos per item
* Receipt OCR included (soft rate limit if needed)
* Full inventory PDF (no photos, summary only)
* Loss List PDF for up to 20 items
* iCloud sync enabled

### Pro Tier – **Nestory Pro (One-Time Unlock)**

* Non-consumable IAP: `com.drunkonjava.nestory.pro`
* Recommended price: **$19.99–$24.99** (you can tune later)
* Unlocks:

  * Unlimited items
  * Unlimited loss list size
  * Full inventory PDF **with photos**
  * Advanced export (CSV, JSON bundle)
  * Additional visuals in analytics (e.g., more breakdowns)
  * Priority local OCR queue (if you later differentiate features)

### Future Monetization (Roadmap Only)

* **“Claim Pack Pro”** one-time IAP:

  * Extra export formats (custom templates, cover letter, etc.)
* **Pro for Professionals** (public adjusters, estate planners):

  * Workspace/client support, white-label PDFs

For v1 and App Store review sanity: keep monetization **simple** (one Pro unlock, clear paywall boundaries).

---

# 4. Technical Stack & Frameworks

### Languages & Tools

* **Language:** Swift 6 (strict concurrency)
* **UI:** SwiftUI
* **Persistence:** SwiftData (backed by SQLite) + CloudKit for sync
* **IDE:** Xcode latest + Swift Package Manager (SPM)

### Apple Frameworks to Use

* **SwiftUI**

  * All views and navigation; no UIKit-first approach.
* **SwiftData**

  * Primary persistence layer for Items, Rooms, Categories, Receipts.
* **CloudKit**

  * Lightweight sync layer via SwiftData + CloudKit integration.
* **Vision / VisionKit**

  * OCR (text recognition) for receipts.
  * Rectangle detection for receipt cropping if needed.
* **AVFoundation**

  * Fine-grained camera control for capture views if VisionKit alone isn’t enough.
* **Core Image**

  * Optional image pre-processing (contrast/deskew tweaks for receipts).
* **Core Graphics / Charts**

  * Use **Swift Charts** (iOS 16+) for the simple graphs in analytics.
* **StoreKit 2**

  * IAP (Nestory Pro unlock) with Swift concurrency.
* **UserNotifications**

  * Basic local notifications (for simple reminders; full warranty reminders are roadmap).
* **AuthenticationServices / LocalAuthentication**

  * Face ID / Touch ID app lock.
* **TipKit**

  * Contextual in-app tutorials (“tooltips” but native and structured).

### Libraries / Patterns to Avoid (v1)

* Avoid **Firebase Analytics** or any third-party analytics SDK:

  * Keeps privacy story clean.
* Avoid **heavy cross-platform UI frameworks** (React Native, Flutter) for this project:

  * You want native-level polish, SwiftUI is enough.
* Avoid building your own networking-based OCR for v1:

  * Use on-device Vision; if you must use a 3rd-party API eventually, treat as v1.5+.
* Avoid massive monolithic view controllers or mix-and-match of UIKit + SwiftUI:

  * Only use UIKit wrappers where absolutely necessary (e.g., custom camera experience), via `UIViewControllerRepresentable`.

---

# 5. High-Level Architecture

### Architectural Pattern

* **MVVM** with a clean layering:

  * **Model Layer**

    * SwiftData models (`@Model` types)
    * Plain Swift value types for derived/computed data (e.g., `DocumentationStatus`, `ReportConfig`).

  * **Repository Layer**

    * `InventoryRepository`: CRUD for Items, Rooms, Categories.
    * `ReceiptRepository`: Manage receipts, OCR results, linking.
    * `ReportRepository`: Query & transform models for export.
    * `SettingsRepository`: Wraps `UserDefaults` / `AppStorage`.

  * **Service Layer**

    * `OcrService` (Vision-based)
    * `BarcodeLookupService` (basic, possibly stub implementation from open product catalogs)
    * `ReportGeneratorService` (PDF generation)
    * `BackupService` (export/import JSON + images)
    * `AppLockService` (LocalAuthentication)

  * **Presentation Layer**

    * SwiftUI views + `Observable`/`@Observable` view models.
    * Feature-oriented: `InventoryViewModel`, `CaptureViewModel`, `ReportsViewModel`, `SettingsViewModel`.

### Project Structure

Use SPM modules or logical groups:

* `AppCore`

  * App entry, environment, dependency injection container.
* `InventoryFeature`
* `CaptureFeature`
* `ReportsFeature`
* `SettingsFeature`
* `SharedUI` (buttons, cards, badge components, list cells)
* `Services` (OCR, Reports, etc.)
* `Models` (SwiftData + shared types)

### Dependency Injection

* A simple **factory or container** pattern:

  * `AppEnvironment` struct holding configured services & repos.
  * Inject into view models via `.environment` or initializer parameters.
  * Example:

    ```swift
    struct AppEnvironment {
        let inventoryRepository: InventoryRepository
        let receiptRepository: ReceiptRepository
        let ocrService: OcrService
        let reportService: ReportService
        let settingsRepository: SettingsRepository
    }
    ```

---

# 6. Information Architecture & Navigation

### Bottom Tab Bar (4 Tabs)

1. **Inventory**
2. **Capture**
3. **Reports**
4. **Settings**

Search is integrated directly inside the Inventory tab; analytics summary sits at the top of the Inventory tab.

---

# 7. Screen-by-Screen Layout (v1)

## 7.1 Inventory Tab

**Goal:** Primary “home” for users; show key stats + browse/manage items.

### Layout (top to bottom)

1. **Navigation Bar**

   * Title: `Inventory`
   * Right: `+` button (Add Item – opens Add Item sheet)
   * Left: no button in v1, keep it clean

2. **Summary Strip (ScrollView / HStack of cards)**

   * Card 1: **Total Items**

     * Large count, e.g., “124 items”
     * Subtitle: “Across 9 rooms”
   * Card 2: **Estimated Value**

     * “$54,300”
     * Subtitle: “Based on entered values”
   * Card 3: **Documentation Score**

     * “Documentation: 78%”
     * Subtitle: “Items with photo + value + category”

   Each card is tappable to show a detail sheet:

   * Documentation card tap → “What counts as documented?” with breakdown.

3. **Analytics Snapshot (optional simple charts)**

   * **Pie chart**: Value by category.
   * Underneath: 2–3 small legend rows.

4. **Search & Filter Row**

   * Search bar (SwiftUI `Searchable`) pinned at top of list.
   * Horizontal filter chips below:

     * “All items”
     * “Needs photo”
     * “Needs receipt”
     * “Needs value”
     * “High value (> $1000)”

5. **List/Grid Toggle + Sort**

   * Segmented control: List | Grid
   * Sort menu (popup):

     * Name A–Z
     * Value high → low
     * Newest added

6. **Item List/Grid**

   * **List Cell content**:

     * Thumbnail photo (or category icon if no photo)
     * Title: Item name
     * Subtitle: `Room • Category • $Value` (if value present)
     * Right side: Documentation badges as small chips:

       * `Photo` (green/gray)
       * `Receipt` (green/gray)
       * `Value` (green/gray)
   * Tap → Item Detail screen

### Item Detail View

Sections (scrollable):

1. Header

   * Large photo carousel (pager) at top
   * Item name + brand/model
   * Room + Category pills

2. Basic Info

   * Purchase price + date
   * Serial number (if set)
   * Condition (segmented control or read-only text)

3. Documentation Status

   * Badges with labels:

     * ✅ Photo
     * ⚠️ No receipt
     * ⚠️ No serial
   * Link to “What’s missing?” sheet.

4. Receipts Section

   * List of linked receipts (thumbnail + vendor/date/amount)
   * Button: “Link receipt” -> opens selection or capture prompt

5. Simple Warranty Info (v1)

   * Optional: warranty expiry date, text note
   * Button: “Set warranty expiry”

6. Quick Actions (sticky bottom bar)

   * `Edit`
   * `Add photo`
   * `Add receipt`
   * `Add to Report` (pre-selects into next Loss List generation)

---

## 7.2 Capture Tab

**Goal:** One place to quickly “dump” info into the system.

### Layout

1. **Navigation Bar**

   * Title: `Capture`

2. **Segmented Control**

   * `Photo Item` | `Receipt` | `Barcode`

3. **Capture Area (mode-specific)**

**Photo Item mode:**

* Full-width camera preview (top ~2/3 of screen).
* Bottom overlay:

  * Big round shutter button centered.
  * Left: “Gallery” (pick existing photo).
  * Right: “Flash” toggle or “Info” (tip about framing).
* After capture → “Quick Item Form” sheet:

  * Name (required)
  * Room (picker)
  * Category (picker)
  * Optional value + date
  * Save → creates item with 1 photo.

**Receipt mode:**

* Similar camera preview.
* Auto rectangle detection overlay.
* Capture → “Processing…” spinner.
* Result screen:

  * Receipt image
  * Extracted fields:

    * Vendor (text field prefilled)
    * Date
    * Total
  * Buttons:

    * “Link to existing item”
    * “Create new item from this receipt”

**Barcode mode:**

* Camera preview with square scan area.
* On scan:

  * Show product match (if any) with:

    * Name
    * Brand
    * Category suggestion
  * Quick form to add:

    * Name (editable)
    * Room
    * Value
  * Save → item with barcode stored and details populated.

4. **Recent Captures strip (bottom)**

   * Small horizontal strip with thumbnails of last 3 captured items/receipts
   * Tapping opens the associated item/receipt detail.

---

## 7.3 Reports Tab

**Goal:** Generate evidence you can hand to an adjuster.

### Layout

1. **Navigation Bar**

   * Title: `Reports`

2. **Summary Section**

   * Info text: “Create inventory summaries and loss lists for insurance.”
   * Quick stats:

     * “Total items: 124”
     * “Documented items: 92 (74%)”

3. **Primary Actions (Cards or Buttons)**

* **Card 1: Full Inventory PDF**

  * Title: “Full Inventory Report”
  * Subtitle: “All items with values and documentation status.”
  * Button: `Generate`
  * Tapping opens config sheet:

    * Toggle: Include photos (Pro-only if you want)
    * Group by: Room / Category
    * Include undocumented items? (Yes/No)

* **Card 2: Loss List PDF**

  * Title: “Loss List”
  * Subtitle: “Select items for a specific incident.”
  * Button: `Start`
  * Flow:

    * Multi-select list of items (with filters).
    * Confirm screen shows total values and item count.
    * `Generate PDF` button.

4. **Report History**

   * List of previously generated reports:

     * Name (Full Inventory / Loss List)
     * Date generated
     * Size
   * Tap → share sheet for PDF (no need to store contents forever).

---

## 7.4 Settings Tab

**Goal:** Configuration, account-ish things, Pro purchase, privacy.

### Layout

Group into sections.

1. **Account & Pro**

   * If free:

     * Cell: “Nestory Pro” with badge `Upgrade`
     * Detail: “Unlimited items, advanced exports, and more.”
     * Tap → Pro paywall screen.
   * If Pro:

     * “Nestory Pro” with `Active` badge and restore purchases.

2. **Data & Sync**

   * Toggle: `Use iCloud Sync`
   * Cell: “Export data”

     * Sub: JSON + images (zip)
   * Cell: “Import data”
   * Storage summary:

     * “X MB used, Y photos”

3. **Appearance**

   * Theme: Light / Dark / System
   * Currency: dropdown (USD, EUR, etc.)

4. **Security & Privacy**

   * Toggle: `Require Face ID / Touch ID on launch`
   * Toggle: `Lock after 5 minutes inactive`

5. **Notifications (minimal for v1)**

   * Toggle: “Enable reminders for documentation”

     * If on: suboption: “Weekly summary reminder”

6. **About**

   * Version, build
   * Links to:

     * Terms of Service
     * Privacy Policy
     * Support email

---

# 8. Data Model (v1)

Using SwiftData `@Model` where appropriate.

### Item

```swift
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var modelNumber: String?
    var serialNumber: String?

    var purchasePrice: Decimal?
    var purchaseDate: Date?
    var currencyCode: String

    @Relationship var category: Category?
    @Relationship var room: Room?

    var condition: ItemCondition
    var conditionNotes: String?

    @Relationship(.cascade) var photos: [ItemPhoto]
    @Relationship(.nullify) var receipts: [Receipt]

    var warrantyExpiryDate: Date?
    var tags: [String]

    var createdAt: Date
    var updatedAt: Date
}
```

### ItemPhoto

```swift
@Model
final class ItemPhoto {
    @Attribute(.unique) var id: UUID
    var imageIdentifier: String  // local filename or asset ID
    var createdAt: Date
}
```

(You probably want file-based photo storage with paths in the DB, not raw `Data` for large image sets.)

### Receipt

```swift
@Model
final class Receipt {
    @Attribute(.unique) var id: UUID
    var vendor: String?
    var total: Decimal?
    var taxAmount: Decimal?
    var purchaseDate: Date?

    var imageIdentifier: String
    var rawText: String?
    var confidence: Double

    @Relationship(.nullify) var linkedItem: Item?
    var createdAt: Date
}
```

### Category / Room

```swift
@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var isCustom: Bool
}

@Model
final class Room {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
}
```

### Settings (non-model)

Use `@AppStorage` or `UserDefaults` via `SettingsRepository` for:

* `maxFreeItems`
* `isProUnlocked`
* `preferredCurrencyCode`
* `themePreference`
* `useICloudSync`
* `requiresBiometrics`

---

# 9. Analytics & Data Visuals (User-Facing)

Not telemetry; these are visuals shown to the user.

### Documentation Score

* Definition (v1): Item is “documented” if:

  * Has at least one photo
  * Has a value
  * Has a category & room

* Display:

  * Percentage bar + explanation tooltip:

    * “Documented items have a photo, value, and location assigned.”

### Charts

Use **Swift Charts**:

1. **Value by Category (Pie-like donut)**

   * Category as segments, value as sum.
2. **Items by Room (Horizontal bar)**

   * Bars sorted descending by item count.

### Useful stats

* “Items needing photos: 23”
* “Items missing receipts: 12”
* “High-value items (> $1000): 18”

These show up on the Inventory tab under the summary strip, maybe as a clickable row: “Improve documentation” → list pre-filtered.

---

# 10. Tooltips & In-App Education

Use **TipKit** and light inline copy. Tooltips should be real, not patronizing.

Examples:

1. **Documentation Score Card**

   * Tip text:

     > “This score tells you how many items have enough proof for an insurance claim: a photo, a location, and a value. Aim for 80%+.”

2. **First Time on Capture Tab**

   * On Photo mode:

     > “Start by taking photos of your most valuable items: TVs, laptops, jewelry, and instruments. You can fill in the details later.”

3. **Missing Data Badges (Item Detail)**

   * Tap on badge `Missing receipt`:

     * Sheet:

       > “Receipts aren’t required, but they’re strong evidence for value and purchase date. Add a photo of a paper receipt or a screenshot of an email.”

4. **Reports Tab (first visit)**

   * Tip near “Full Inventory Report”:

     > “Most insurers accept a PDF inventory with photos and values. Generate this once you’ve documented your key items.”

5. **Pro Paywall**

   * Clear and honest:

     > “Nestory Pro unlocks unlimited items and advanced reports. It’s a one-time purchase — no subscriptions, no ads.”

---

# 11. Design & Layout Principles

### Visual Style

* Clean, slightly “insurance-grade,” not cutesy.
* Neutral palette with one accent color:

  * Background: off-white / dark mode friendly
  * Accent: a reassuring blue or teal (trust/insurance vibe)
* Generous spacing, legible typography (SF Pro Text, 17–20pt for body).

### Component Patterns

* **Cards** for summary panels and actions.
* **Pills** for categories/rooms.
* **Badges** for documentation status.
* Simple **segmented controls** for list/grid and capture modes.

### Interaction Standards

* Almost everything is **tappable** with clear feedback.
* Heavy actions (delete item, clear all data) → confirmation sheets.
* Long-press on an item for quick actions: “Add to loss list,” “Edit,” “Add photo.”

---

# 12. Areas for Additional Research

1. **Insurer Expectations**

   * What do major carriers actually recommend for home inventories?
   * Common export formats adjusters like (CSV vs PDF vs both).
   * Phrasing for descriptions that avoids implying you’re a legal/financial advisor.

2. **Vision OCR Performance**

   * Benchmark on typical receipt photos.
   * How well does it handle:

     * Crumpled receipts
     * Low light
     * Curved surfaces
   * When to fall back to “manual mode” gracefully.

3. **Photo Storage Strategy**

   * Tradeoff: SwiftData `Data` blobs vs file-based storage.
   * Impact on iCloud sync size and performance.

4. **iCloud + SwiftData Reliability**

   * Battle scars research: known issues, best practices, conflict merging strategies.

5. **App Store Review Risk**

   * Wording around:

     * Insurance claims
     * “Accepted by all insurers” (avoid that)
     * Warranty suggestions
   * Keep copy in “helps you prepare” territory.

6. **Accessibility**

   * VoiceOver support for all charts and badges.
   * Large text compatibility.

---

# 13. Roadmap (Post-v1)

### v1.1 – Quality & Depth

* Warranty dashboard:

  * List of items with warranty expiry dates.
  * Simple “expiring soon” view.
* More detailed analytics:

  * Time-based graphs (items added per month).
* Improved search syntax (filters like `missing:photo` directly in search bar).

### v1.2 – Claims & Disaster Workflows

* “Incident mode”:

  * Create an incident (e.g., “Kitchen fire”).
  * Attach items + photos + receipts to that incident.
  * Auto-generate claim pack for that incident.
* Basic “incident notes” field for narrative.

### v2 – Pro/Professional & AI

* Shared household access (family accounts).
* White-label exports:

  * Logos for public adjusters / professionals.
* Video walkthrough support:

  * Store video, optionally run on-device analysis to propose items.
* Smarter AI-assist:

  * Suggest item names/categories from photo.
  * Suggest values based on similar items (careful with disclaimers).

---

# 14. Non-Functional Requirements

* **Performance**

  * App should feel snappy with up to 5,000 items.
  * Cold launch < 2s on modern devices.

* **Offline First**

  * Everything usable offline; sync is best-effort.

* **Reliability**

  * Never lose data. Use safe migrations for SwiftData.

* **Privacy**

  * No third-party tracking or analytics.
  * Clear, human-readable privacy policy.

* **Testing**

  * Unit tests for:

    * Repositories
    * OCR parsing helpers
    * Report generation logic
  * Snapshot tests for:

    * Inventory list/grid
    * Item detail
    * Reports config sheets

---

# 15. Implementation Status Summary

**Last Updated:** 2025-11-29

## Core Features Status

| Feature | Status | Notes |
|---------|--------|-------|
| **Inventory Management** | ✅ Complete | Grid/list views, filtering, search |
| **Item Model** | ✅ Complete | All fields, documentation score, validation |
| **Photo Capture** | ✅ Complete | Camera + Photos picker, async loading |
| **Receipt OCR** | ✅ Complete | Vision framework, confidence scoring |
| **Barcode Scanning** | ✅ Complete | Scan-only v1.0, stores barcode string |
| **Full Inventory PDF** | ✅ Complete | Grouping options, Pro photo support |
| **Loss List PDF** | ✅ Complete | Multi-select, incident details, 20-item free limit |
| **Data Export (JSON)** | ✅ Complete | Full backup with relationships |
| **Data Export (CSV)** | ✅ Complete | Pro-gated |
| **Data Import/Restore** | ✅ Complete | Merge/replace strategies |
| **Pro Paywall** | ✅ Complete | StoreKit 2, contextual prompts |
| **Item Limit Enforcement** | ✅ Complete | 100-item free tier |
| **App Lock (Biometrics)** | ✅ Complete | Face ID / Touch ID |
| **Settings Tab** | ✅ Complete | All v1 options |

## Architecture Status

| Component | Status | Notes |
|-----------|--------|-------|
| **SwiftData Models** | ✅ Complete | Item, Category, Room, Receipt, ItemPhoto |
| **VersionedSchema** | ✅ Complete | Migration scaffolding ready |
| **MVVM ViewModels** | ✅ Complete | All tabs have @Observable VMs |
| **AppEnvironment DI** | ✅ Complete | 7 services injected via @Environment |
| **Protocol-based Testing** | ✅ Complete | Mock implementations for all services |

## Pending for v1.0 Release

| Task | Priority | Category |
|------|----------|----------|
| Sync spec docs with code (this task) | P0 | Documentation |
| Fix Match / API key configuration | P1 | Release Engineering |
| Finalize fastlane lanes | P1 | Release Engineering |
| GitHub Actions CI workflows | P1 | Release Engineering |
| App Store metadata & screenshots | P1 | Release Engineering |
| Privacy policy & support URL | P1 | Release Engineering |
| Accessibility labels (WCAG 2.1 AA) | P2 | Accessibility |
| Additional service tests | P2 | Testing |
| UI flow tests | P2 | Testing |

## Known Issues

1. **CloudKit sync disabled for v1.0** - Using local-only SwiftData container pending CloudKit configuration
2. **Photo backup not in ZIP** - Photos stored locally, not included in JSON backup (planned for v1.1)
3. **No product lookup from barcode** - Barcode is stored but not used for auto-fill (planned for v1.1)

## Task Progress

- **Completed:** 82 tasks
- **Pending:** 42 tasks
- **Overall Progress:** ~66%

---

This gives you:

* A sharply defined v1 that you can actually ship.
* A clear mental model of how each tab behaves and how the user flows connect.
* A roadmap that layers in the more ambitious “insurtech” stuff without drowning you immediately.

From here, the next practical step is usually:

* turn this into a small `Docs/` folder in your repo (`PRODUCT_SPEC.md`, `DATA_MODEL.md`, `ARCHITECTURE.md`) and then start a skeleton SwiftUI project that wires up the tabs and basic models while everything is still fresh in your head.

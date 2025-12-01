# Nestory Pro - Competitive Feature Backlog

<!--
================================================================================
CLAUDE CODE AGENT INSTRUCTIONS - READ BEFORE WORKING
================================================================================

This document captures COMPETITIVE FEATURE GAPS identified through market research.
These are features that competitors have but Nestory Pro does not yet implement.

DOCUMENT PURPOSE:
  - Single source of truth for competitive feature priorities
  - Complements TODO.md (which tracks implementation tasks)
  - Research-backed with competitor references
  - Approved features get promoted to TODO.md for implementation

TASK STATUS LEGEND:
  - [ ] Available    = Feature identified, not yet scheduled
  - [~] In Progress  = Being implemented (see TODO.md for subtasks)
  - [x] Completed    = Feature shipped
  - [-] Blocked      = Cannot proceed (see blocker note)
  - [!] Needs Review = Needs product owner decision

APPROVAL RULES:
- Features MUST be approved by product owner before implementation
- Approved features are added to TODO.md with proper task IDs
- Do NOT start implementation without TODO.md task assignment
- Cross-reference with TODO.md using "Tracked-in: P#-##" notation

SCOPE RULES:
- Do NOT add features without competitive research backing
- Do NOT modify pricing tier assignments without approval
- Features marked "Pro" require purchase; "Free" are available to all users

RESEARCH SOURCES:
- App Store analysis (ratings, reviews, feature lists)
- Web search (company websites, comparison articles)
- User feedback (Reddit, support forums, review sites)
- Direct app testing (competitor demos)

================================================================================
-->

## Research Summary

**Analysis Date:** December 1, 2025
**Competitors Analyzed:** 15+ apps
**Research Method:** Multi-agent web search, app store analysis, user review aggregation

### Competitor Landscape

| Segment | Price Range | Key Players | Market Gap |
|---------|-------------|-------------|------------|
| **Free** | $0 | NAIC, Know Your Stuff | Outdated, basic exports |
| **Budget** | $3-$5 | Home Contents, Supplies | No OCR, limited features |
| **Mid-Tier** | $5-$30/mo | Sortly, Itemtopia | Subscription fatigue, business-focused |
| **Enterprise** | $270+/mo | Encircle, Xactimate | Overkill for consumers |

**Nestory Pro Position:** Premium one-time purchase ($19.99-24.99) targeting gap between free/basic and expensive subscriptions.

---

## Active Checkouts

> When you check out a feature for implementation, add entry here. One active feature per agent.

| Feature ID | Agent ID | Checkout Time | Notes |
|------------|----------|---------------|-------|
| (none) | (none) | (none) | (none) |

---

## Competitive Advantages (Already Implemented)

These features differentiate Nestory Pro from competitors:

| Feature | Nestory Pro | Competitors | Advantage |
|---------|-------------|-------------|-----------|
| **Receipt OCR** | ✅ Vision framework | ❌ Most lack OCR | Unique in consumer segment |
| **Documentation Score** | ✅ Gamified progress | ❌ No gamification | Motivates completion |
| **One-Time Purchase** | ✅ $19.99-24.99 | ❌ $85-96/year | No subscription fatigue |
| **Privacy-First** | ✅ SwiftData + iCloud | ❌ Cloud-only | User controls data |
| **Loss List PDF** | ✅ 20 items free | ❌ Most gate exports | Free tier value |
| **Native iOS** | ✅ Swift 6, SwiftUI | ❌ Web wrappers | Performance, polish |

---

## ✅ APPROVED: v1.2 Features

> **Status:** Approved by product owner (2025-12-01)
> **Target:** Q1 2026
> **Tracked-in:** TODO.md (pending task creation)

### F1 – Barcode Scanning with Product Lookup ⭐⭐⭐⭐⭐ ✅ COMPLETED

**Priority:** MUST HAVE
**Tier:** Free (scan) / Pro (lookup)
**Effort:** Medium
**Status:** ✅ COMPLETED (2025-12-01)

**Competitive Analysis:**
- **Nest Egg:** 6M+ items scanned, best-in-class UPC recognition
- **Sortly:** QR codes only (no UPC lookup)
- **Itemtopia:** Basic barcode with limited database
- **NAIC:** Has scanning, no lookup
- **User Demand:** "Expected feature in 2024" - multiple reviews

**Implementation Completed:**
- [x] **F1-01** VisionKit barcode detection (VNBarcodeObservation) - already existed
- [x] **F1-02** Support formats: UPC-A, UPC-E, EAN-8, EAN-13, QR, Code128
- [x] **F1-03** UPCitemdb API integration (free tier: 100/day, 15K/month)
- [x] **F1-04** Product info autofill: name, brand, category, MSRP
- [x] **F1-05** Fallback to manual entry if not found
- [x] **F1-06** Barcode field on Item model (verified)
- [ ] **F1-07** Unit tests for barcode parsing and API integration (TODO)

**Files Created/Modified:**
- `Services/ProductLookupService.swift` (NEW - UPCitemdb API integration)
- `Views/Capture/BarcodeScanView.swift` (enhanced QuickAddBarcodeSheet)
- `AppEnvironment.swift` (added productLookupService)

---

### F2 – QR Code Label Generation & Printing ⭐⭐⭐⭐⭐ ✅ COMPLETED

**Priority:** SHOULD HAVE
**Tier:** Pro
**Effort:** Low-Medium
**Status:** ✅ COMPLETED (2025-12-01)

**Competitive Analysis:**
- **Sortly:** Standout feature - QR labels for boxes/containers
- **Itemtopia:** QR code support with label printing
- **Everspruce:** QR code label generation
- **Nest Egg:** QR code support
- **Use Case:** Physical labels for moving, storage, insurance claims

**Implementation Completed:**
- [x] **F2-01** QR code generation via CoreImage (CIQRCodeGenerator)
- [x] **F2-02** Deep link URL scheme: `nestory://item/{uuid}`
- [x] **F2-03** Label templates:
  - Small (1" x 1"): QR only
  - Medium (2" x 1"): QR + item name
  - Large (3" x 2"): QR + name + location + value
- [x] **F2-04** AirPrint integration for label printing
- [x] **F2-05** Batch QR generation for rooms (room filter in LabelGeneratorView)
- [x] **F2-06** "Scan to find" feature (scan QR → navigate to item via deep link)
- [ ] **F2-07** Unit tests for QR generation and deep link parsing (TODO)

**Files Created/Modified:**
- `Services/QRCodeService.swift` (NEW - QR code generation & deep link parsing)
- `Views/Reports/LabelGeneratorView.swift` (NEW - label templates, preview, print)
- `Views/Reports/ReportsTab.swift` (enhanced - QR Labels section)
- `Info.plist` (URL scheme registration)
- `Nestory_ProApp.swift` (deep link handling via .onOpenURL)
- `Views/MainTabView.swift` (deep link navigation to inventory tab)
- `Views/Inventory/InventoryTab.swift` (deep link item detail sheet)

---

### F3 – Warranty Expiration Reminders ⭐⭐⭐⭐ ✅ COMPLETED

**Priority:** MUST HAVE
**Tier:** Free
**Effort:** LOW (field exists, just needs notifications)
**Status:** ✅ COMPLETED (2025-12-01)

**Competitive Analysis:**
- **Itemtopia:** 30-day auto-reminders before warranty expiry
- **BluePlum:** Warranty tracking with notifications
- **Nest Egg:** Warranty expiry tracking
- **Current State:** ~~Nestory has `warrantyExpiryDate` field but no notifications~~ NOW IMPLEMENTED

**Implementation Completed:**
- [x] **F3-01** Enhanced `ReminderService` with multi-day reminders
- [x] **F3-02** UserNotifications framework integration
- [x] **F3-03** Reminder schedule:
  - 30 days before expiry (`warrantyExpiring30Day`)
  - 7 days before expiry (`warrantyExpiring7Day`)
  - Day of expiry (`warrantyExpiring`)
- [x] **F3-04** Settings toggle exists in RemindersView
- [x] **F3-05** Batch scheduling via `scheduleAllWarrantyReminders(context:)`
- [x] **F3-06** Authorization handling in ReminderService
- [x] **F3-07** Deep link via NotificationDelegate (VIEW_ITEM action)
- [ ] **F3-08** Unit tests for reminder scheduling logic (TODO)

**Files Created/Modified:**
- `Services/ReminderService.swift` (enhanced with multi-day support)
- `Services/NotificationDelegate.swift` (NEW - handles notification taps)
- `AppEnvironment.swift` (added notificationDelegate, factory methods)
- `Nestory_ProApp.swift` (wired notification delegate)
- `ViewModels/AddItemViewModel.swift` (auto-schedule on save)
- `Views/Inventory/AddItemView.swift` (wired ViewModel factory)

---

### F4 – Automated Item Valuation (Market Pricing) ⭐⭐⭐⭐ ✅ COMPLETED

**Priority:** SHOULD HAVE
**Tier:** Pro
**Effort:** Medium
**Status:** ✅ COMPLETED (2025-12-01)

**Competitive Analysis:**
- **EasyClaim:** eBay/Amazon pricing with link confirmations
- **Nest Egg:** Partial price lookup via barcode
- **BluePlum:** Depreciation tracking with suggested rates
- **Use Case:** "Am I underinsured?" - market-based replacement estimates

**Implementation Completed:**
- [x] **F4-01** Evaluated pricing APIs - using eBay Browse API with simulated fallback
- [x] **F4-02** Created `ValueLookupService` with 30-min response caching
- [x] **F4-03** "Check Value" button on ItemDetailView
- [x] **F4-04** Display: estimated range, source, last checked date
- [x] **F4-05** Added Item model fields:
  - `estimatedReplacementValue`, `estimatedValueLow`, `estimatedValueHigh`
  - `valueLookupSource`, `valueLookupDate`
  - `hasRecentValueEstimate`, `daysSinceValueLookup` computed properties
- [ ] **F4-06** Batch value update for inventory (TODO for v1.3)
- [x] **F4-07** Privacy: only sends name/brand/category, not personal data
- [ ] **F4-08** Unit tests for API integration and caching (TODO)

**Files Created/Modified:**
- `Services/ValueLookupService.swift` (NEW - eBay API integration with OAuth)
- `Views/Inventory/ItemDetailView.swift` (enhanced - Market Value section)
- `Models/Item.swift` (added value lookup fields)
- `AppEnvironment.swift` (added valueLookupService)

---

## 📋 Future Features (Research Complete, Pending Approval)

> Features below have competitive research but await product owner approval.
> Use `AskUserQuestion` before promoting to v1.3+.

### Tier 2: Medium Impact

#### [ ] F5 – Depreciation Tracking & Value History ⭐⭐⭐⭐
- **Who Has It:** BluePlum (annual logs, depreciation charts)
- **Use Case:** Estate planning, tax documentation, coverage analysis
- **Implementation:** `valueHistory: [ValueEntry]` model, chart visualization
- **Effort:** Medium
- **Tier:** Pro+
- **Target:** v2.0

---

#### [ ] F6 – Batch Import from Spreadsheets ⭐⭐⭐
- **Who Has It:** Sortly, Everspruce, MyStuff2 Pro
- **Use Case:** Users migrating from spreadsheets or other apps
- **Implementation:** CSV parser, field mapping UI
- **Effort:** Medium
- **Tier:** Pro
- **Target:** v1.3

---

#### [ ] F7 – Offline Mode Indicator ⭐⭐⭐⭐
- **Who Has It:** Encircle (full offline), Sortly (mobile only)
- **Current State:** SwiftData provides local-first storage
- **Gap:** Need explicit sync status indicator
- **Implementation:** Network monitor, sync status badge
- **Effort:** Low
- **Tier:** Free
- **Target:** v1.2

---

#### [ ] F8 – Batch Photo Capture Mode ⭐⭐⭐
- **Who Has It:** Everspruce (rapid photo capture, details later)
- **Use Case:** Quick inventory of many items, add details later
- **Implementation:** Camera roll → bulk import → edit queue
- **Effort:** Medium
- **Tier:** Free
- **Target:** v1.3

---

### Tier 3: Lower Priority

#### [ ] F9 – 3D Room Scanning ⭐⭐
- **Who Has It:** Under My Roof (LiDAR), Encircle (floor plans)
- **Use Case:** Spatial documentation for complex claims
- **Implementation:** RoomPlan API (iOS 16+, LiDAR devices)
- **Effort:** High
- **Tier:** Pro+
- **Limitation:** LiDAR requirement limits audience
- **Target:** v2.0+

---

#### [ ] F10 – macOS Catalyst ⭐⭐⭐
- **Who Has It:** BluePlum ($21 Mac app)
- **Use Case:** Desktop inventory management
- **Implementation:** Mac Catalyst target, keyboard shortcuts
- **Effort:** Medium
- **Tier:** Pro
- **Target:** v1.5

---

#### [ ] F11 – Insurance Company Integrations ⭐⭐⭐⭐
- **Who Has It:** Encircle (Guidewire), carrier-specific apps
- **Use Case:** Direct upload to insurance systems
- **Implementation:** API partnerships, carrier-specific exports
- **Effort:** High (requires partnerships)
- **Tier:** Enterprise
- **Target:** v3.0

---

## Market Opportunities

### Encircle Free User Migration 🚨

**Critical Date:** December 17, 2025

Encircle is discontinuing their free home inventory tier. Users must export data before this date.

**Opportunity:**
- [ ] Create Encircle import format support
- [ ] Marketing campaign: "Encircle shutting down? Switch to Nestory Pro"
- [ ] App Store keyword targeting: "encircle alternative"

**Status:** Deferred (product focus over marketing)

---

### Sortly Pricing Backlash

**Evidence:** Reddit, Trustpilot complaints about 93% annual price increases

**Opportunity:**
- [ ] SEO targeting: "Sortly alternative", "home inventory app no subscription"
- [ ] Comparison page highlighting one-time purchase model
- [ ] App Store screenshots emphasizing "Pay once, own forever"

**Status:** Deferred (product focus over marketing)

---

### NAIC App Abandonment

**Evidence:** No updates in 12+ months, crash reports, basic features

**Opportunity:**
- [ ] Position as "modern NAIC replacement"
- [ ] Target "NAIC home inventory" keywords
- [ ] Feature comparison showing OCR, photos in reports

**Status:** Deferred (product focus over marketing)

---

## Competitor Weaknesses to Exploit

| Competitor | Weakness | Nestory Advantage |
|------------|----------|-------------------|
| **Sortly** | $85/year subscription, price hikes | One-time $24.99 purchase |
| **Sortly** | Business-focused complexity | Consumer-focused simplicity |
| **Sortly** | No receipt OCR | Vision framework OCR |
| **Encircle** | $270/mo professional pricing | Consumer pricing |
| **Encircle** | Free tier ending Dec 2025 | Stable free tier |
| **NAIC** | Outdated, crashes | Modern SwiftUI, actively maintained |
| **NAIC** | Basic exports | PDF with photos, CSV export |
| **Nest Egg** | Confusing cloud pricing | Simple one-time purchase |
| **Itemtopia** | $96/year subscription | One-time purchase |

---

## Feature Comparison Matrix

| Feature | Nestory | Sortly | Encircle | Nest Egg | NAIC |
|---------|---------|--------|----------|----------|------|
| **Barcode Scan** | ✅ v1.2 | QR only | ✅ | ✅ Best | ✅ |
| **Product Lookup** | ✅ v1.2 | ❌ | ❌ | ✅ | ❌ |
| **QR Labels** | ✅ v1.2 | ✅ Best | ❌ | ✅ | ❌ |
| **Receipt OCR** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Warranty Alerts** | ✅ v1.2 | ❌ | ❌ | ✅ | ❌ |
| **Value Lookup** | ✅ v1.2 | ❌ | ❌ | Partial | ❌ |
| **Doc Score** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **One-Time Price** | ✅ | ❌ | ❌ | Partial | ✅ Free |
| **Offline Mode** | ✅ | ✅ | ✅ | Partial | ✅ |
| **PDF Export** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **CSV Export** | ✅ Pro | ✅ | ✅ | ✅ | ❌ |
| **Multi-Property** | 🔜 v1.3 | ✅ | ✅ | ❌ | ❌ |
| **3D Room Scan** | 🔜 v2.0+ | ❌ | ✅ | ❌ | ❌ |

---

## API Research Notes

### UPC Database APIs

| API | Free Tier | Rate Limit | Coverage | Notes |
|-----|-----------|------------|----------|-------|
| **Open Food Facts** | ✅ Unlimited | None | Food only | Open source, community |
| **UPCitemdb** | ✅ 15K/month | 100/day | General | Good for consumer goods |
| **Barcode Lookup** | ❌ | - | Comprehensive | Paid only, ~$10/month |
| **Digit Eyes** | ❌ | - | Comprehensive | Paid, accessibility focus |

**Recommendation:** Start with UPCitemdb free tier, upgrade if needed.

### Pricing APIs

| API | Free Tier | Notes |
|-----|-----------|-------|
| **eBay Browse API** | ✅ 5K/day | Good for used/refurbished values |
| **Amazon PAAPI** | ❌ | Requires Associate account, revenue |
| **PriceAPI** | ❌ | Aggregates multiple sources |

**Recommendation:** Start with eBay Browse API for market-based pricing.

---

## Notes

### Research Sources

- **Sortly:** sortly.com, App Store, Trustpilot, Reddit r/inventory
- **Encircle:** getencircle.com, App Store, G2, Capterra
- **Nest Egg:** nestegg.cloud, App Store
- **BluePlum:** theblueplum.com, Mac App Store
- **NAIC:** content.naic.org, App Store
- **Itemtopia:** itemtopia.com, App Store
- **Everspruce:** everspruceapp.com, App Store
- **EasyClaim:** easyclaimapp.com, App Store

### Key Insights

1. **Barcode scanning is table stakes** - Users expect it in 2024+
2. **Subscription fatigue is real** - One-time purchase is competitive advantage
3. **OCR is unique** - No consumer competitor has receipt OCR
4. **Documentation score is unique** - Gamification differentiates
5. **Encircle exit creates opportunity** - Dec 2025 migration window

---

## Pricing Tier Summary

> **IMPORTANT:** Tier assignments are product-owner controlled. Agents MUST NOT change without approval.

| Feature | Tier | Rationale |
|---------|------|-----------|
| Barcode scanning | Free | Table stakes, drives adoption |
| Product lookup | Pro | API costs, value-add |
| QR code labels | Pro | Power user feature |
| Warranty reminders | Free | Low cost, high value |
| Market value lookup | Pro | API costs, unique feature |
| Depreciation tracking | Pro+ | Complex, prosumer |
| CSV import | Pro | Migration feature |
| 3D room scanning | Pro+ | LiDAR requirement |

---

*Last Updated: December 1, 2025*

### Changelog

- **2025-12-01**: F2 QR Code Labels completed
  - Created QRCodeService with CoreImage CIQRCodeGenerator
  - Implemented label templates (small/medium/large)
  - Added deep link URL scheme (nestory://item/{uuid})
  - Integrated AirPrint for label printing
  - Added LabelGeneratorView with room filtering
  - Connected deep link navigation through app
- **2025-12-01**: F1 Barcode Scanning completed
  - Created ProductLookupService with UPCitemdb API
  - Fixed Swift 6 concurrency with MainActor.run for Codable decoding
  - Integrated auto-fill in QuickAddBarcodeSheet
- **2025-12-01**: F3 Warranty Reminders completed
  - Enhanced ReminderService with multi-day notifications
  - Created NotificationDelegate for deep link handling
- **2025-12-01**: Initial document created from competitive research
  - Analyzed 15+ competitors across 4 market segments
  - Identified 10 feature gaps with implementation approaches
  - Documented competitive advantages and weaknesses
  - Created API research notes for barcode and pricing
  - User approved F1-F4 for v1.2 implementation

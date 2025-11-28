# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Nestory Pro** is a native iOS 17+ app for home inventory management designed for insurance documentation. Built with Swift 6, SwiftUI, and SwiftData with CloudKit sync. Core features: fast item capture, receipt OCR via Vision framework, documentation status tracking, and insurance-ready PDF exports.

## Build & Test Commands

```bash
# Open in Xcode
open Nestory-Pro.xcodeproj

# Build (Debug)
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -configuration Debug

# Build for simulator
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'

# Run all tests (recommended)
bundle exec fastlane test

# Run tests with xcodebuild
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests                    # Unit + Integration
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProUITests                  # UI tests only
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/UnitTests          # Unit tests only
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/IntegrationTests   # Integration tests only
```

## Deployment Commands

```bash
bundle exec fastlane beta               # TestFlight (auto-increments build)
bundle exec fastlane release            # App Store
bundle exec fastlane bump_version              # Patch: 1.0.0 -> 1.0.1
bundle exec fastlane bump_version type:minor   # Minor: 1.0.0 -> 1.1.0
bundle exec fastlane bump_version type:major   # Major: 1.0.0 -> 2.0.0
```

Push to `main` branch triggers automatic TestFlight upload via GitHub Actions.

## Architecture

**MVVM with Clean Layers:**
- **Presentation**: SwiftUI Views + `@Observable` ViewModels (feature-organized)
- **Service**: Business logic (OCR, Reports, Backup, AppLock)
- **Model**: SwiftData `@Model` entities + value types

**Navigation**: 4-tab structure (Inventory, Capture, Reports, Settings)

### Directory Structure

```
Nestory-Pro/
├── Models/              # SwiftData models (Item, Category, Room, Receipt, ItemPhoto)
├── Services/            # Business logic services
├── Views/
│   ├── MainTabView.swift
│   ├── Inventory/       # Main inventory tab, item detail, add item
│   ├── Capture/         # Photo/receipt/barcode capture
│   ├── Reports/         # PDF generation & export
│   ├── Settings/        # Config, Pro purchase, backup
│   └── SharedUI/        # Reusable components
├── PreviewContent/      # Preview fixtures (PreviewContainer, PreviewFixtures)
Nestory-ProTests/
├── UnitTests/Models/    # Model unit tests
├── IntegrationTests/    # SwiftData persistence tests
├── PerformanceTests/    # Benchmarks
├── TestFixtures.swift   # Test data factories
Nestory-ProUITests/
├── Flows/               # User workflow tests
└── TestUtilities/       # AccessibilityIdentifiers
```

## Core Data Models

All models use SwiftData `@Model` with relationships:

- **Item**: Inventory item with photos, receipts, category, room. Cascade deletes photos, nullifies receipts.
- **Category**: Predefined + custom categories (seeded on first launch)
- **Room**: Physical locations (seeded on first launch)
- **Receipt**: OCR-extracted data, optional link to Item
- **ItemPhoto**: Photo metadata with file identifiers

### Documentation Status Logic

An item is "documented" when it has: photo + value + category + room (0.25 points each, totaling `documentationScore`).

## Key Technical Details

- **Swift 6 strict concurrency** - Use `@MainActor` for UI code, `async/await` for services
- **SwiftData + CloudKit** - `ModelConfiguration.cloudKitDatabase(.automatic)` for sync
- **Photo storage**: File-based with identifiers in database (not Data blobs)
- **iCloud container**: `iCloud.com.drunkonjava.nestory`
- **IAP product ID**: `com.drunkonjava.nestory.pro`

### Apple Frameworks

SwiftUI, SwiftData, Vision/VisionKit (OCR), Swift Charts, StoreKit 2, TipKit, LocalAuthentication

## Testing Strategy

- **Unit tests** (50-70%): Model computed properties, services, validation logic. < 0.1s per test.
- **Integration tests** (20-30%): SwiftData CRUD, relationship cascades. < 1s per test.
- **UI tests** (10-20%): Critical workflows with accessibility identifiers.
- **Performance tests**: Benchmark `documentationScore` with 1000+ items.

### Test Naming Convention

`test<What>_<Condition>_<ExpectedResult>()` - e.g., `testDocumentationScore_AllFieldsFilled_Returns1()`

### Preview System

Use `PreviewContainer` for all previews (never production data):
```swift
#Preview { MyView().modelContainer(PreviewContainer.withSampleData()) }
```

Available: `.empty()`, `.withBasicData()`, `.withSampleData()`, `.withManyItems(count:)`, `.emptyInventory()`

## Code Style

- **ViewModels**: Use `@Observable` macro (not `@StateObject`)
- **Views**: Keep small and composable, extract to `SharedUI/` when reusable
- **Services**: Use `actor` for thread-safe services with state
- **Tests**: Use `TestFixtures` for predictable test data, `@MainActor` for SwiftData operations

## CI/CD

GitHub Actions workflow (`.github/workflows/beta.yml`) requires secrets:
- `FASTLANE_APPLE_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT` (base64 .p8)

## Monetization

- **Free**: Up to 100 items, basic PDF exports, loss list up to 20 items
- **Pro** ($19.99-$24.99 one-time): Unlimited items, PDF with photos, CSV/JSON export

## Additional Documentation

- [PRODUCT-SPEC.md](PRODUCT-SPEC.md) - Complete product specs and UI layouts
- [TestingStrategy.md](TestingStrategy.md) - Comprehensive testing guide
- [WARP.md](WARP.md) - Extended development guide
- [PreviewExamples.md](PreviewExamples.md) - Preview and fixtures documentation

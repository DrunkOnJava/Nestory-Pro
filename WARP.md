# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Nestory Pro** is a native iOS app (iOS 17+) for home inventory management designed for insurance documentation. Built with SwiftUI, SwiftData, and modern Apple frameworks to provide fast item capture, receipt OCR, clear documentation status, and insurance-ready PDF exports.

**Key Value Proposition:** Make it stupidly easy to be claim-ready before something bad happens—prove what you owned, what it was worth, and where it was.

## Build & Development Commands

### Building and Running
```bash
# Open the project in Xcode
open Nestory-Pro.xcodeproj

# Build from command line (Debug)
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -configuration Debug

# Build for simulator (specific device - always use iPhone 17 Pro Max)
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

### Testing
```bash
# Run all tests via fastlane (recommended)
bundle exec fastlane test

# Run tests directly with xcodebuild
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

# Run specific test target
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -only-testing:Nestory-ProTests

# Run UI tests
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -only-testing:Nestory-ProUITests
```

### Deployment
```bash
# Deploy to TestFlight (increments build number automatically)
bundle exec fastlane beta

# Deploy to App Store (increments build number automatically)
bundle exec fastlane release

# Bump version numbers
bundle exec fastlane bump_version              # Patch: 1.0.0 → 1.0.1
bundle exec fastlane bump_version type:minor   # Minor: 1.0.0 → 1.1.0
bundle exec fastlane bump_version type:major   # Major: 1.0.0 → 2.0.0
```

**Note:** Pushing to `main` branch triggers automatic TestFlight upload via GitHub Actions.

## Architecture

### Design Pattern
**MVVM with Clean Layer Separation**

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  SwiftUI Views + @Observable VMs    │
│  (Feature-oriented organization)    │
└──────────────┴───────────────────────┘
               │
┌──────────────┴───────────────────────┐
│          Service Layer              │
│  OCR, Reports, Backup, AppLock      │
│  (Business logic & operations)      │
└──────────────┴───────────────────────┘
               │
┌──────────────┴───────────────────────┐
│         Repository Layer            │
│  (Future: Data access abstraction)  │
└──────────────┴───────────────────────┘
               │
┌──────────────┴───────────────────────┐
│           Model Layer               │
│  SwiftData @Model + Value Types     │
│  (Domain entities & data)           │
└─────────────────────────────────────────┘
```

### Dependency Injection Pattern

**AppEnvironment Container** - All services are initialized once and injected via `@Environment`:

```swift
// In views
@Environment(AppEnvironment.self) private var env

// Access services
let isProUnlocked = env.settings.isProUnlocked
await env.photoStorage.savePhoto(data)

// ViewModels receive AppEnvironment in initializer
class MyViewModel {
    init(settings: SettingsManager) { ... }
}
```

**Key Points:**
- **No .shared singletons** - All services managed by AppEnvironment
- **Actor-isolated services** - PhotoStorage, OCR, ReportGenerator, BackupService
- **MainActor services** - SettingsManager, IAPValidator, AppLockService
- **Injected at app root** - `MainTabView().environment(appEnv)` in Nestory_ProApp.swift
- **Testing support** - `AppEnvironment.mock()` for previews and tests

### Directory Structure
```
Nestory-Pro/
├── Nestory-Pro/                # Main app source
│   ├── Nestory_ProApp.swift    # App entry point, DI setup, SwiftData container
│   ├── AppEnvironment.swift    # Dependency injection container (all services)
│   ├── Models/                 # SwiftData models
│   │   ├── Item.swift          # Core inventory item model
│   │   ├── ItemPhoto.swift     # Photo metadata
│   │   ├── Receipt.swift       # Receipt OCR data
│   │   ├── Category.swift      # Item categorization
│   │   └── Room.swift          # Room/location data
│   ├── ViewModels/             # @Observable view models
│   │   ├── InventoryTabViewModel.swift
│   │   ├── CaptureTabViewModel.swift
│   │   ├── ReportsTabViewModel.swift
│   │   ├── AddItemViewModel.swift
│   │   └── ItemDetailViewModel.swift
│   ├── Services/               # Business logic services (actor-isolated)
│   │   ├── SettingsManager.swift       # User preferences
│   │   ├── IAPValidator.swift          # StoreKit 2 purchases
│   │   ├── PhotoStorageService.swift   # File-based photo storage
│   │   ├── OCRService.swift            # Vision framework OCR
│   │   ├── ReportGeneratorService.swift # PDF generation
│   │   ├── BackupService.swift         # Data export/import
│   │   ├── AppLockService.swift        # LocalAuthentication
│   │   ├── NetworkMonitor.swift        # Connectivity status
│   │   ├── HapticManager.swift         # Haptic feedback
│   │   ├── KeychainManager.swift       # Secure storage
│   │   ├── ImageCache.swift            # Photo caching
│   │   ├── PaginatedFetch.swift        # SwiftData pagination
│   │   └── PerformanceLogger.swift     # Performance tracking
│   ├── Protocols/              # Service protocols and interfaces
│   ├── Utilities/              # Helper utilities
│   │   ├── BackgroundTaskManager.swift
│   │   ├── ModelContextOptimization.swift
│   │   └── MemoryPressureObserver.swift
│   ├── Views/                  # Feature-organized SwiftUI views
│   │   ├── MainTabView.swift   # 4-tab navigation structure
│   │   ├── Inventory/          # Main inventory tab & item detail
│   │   ├── Capture/            # Photo/receipt/barcode capture
│   │   ├── Reports/            # PDF generation & export
│   │   ├── Settings/           # Configuration & Pro purchase
│   │   └── SharedUI/           # Reusable components (badges, cards, pills)
│   └── PreviewContent/         # Preview fixtures and containers
│       ├── PreviewFixtures.swift   # Sample data factory
│       ├── PreviewContainer.swift  # In-memory containers
│       └── PreviewHelpers.swift    # Preview utilities
├── Nestory-ProTests/           # Unit & integration tests
│   ├── UnitTests/
│   ├── IntegrationTests/
│   ├── PerformanceTests/
│   ├── TestUtilities/
│   └── TestFixtures.swift      # Test-specific fixtures
├── Nestory-ProUITests/         # UI automation tests
│   ├── Flows/
│   └── TestUtilities/
├── fastlane/                   # Deployment automation
│   ├── Fastfile                # Lanes: test, beta, release, bump_version
│   ├── Appfile                 # App ID, Apple ID, Team ID
│   ├── .env                    # Environment variables (NOT committed)
│   └── AuthKey_*.p8            # App Store Connect API key (NOT committed)
└── .github/workflows/
    └── beta.yml                # Auto TestFlight on push to main
```

## Core Data Models

### SwiftData Models
All models use `@Model` macro with relationships:

- **Item**: Core inventory item with purchase info, condition, photos, receipts
  - `@Relationship` to Category, Room, ItemPhoto (cascade), Receipt (nullify)
  - Computed properties: `isDocumented`, `documentationScore`, `missingDocumentation`
  
- **Category**: Predefined + custom categories with icons and colors
  - Default categories seeded on first launch
  
- **Room**: Physical locations in home
  - Default rooms seeded on first launch
  
- **Receipt**: OCR-extracted data from receipts
  - Links to Item (optional, nullify on delete)
  
- **ItemPhoto**: Photo metadata with file identifiers
  - Cascade deletes with parent Item

### Documentation Status Logic
An item is "documented" when it has the 4 core fields:
1. At least one photo
2. Purchase value
3. Category assigned
4. Room/location assigned

**Documentation Score (6-field weighted - Task 1.4.1):**
- Photo: 30%
- Value: 25%
- Room: 15%
- Category: 10%
- Receipt: 10%
- Serial Number: 10%

## Key Technical Decisions

### Data Persistence
- **SwiftData** as primary persistence layer (backed by SQLite)
- **CloudKit integration** via SwiftData's automatic sync (`ModelConfiguration.cloudKitDatabase`)
- Photo storage: File-based with identifiers in database (not `Data` blobs)
- iCloud container: `iCloud.com.drunkonjava.nestory`

### Backup & Import Format

**JSON Export Format (`nestory-backup-YYYYMMDD-HHMMSS.json`):**
```json
{
  "exportDate": "2025-11-29T12:00:00Z",
  "appVersion": "1.0.0",
  "items": [{ "id": "uuid", "name": "...", "categoryName": "...", "roomName": "...", ... }],
  "categories": [{ "id": "uuid", "name": "...", "iconName": "...", ... }],
  "rooms": [{ "id": "uuid", "name": "...", "iconName": "...", ... }],
  "receipts": [{ "id": "uuid", "vendor": "...", "total": 99.99, ... }]
}
```

**Reconciliation Rules (Import):**

| Scenario | Merge Strategy | Replace Strategy |
|----------|----------------|------------------|
| Category exists (by name) | Update properties, keep ID | Overwrite with backup |
| Room exists (by name) | Update properties, keep ID | Overwrite with backup |
| Item with same UUID | Skip (no duplicate) | Overwrite with backup |
| Receipt with same UUID | Skip (no duplicate) | Overwrite with backup |
| Missing relationships | Link by name match | Link by name match |
| Orphaned photo IDs | Warn but continue | Warn but continue |

**Import Strategies:**
- **Merge**: Adds backup data to existing inventory. Skips duplicates by UUID. Updates existing categories/rooms by name.
- **Replace**: Clears existing items, receipts, and custom categories/rooms first. Default system categories/rooms are preserved.

**Photo Handling (v1.0):**
- Photos are NOT included in JSON export (file size concerns)
- `photoIdentifiers` array references files in `Documents/Photos/`
- Import creates `ItemPhoto` records but photos may be missing
- Future v1.1: ZIP archive format with photos + manifest

### Concurrency
- **Swift 5 language mode** for v1.0 stability (Swift 6 migration in v1.1)
- **Swift 6.2.1 toolchain** for latest compiler optimizations
- Use `@MainActor` for UI-related code
- Use `async/await` for service layer operations
- SwiftData operations on main context by default

### Apple Frameworks Used
- **SwiftUI**: All UI (no UIKit mixing unless absolutely necessary)
- **SwiftData**: Persistence (local-only for v1.0, CloudKit in v1.1)
- **Vision/VisionKit**: OCR for receipt scanning
- **Swift Charts**: Analytics visualizations (pie/bar charts)
- **StoreKit 2**: In-app purchase (Nestory Pro unlock: `com.drunkonjava.nestory.pro`)
- **TipKit**: Contextual in-app tutorials
- **LocalAuthentication**: Face ID/Touch ID app lock

### Design Principles
- **Offline First**: Everything works without connectivity, sync is best-effort
- **Privacy First**: No third-party analytics or tracking, data never leaves Apple ecosystem
- **Native Feel**: 100% SwiftUI, leverage Apple frameworks
- **Type Safety**: Strict concurrency, comprehensive enum usage

## Navigation Structure

**4-Tab Bottom Navigation:**
1. **Inventory**: Main home, summary cards, analytics, item list/grid with search/filter
2. **Capture**: Photo/Receipt/Barcode segmented modes for quick data input
3. **Reports**: Generate full inventory PDFs and loss list PDFs
4. **Settings**: iCloud sync, Pro purchase, backup/export, app lock, theme

## Feature Implementation Guidelines

### Adding New Models
1. Create `@Model` class in `Models/` directory
2. Add to schema in `Nestory_ProApp.swift` (`sharedModelContainer`)
3. Define relationships with appropriate delete rules (`.cascade`, `.nullify`)
4. Add default data seeding if needed in `seedDefaultDataIfNeeded()`

### Adding New Services
1. Create service class in `Services/` directory
2. Use `actor` for thread-safe services with state
3. Add service to `AppEnvironment` container
4. Inject service via `@Environment(AppEnvironment.self)` in views
5. Pass specific services to ViewModels via their initializers
6. Mark async operations with `async throws` when appropriate

**Example:**
```swift
// 1. Create service
actor MyNewService {
    func doSomething() async throws { ... }
}

// 2. Add to AppEnvironment.swift
final class AppEnvironment {
    nonisolated let myNewService: MyNewService
    
    init(..., myNewService: MyNewService? = nil) {
        self.myNewService = myNewService ?? MyNewService()
        ...
    }
}

// 3. Use in views
@Environment(AppEnvironment.self) private var env
Task { await env.myNewService.doSomething() }
```

### Adding New Views
1. Organize by feature in `Views/` subdirectories
2. Keep views small and composable
3. Use `@Observable` macro for view models (not `@StateObject`)
4. Extract reusable components to `SharedUI/`

### Testing Strategy
- **Unit tests** for: Repository logic, OCR parsing, report generation, model helpers
- **UI tests** for: Main user flows, tab navigation, capture modes
- Run tests before merging to main (CI enforces this)

## Monetization

### Free Tier Limits
- Up to 100 items
- Basic PDF exports (no photos in inventory PDF)
- Loss list for up to 20 items

### Pro Tier (`com.drunkonjava.nestory.pro`)
- One-time IAP: $19.99–$24.99
- Unlimited items and loss lists
- Full PDF exports with photos
- Advanced export formats (CSV, JSON)

## CI/CD & GitHub Actions

- **Automatic TestFlight**: Push to `main` → GitHub Actions → Fastlane beta
- **Required Secrets** (set via `gh secret set`):
  - `FASTLANE_APPLE_ID`
  - `APP_STORE_CONNECT_KEY_ID`
  - `APP_STORE_CONNECT_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_CONTENT` (base64 encoded .p8 file)

## Configuration

### iCloud Setup
- Container ID: `iCloud.com.drunkonjava.nestory`
- Capability must be enabled in Xcode project settings
- Requires Apple Developer account with CloudKit access

### Signing
- Uses **Xcode automatic signing** (no Fastlane Match needed)
- Configure in Xcode: Project Settings → Signing & Capabilities

## Security & Privacy

- Face ID/Touch ID app lock support
- All data local-first with optional iCloud sync
- No third-party analytics or tracking SDKs
- Privacy policy required for App Store compliance

## Code Conventions

### Inline Documentation Comments

The codebase uses structured inline comments for critical architectural decisions:

```swift
// ============================================================================
// CLAUDE CODE AGENT: READ BEFORE MODIFYING
// ============================================================================
// Brief description of the file's purpose and key architectural notes
//
// ARCHITECTURE:
// - Key architectural decision 1
// - Key architectural decision 2
//
// WHEN ADDING NEW FEATURES:
// 1. Step-by-step guidance
// 2. Important considerations
//
// SEE: Related files | Documentation references
// ============================================================================
```

**When you see these comments:**
- Read them carefully before making changes
- They document critical architectural decisions
- Follow the guidance provided for adding new features
- Update them if you make significant architectural changes

**Common locations:**
- `Nestory_ProApp.swift` - App entry point and DI setup
- `AppEnvironment.swift` - Dependency injection container
- Key service files with architectural significance

## Common Pitfalls

1. **SwiftData Relationships**: Always use inverse relationships and specify delete rules explicitly
2. **CloudKit Sync Conflicts**: Handle merge conflicts gracefully, prefer last-write-wins for user convenience
3. **Photo Storage**: Don't store image Data directly in SwiftData—use file system with identifiers
4. **App Review**: Avoid wording like "accepted by all insurers"—keep copy in "helps you prepare" territory
5. **OCR Accuracy**: Vision framework works best with good lighting and flat receipts—provide manual entry fallback

## Future Roadmap (Not in v1)

- **v1.1**: Warranty dashboard, enhanced analytics, advanced search syntax
- **v1.2**: Incident mode for claims, claim pack generation
- **v2**: Household sharing, professional white-label exports, video walkthrough analysis, AI-assisted identification

## Testing & Previews

### Preview System

The project uses a comprehensive fixtures and preview system to avoid mixing real and fake data:

**Structure:**
```
Nestory-Pro/PreviewContent/
├── PreviewFixtures.swift      # Sample data factory
├── PreviewContainer.swift     # In-memory SwiftData containers
└── PreviewHelpers.swift       # Preview utilities

Nestory-ProTests/
└── TestFixtures.swift          # Test-specific fixtures
```

**Key Components:**
- `PreviewFixtures` - Realistic sample data for all models
- `PreviewContainer` - In-memory containers (never touch production data)
- `PreviewHelpers` - Utilities for device sizes, color schemes, dynamic type
- `TestFixtures` - Predictable test data with XCTest extensions

### Using Previews

```swift
// Basic preview with sample data
#Preview("Default") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
}

// Dark mode
#Preview("Dark Mode") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .preferredColorScheme(.dark)
}

// Different device sizes
#Preview("iPhone SE") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
}

// Empty state
#Preview("Empty") {
    MyView()
        .modelContainer(PreviewContainer.emptyInventory())
}

// Large text accessibility
#Preview("Large Text") {
    MyView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(\.dynamicTypeSize, .xxxLarge)
}
```

### Available Container Types

- `PreviewContainer.empty()` - No data
- `PreviewContainer.withBasicData()` - Categories and rooms only
- `PreviewContainer.withSampleData()` - Full sample dataset
- `PreviewContainer.withManyItems(count: 50)` - Stress testing
- `PreviewContainer.emptyInventory()` - Categories/rooms but no items

### Writing Unit Tests

- Use `AppEnvironment.mock(...)` in tests when you need a fully wired environment without touching real services:
  - Pass protocol-conforming mocks from `Nestory-ProTests/Mocks` for `SettingsProviding`, `PhotoStorageProtocol`, `OCRServiceProtocol`, and `BackupServiceProtocol`.
  - Example: `let env = AppEnvironment.mock(settings: MockSettingsManager(), photoStorage: MockPhotoStorageService(), ocrService: MockOCRService(), backupService: MockBackupService())`.

```swift
import XCTest
@testable import Nestory_Pro

final class ItemTests: XCTestCase {
    
    @MainActor
    func testDocumentationScore() throws {
        let container = TestContainer.empty()
        let context = container.mainContext
        
        let category = TestFixtures.testCategory()
        let room = TestFixtures.testRoom()
        context.insert(category)
        context.insert(room)
        
        let item = TestFixtures.testDocumentedItem(
            category: category,
            room: room
        )
        context.insert(item)
        
        // Add photo for full documentation
        let photo = TestFixtures.testItemPhoto()
        photo.item = item
        context.insert(photo)
        
        XCTAssertEqual(item.documentationScore, 1.0)
        XCTAssertTrue(item.isDocumented)
    }
}
```

### Best Practices

1. **Never use production container in previews** - Always use `PreviewContainer`
2. **Create multiple preview variations** - Test light/dark, different devices, dynamic type
3. **Test empty states** - Use `PreviewContainer.emptyInventory()`
4. **Name previews descriptively** - `#Preview("Dark Mode - Large Text")` not `#Preview("Test 1")`
5. **Wrap fixtures in `#if DEBUG`** - Exclude from release builds
6. **Use TestFixtures for unit tests** - Predictable, simple test data

See [PreviewExamples.md](PreviewExamples.md) for comprehensive documentation and examples.

## Test Suite Structure

### Test Organization

```
Nestory-ProTests/              # Unit & Integration Tests
├── UnitTests/
│   ├── Models/
│   │   └── ItemTests.swift
│   └── Services/
│       └── SettingsManagerTests.swift
├── IntegrationTests/
│   └── PersistenceIntegrationTests.swift
├── PerformanceTests/
│   └── DocumentationScorePerformanceTests.swift
├── TestUtilities/
│   ├── TestFixtures.swift
│   ├── MockServices.swift
│   └── TestHelpers.swift
└── Nestory_ProTests.swift

Nestory-ProUITests/            # UI Tests
├── Flows/
│   └── TabNavigationUITests.swift
└── TestUtilities/
    └── AccessibilityIdentifiers.swift
```

### Test Types & Coverage Goals

- **Unit Tests** (50-70%) - Isolated component testing, < 0.1s per test
- **Integration Tests** (20-30%) - Component interaction testing, < 1s per test
- **UI Tests** (10-20%) - Critical user workflows, 1-10s per test
- **Performance Tests** - Benchmark critical operations, track regressions

### Running Tests

```bash
# All tests
bundle exec fastlane test

# Unit tests only
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:Nestory-ProTests/UnitTests

# Integration tests
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:Nestory-ProTests/IntegrationTests

# Performance tests
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:Nestory-ProTests/PerformanceTests

# UI tests
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:Nestory-ProUITests

# Specific test class
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:Nestory-ProTests/ItemTests
```

### Example Tests

**Unit Test** - Fast, isolated, mocked dependencies:
```swift
@MainActor
func testDocumentationScore_AllFieldsFilled_Returns1() throws {
    let container = TestContainer.empty()
    let context = container.mainContext
    
    let item = TestFixtures.testDocumentedItem(
        category: TestFixtures.testCategory(),
        room: TestFixtures.testRoom()
    )
    
    XCTAssertEqual(item.documentationScore, 1.0)
}
```

**Integration Test** - Component interactions:
```swift
@MainActor
func testItemDelete_WithPhotos_CascadesDelete() throws {
    let container = TestContainer.empty()
    let context = container.mainContext
    
    let item = TestFixtures.testItem()
    context.insert(item)
    
    let photo = TestFixtures.testItemPhoto()
    photo.item = item
    context.insert(photo)
    try context.save()
    
    context.delete(item)
    try context.save()
    
    let photos = try context.fetch(FetchDescriptor<ItemPhoto>())
    XCTAssertEqual(photos.count, 0)
}
```

**UI Test** - User workflows:
```swift
func testTabNavigation_SwitchBetweenTabs() throws {
    app.buttons["Capture"].tap()
    XCTAssertTrue(app.staticTexts["Capture"].exists)
    
    app.buttons["Reports"].tap()
    XCTAssertTrue(app.staticTexts["Reports"].exists)
}
```

**Performance Test** - Benchmarking:
```swift
@MainActor
func testDocumentationScore_1000Items_Performance() throws {
    let container = TestContainer.withManyItems(count: 1000)
    let items = try container.mainContext.fetch(FetchDescriptor<Item>())
    
    measure {
        let scores = items.map { $0.documentationScore }
        XCTAssertEqual(scores.count, 1000)
    }
}
```

### Test Naming Convention

Pattern: `test<What>_<Condition>_<ExpectedResult>()`

✅ Good:
- `testDocumentationScore_AllFieldsFilled_Returns1()`
- `testItemDelete_WithPhotos_CascadesDelete()`
- `testFetchItems_WithPredicate_ReturnsMatchingItems()`

❌ Bad:
- `testItem()`
- `test1()`
- `testDocumentation()`

### Accessibility Identifiers

All UI elements for testing use centralized identifiers:

```swift
// Adding to views
Button("Add Item") { }
    .accessibilityIdentifier("inventory.addButton")

// Using in tests
app.buttons["inventory.addButton"].tap()
```

See `AccessibilityIdentifiers.swift` for all identifiers.

### Test Best Practices

1. **Use in-memory databases** - Never test against production data
2. **Keep tests fast** - Unit tests < 0.1s, Integration < 1s
3. **Test one thing** - Single assertion per test when possible
4. **Arrange-Act-Assert** - Clear test structure
5. **Descriptive names** - Explain what, when, and expected result
6. **No shared state** - Each test is independent
7. **Use TestFixtures** - Consistent, predictable test data

See [TestingStrategy.md](TestingStrategy.md) for complete testing documentation.

## References

- [Product Specification](PRODUCT-SPEC.md) - Detailed product and technical specs
- [Fastlane README](FASTLANE_README.md) - Deployment automation details
- [Preview Examples](PreviewExamples.md) - Fixtures and preview strategy guide
- [Testing Strategy](TestingStrategy.md) - Comprehensive testing documentation

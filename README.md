# Nestory Pro

<div align="center">

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?logo=swift)
![License](https://img.shields.io/badge/license-Proprietary-red)
![Status](https://img.shields.io/badge/status-Active%20Development-green)

**Home Inventory for Insurance** — Make it stupidly easy to be claim-ready before something bad happens.

[Features](#features) • [Installation](#getting-started) • [Documentation](#documentation) • [Roadmap](#roadmap)

</div>

---

## 📖 Table of Contents

- [About](#about)
- [Features](#features)
- [Technical Stack](#technical-stack)
- [Getting Started](#getting-started)
- [Development](#development)
- [Architecture](#architecture)
- [Monetization](#monetization)
- [Roadmap](#roadmap)
- [Documentation](#documentation)
- [Privacy & Security](#privacy--security)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## About

Nestory Pro is a native iOS app (iOS 17+) designed to help people create comprehensive home inventories for insurance purposes. Built with SwiftUI and modern Apple frameworks, it provides fast item capture, receipt OCR, clear documentation status, and insurance-ready PDF exports.

**Core Value Proposition:** Prove what you owned, what it was worth, and where it was — with the least possible work.

## Features

### 🎯 Core Features (v1)

- **📸 Fast Item Capture** — Photos with minimal required fields
- **🧾 Receipt OCR** — Automatic extraction of date, vendor, and amount using Vision framework
- **✅ Documentation Status** — Clear badges and scoring system to track completeness
- **📄 Insurance-Ready PDFs** — Full inventory and loss list exports
- **☁️ iCloud Sync** — Local-first storage with optional cloud backup via CloudKit

## Technical Stack

- **Language:** Swift 5 (Swift 6 migration planned for v1.1)
- **Toolchain:** Xcode 26+ / Swift 6.2.1
- **UI:** SwiftUI
- **Persistence:** SwiftData (local-only for v1.0, CloudKit sync in v1.1)
- **Frameworks:** Vision/VisionKit, Swift Charts, StoreKit 2, TipKit
- **Architecture:** MVVM with clean layer separation
- **IDE:** Xcode latest + Swift Package Manager

## Project Structure

```
Nestory-Pro/
├── AppCore/              # App entry, environment, DI
├── Models/               # SwiftData models & shared types
├── Services/             # OCR, Reports, Backup, etc.
├── Views/                # SwiftUI views
│   ├── Inventory/        # Main inventory tab
│   ├── Capture/          # Photo/receipt/barcode capture
│   ├── Reports/          # PDF generation & export
│   └── Settings/         # Configuration & Pro purchase
├── Repositories/         # Data access layer
└── SharedUI/             # Reusable components
```

## Getting Started

### Prerequisites

- macOS Sonoma or later
- Xcode 15.0+
- iOS 17.0+ deployment target
- Apple Developer account (for iCloud/CloudKit)

### Setup

1. Clone the repository
2. Open `Nestory-Pro.xcodeproj` in Xcode
3. Configure signing & capabilities
4. Enable iCloud (CloudKit) capability
5. Build and run on simulator or device

### Configuration

- iCloud container: `iCloud.com.drunkonjava.nestory`
- IAP product ID: `com.drunkonjava.nestory.pro`

## Development

### Building and Running

```bash
# Open the project in Xcode
open Nestory-Pro.xcodeproj

# Build from command line (Debug)
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -configuration Debug

# Build for simulator (always use iPhone 17 Pro Max)
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

### Testing

```bash
# Run all tests via fastlane (recommended)
bundle exec fastlane test

# Run tests directly with xcodebuild
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

# Run specific test target
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests

# Run UI tests
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProUITests
```

### Deployment

```bash
# Deploy to TestFlight (increments build number automatically)
bundle exec fastlane beta

# Deploy to App Store
bundle exec fastlane release

# Bump version numbers
bundle exec fastlane bump_version              # Patch: 1.0.0 → 1.0.1
bundle exec fastlane bump_version type:minor   # Minor: 1.0.0 → 1.1.0
bundle exec fastlane bump_version type:major   # Major: 1.0.0 → 2.0.0
```

> **Note:** Pushing to `main` branch automatically triggers TestFlight upload via GitHub Actions.

### CI/CD & Build Optimization

The project uses **Xcode Cloud** for continuous integration with comprehensive test optimization:

#### Xcode Cloud Workflows

Three optimized workflows targeting 7.1 compute hours/month (71% under free tier):

| Workflow | Test Plan | Time | Trigger | Monthly Usage |
|----------|-----------|------|---------|---------------|
| **PR Validation** | FastTests | 5 min | Pull requests | 1.7 hrs (20 PRs) |
| **Main Branch** | FullTests | 10 min | Push to main | 5.0 hrs (30 commits) |
| **Pre-Release** | FullTests | 12 min | Version tags | 0.4 hrs (2 releases) |

**Device Target:** iPhone 17 Pro Max only (all workflows)

#### Test Infrastructure

- **Test Plans:** FastTests, FullTests, CriticalPath
- **Parallel Execution:** Enabled for 50-70% faster test runs
- **Test Tagging:** `.fast`, `.medium`, `.slow`, `.unit`, `.integration`, `.critical`
- **Shared Fixtures:** 92% reduction in test setup overhead

#### Build Optimizations

- **Local Builds:** 50% faster with compiler optimizations
- **Incremental Builds:** 67% faster (15s → 5s)
- **SPM Caching:** Configured for faster dependency resolution

See [docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md](docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md) and [docs/IOS_BUILD_OPTIMIZATIONS.md](docs/IOS_BUILD_OPTIMIZATIONS.md) for complete details.

#### GitHub Actions (Backup)

- **Workflow:** `.github/workflows/beta.yml`
- **Trigger:** Push to `main` branch
- **Action:** Automatically builds and uploads to TestFlight

Required Secrets:
- `FASTLANE_APPLE_ID`, `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_CONTENT`

## Architecture

### Design Pattern

**MVVM with Clean Layer Separation:**

- **Model Layer:** SwiftData `@Model` types for persistence
- **Repository Layer:** Data access abstraction (future enhancement)
- **Service Layer:** Business logic (OCR, Reports, Backup, AppLock)
- **Presentation Layer:** SwiftUI Views with `@Observable` ViewModels

### Key Architectural Decisions

1. **SwiftData (Local-First):** Primary persistence, CloudKit sync planned for v1.1
2. **Swift 5 Language Mode:** Using Swift 6 toolchain with Swift 5 mode for stability
3. **Offline-First:** All features work without network connectivity
4. **File-Based Photo Storage:** Images stored as files, not Data blobs
5. **Feature-Oriented Organization:** Code organized by feature, not layer

### Core Models

- **Item:** Inventory items with photos, receipts, metadata
- **Category:** Predefined and custom item categories
- **Room:** Physical locations for item organization
- **Receipt:** OCR-extracted receipt data
- **ItemPhoto:** Photo metadata with file references

## Features Breakdown

### Inventory Management
- Items with name, brand, model, serial number
- Categories and room assignment
- Purchase price & date tracking
- Condition tracking
- Multiple photos per item
- Grid/list views with filtering and search

### Capture
- **Photo Mode** - Quick item photo capture with minimal form
- **Receipt Mode** - OCR-powered receipt scanning
- **Barcode Mode** - Product lookup via barcode scanning

### Reports
- **Full Inventory PDF** - Complete listing with optional photos
- **Loss List PDF** - Custom selection for specific claims
- Value summaries by room and category

### Analytics
- Total items and estimated value
- Documentation score (% complete)
- Value by category (pie chart)
- Items by room (bar chart)

## Monetization

### Free Tier
- Up to 100 items
- Unlimited photos per item
- Receipt OCR included
- Basic PDF exports
- iCloud sync

### Nestory Pro (One-Time Purchase)
- Unlimited items
- Full PDF exports with photos
- Advanced export formats (CSV, JSON)
- Extended analytics
- Price: $19.99–$24.99

## Development Principles

- **Offline First** - Everything works without connectivity
- **Privacy First** - No third-party analytics or tracking
- **Native Feel** - 100% SwiftUI, leveraging Apple frameworks
- **Clean Architecture** - MVVM with repository pattern
- **Type Safety** - Swift 5 with concurrency patterns (Swift 6 migration in v1.1)

## Roadmap

> **Complete roadmap:** See [TODO.md](TODO.md) for detailed task breakdown and dependencies.

| Version | Theme | Target | Tier | Status |
|---------|-------|--------|------|--------|
| **v1.0** | Launch | ✅ Nov 2025 | Free/Pro | ✅ Shipped |
| **v1.1** | Stability & Swift 6 | Q1 2026 | Pro | 🔄 Planning |
| **v1.2** | UX & Onboarding | Q1 2026 | Pro | 📋 Planned |
| **v1.3** | Pro Features v2 | Q2 2026 | Pro | 📋 Planned |
| **v1.4** | Automation | Q2 2026 | Pro | 📋 Planned |
| **v1.5** | Platform Expansion | Q3 2026 | Pro | 📋 Planned |
| **v2.0** | Data Intelligence | Q4 2026 | Pro+ | 💡 Future |
| **v2.1** | Professional | Q1 2027 | Business | 💡 Future |
| **v3.0** | Enterprise | Q2 2027 | Enterprise | 💡 Future |

### Key Upcoming Features

**v1.1 - Stability** (Q1 2026)
- Swift 6 strict concurrency migration
- Snapshot testing suite
- CloudKit sync enablement

**v1.2 - UX** (Q1 2026)
- First-time onboarding flow
- Tags system
- Reminders

**v2.0+ - Advanced** (2026-2027)
- Depreciation tracking
- Claims workflow
- Core ML categorization
- REST API & webhooks

## Documentation

Comprehensive project documentation:

### Core Documentation
- **[CLAUDE.md](CLAUDE.md)** — Agent behavior and collaboration rules (AI agents read this first)
- **[TODO.md](TODO.md)** — Task management and version roadmap
- **[TODO-COMPLETE.md](TODO-COMPLETE.md)** — Completed v1.0 tasks archive (105 tasks)
- **[PRODUCT-SPEC.md](PRODUCT-SPEC.md)** — Complete product and technical specifications
- **[WARP.md](WARP.md)** — Extended development guide

### AI Agent Instructions
- **[AGENTS.md](AGENTS.md)** — Universal AI agent instructions
- **[GEMINI.md](GEMINI.md)** — Gemini Code Assist specific guidance
- **[COPILOT.md](COPILOT.md)** — GitHub Copilot specific guidance

### CI/CD & Optimization
- **[docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md](docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md)** — 19 advanced techniques for Xcode Cloud efficiency
- **[docs/XCODE_CLOUD_TEST_OPTIMIZATION.md](docs/XCODE_CLOUD_TEST_OPTIMIZATION.md)** — Test optimization strategy (48.8h → 7.1h/month)
- **[docs/IOS_BUILD_OPTIMIZATIONS.md](docs/IOS_BUILD_OPTIMIZATIONS.md)** — iOS-specific build optimizations
- **[TestPlans-README.md](TestPlans-README.md)** — Test plan configuration guide
- **[fastlane/README.md](fastlane/README.md)** — Deployment automation setup and usage

### Additional Resources

- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [Fastlane Documentation](https://docs.fastlane.tools/)

## Privacy & Security

- All data stored locally with optional iCloud sync
- Face ID/Touch ID app lock support
- No third-party analytics or tracking
- User data never leaves Apple's ecosystem

## Contributing

This is currently a personal project. While external contributions are not actively solicited at this time, feedback and suggestions are welcome through GitHub Issues.

### Development Guidelines

If contributing:

1. Follow Swift concurrency best practices (actors, async/await)
2. Maintain SwiftUI-first approach (no UIKit unless necessary)
3. Write unit tests for business logic
4. Keep views small and composable
5. Use `@Observable` for view models (not `@StateObject`)
6. Document public APIs and complex logic

## License

Copyright © 2024-2025 DrunkOnJava. All rights reserved.

This is proprietary software. Unauthorized copying, modification, distribution, or use of this software is strictly prohibited.

## Support

For questions, bug reports, or feature requests:

- **Issues:** [GitHub Issues](https://github.com/DrunkOnJava/Nestory-Pro/issues)
- **Email:** Contact via GitHub profile
- **Documentation:** See [WARP.md](WARP.md) for development guidance

---

<div align="center">

Built with ❤️ by [@DrunkOnJava](https://github.com/DrunkOnJava)

**[⬆ back to top](#nestory-pro)**

</div>

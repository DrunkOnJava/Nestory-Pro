# Nestory Pro

> **Home Inventory for Insurance** - Make it stupidly easy to be claim-ready before something bad happens.

Nestory helps you prove what you owned, what it was worth, and where it was — with the least possible work.

## Overview

Nestory is a native iOS app (iOS 17+) designed to help people create comprehensive home inventories for insurance purposes. Built with SwiftUI and modern Apple frameworks, it provides fast item capture, receipt OCR, clear documentation status, and insurance-ready PDF exports.

### Core Features (v1)

- **📸 Fast Item Capture** - Photos with minimal required fields
- **🧾 Receipt OCR** - Automatic extraction of date, vendor, and amount
- **✅ Documentation Status** - Clear badges and scoring system
- **📄 Insurance-Ready PDFs** - Full inventory and loss list exports
- **☁️ iCloud Sync** - Local-first storage with optional cloud backup

## Technical Stack

- **Language:** Swift 6 (strict concurrency)
- **UI:** SwiftUI
- **Persistence:** SwiftData + CloudKit
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
- **Type Safety** - Swift 6 strict concurrency

## Roadmap

### v1.1 - Quality & Depth
- Warranty dashboard
- Enhanced analytics
- Advanced search syntax

### v1.2 - Claims Workflows
- Incident mode for specific events
- Claim pack generation
- Incident notes and documentation

### v2 - Professional & AI
- Household sharing
- White-label exports for professionals
- Video walkthrough analysis
- AI-assisted item identification

## Documentation

- [Product Specification](PRODUCT-SPEC.md) - Detailed product and technical specs
- Architecture documentation - Coming soon
- API documentation - Coming soon

## Privacy & Security

- All data stored locally with optional iCloud sync
- Face ID/Touch ID app lock support
- No third-party analytics or tracking
- User data never leaves Apple's ecosystem

## Contributing

This is currently a personal project. Contributions guidelines will be added in the future.

## License

Copyright © 2024 DrunkOnJava. All rights reserved.

## Support

For questions or support, please contact: [Your support email]

---

Built with ❤️ by [@DrunkOnJava](https://github.com/DrunkOnJava)

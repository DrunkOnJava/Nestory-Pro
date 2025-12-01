# AGENTS.md

Universal AI agent instructions for Nestory Pro. All AI coding assistants should read this file.

## Quick Start for AI Agents

> **Platform-Specific Files:** For detailed platform instructions, see:
> - [CLAUDE.md](CLAUDE.md) - Claude Code (Anthropic)
> - [GEMINI.md](GEMINI.md) - Gemini CLI (Google)
> - [COPILOT.md](COPILOT.md) - GitHub Copilot
> - [WARP.md](WARP.md) - Warp Terminal AI

## Project Identity

**Nestory Pro** — Home Inventory for Insurance
**Platform:** iOS 17+
**Tech Stack:** Swift 5 → Swift 6 (v1.1), SwiftUI, SwiftData
**Architecture:** MVVM with clean layer separation
**Status:** v1.0 shipped, v1.1 in planning

## Essential Commands

```bash
# Development
open Nestory-Pro.xcodeproj                    # Open in Xcode
bundle exec fastlane test                     # Run all tests
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

# Deployment
bundle exec fastlane beta                     # TestFlight
bundle exec fastlane bump_version             # Version management
```

**Simulator:** Always use **iPhone 17 Pro Max**

## Test Infrastructure

### Test Plans

- **FastTests** (5 min) - PR validation, skips performance/snapshots
- **FullTests** (15 min) - Main branch, all tests except snapshots
- **CriticalPath** (2 min) - Smoke tests only

**Parallel Execution:** Enabled in all test plans for 50-70% speedup

### Xcode Cloud Optimization

Optimized workflows targeting **7.1 hours/month** (71% under 25-hour free tier):
- PR: 5 min × 20/month = 1.7 hrs
- Main: 10 min × 30/month = 5.0 hrs
- Release: 12 min × 2/month = 0.4 hrs

**Documentation:**
- [XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md](docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md)
- [IOS_BUILD_OPTIMIZATIONS.md](docs/IOS_BUILD_OPTIMIZATIONS.md)

## Critical Governance Rules

> **⚠️ IMPORTANT:** All agents MUST follow these rules before making changes.

### 🚫 Strategic Changes Require Approval

**NEVER modify without asking first:**
1. **Pricing & Tiers** - No changes to Free/Pro/Pro+/Business/Enterprise pricing
2. **Release Roadmap** - No moving tasks between versions (v1.1–v3.0)
3. **Product Behavior** - No changes to PRODUCT-SPEC.md without alignment
4. **Governance Docs** - No editing CLAUDE.md, TODO.md, WARP.md, GEMINI.md, COPILOT.md, AGENTS.md rules
5. **Compliance/Security** - No changes to GDPR, data retention, audit logs

**How to request approval:**
- Claude Code: Use `AskUserQuestion` tool
- Gemini CLI: Explain proposed change and wait for confirmation
- Copilot: Add comment explaining change, wait for developer approval
- Warp: Use `/plan` to propose changes before implementing

### ✅ Autonomous Operation Allowed

**You CAN make these changes without asking:**
- Bug fixes where correct behavior is clear from tests/spec
- Refactoring internals (no public behavior change)
- Adding/expanding tests (no semantic changes)
- Small UX polish within screens (matches spec, no pricing changes)
- Clarifying comments, better naming
- Fixing typos in documentation

## Task Management

**Primary Source:** [TODO.md](TODO.md)

**Rules:**
1. Read TODO.md before starting work
2. Check "Active Checkouts" - don't take checked-out tasks
3. Respect `Blocked-by:` dependencies
4. One task per agent at a time
5. Mark task `[~]` when starting, `[x]` when complete

**Current Status:**
- v1.0: ✅ Complete (105 tasks archived in TODO-COMPLETE.md)
- v1.1: 9 tasks (Stability & Swift 6)
- v1.2–v3.0: 43 tasks (see TODO.md)

## Architecture Quick Reference

### MVVM Pattern

```swift
// View (SwiftUI)
struct InventoryTab: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: InventoryTabViewModel

    var body: some View { /* UI */ }
}

// ViewModel (@Observable)
@Observable
class InventoryTabViewModel {
    private let settings: SettingsManager

    init(settings: SettingsManager) {
        self.settings = settings
    }
}

// Service (actor-isolated)
actor PhotoStorageService: PhotoStorageProtocol {
    func savePhoto(_ image: UIImage, for itemId: UUID) async throws -> String {
        // Business logic
    }
}

// Model (SwiftData)
@Model
final class Item {
    var name: String
    var purchasePrice: Decimal?
    @Relationship(deleteRule: .cascade) var photos: [ItemPhoto]
}
```

### Dependency Injection

**All services** managed by `AppEnvironment`:

```swift
// In app root (Nestory_ProApp.swift)
let appEnv = AppEnvironment(
    settings: SettingsManager(),
    photoStorage: PhotoStorageService(),
    ocrService: OCRService(),
    // ... other services
)

// Inject at root
MainTabView()
    .environment(appEnv)

// Access in views
@Environment(AppEnvironment.self) private var env
let isPro = env.settings.isProUnlocked
```

**No `.shared` singletons** - Everything via AppEnvironment.

## Code Style Guidelines

### Swift Concurrency

```swift
// ✅ Correct
@MainActor
class InventoryTabViewModel: ObservableObject { }

actor PhotoStorageService {
    func savePhoto(_ image: UIImage) async throws -> String { }
}

// ❌ Avoid
class PhotoService {
    static let shared = PhotoService()  // No singletons
}
```

### SwiftUI Views

```swift
// ✅ Keep views small
struct ItemRow: View {
    let item: Item
    var body: some View {
        HStack { /* simple layout */ }
    }
}

// ❌ Avoid massive views
struct InventoryTab: View {
    var body: some View {
        // 500 lines of nested VStack/HStack...
    }
}
```

### Testing

```swift
// ✅ Use TestFixtures
let item = TestFixtures.testDocumentedItem()

// ✅ Use in-memory containers
let container = TestContainer.withSampleData()

// ❌ Don't use production data
let container = sharedModelContainer  // NO!
```

## Documentation Status

6-field weighted scoring system:
- **Photo**: 30%
- **Value**: 25%
- **Room**: 15%
- **Category**: 10%
- **Receipt**: 10%
- **Serial**: 10%

An item with all fields complete = 100% documented.

## Additional Resources

- [PRODUCT-SPEC.md](PRODUCT-SPEC.md) - Complete product requirements
- [TODO.md](TODO.md) - Version roadmap and tasks
- [TODO-COMPLETE.md](TODO-COMPLETE.md) - v1.0 completed tasks archive
- [TestingStrategy.md](TestingStrategy.md) - Comprehensive testing guide
- [PreviewExamples.md](PreviewExamples.md) - SwiftUI preview patterns
- [PRIVACY.md](PRIVACY.md) - Privacy policy (App Store)

---

## Platform-Specific Features Summary

| Feature | Claude Code | Gemini CLI | Copilot | Warp |
|---------|-------------|------------|---------|------|
| **Checkpoints** | ✅ /rewind | ✅ Experimental | ❌ | ❌ |
| **Skills/Extensions** | ✅ .claude/skills/ | ✅ Extensions | ❌ | ❌ |
| **Custom Commands** | ✅ .claude/commands/ | ✅ ~/.gemini/commands/*.toml | ❌ | ❌ |
| **Plan Mode** | ✅ /plan | ❌ | ❌ | ✅ /plan |
| **File Referencing** | @file.txt | @file.txt | #file:file.txt | Standard |
| **Shell Execution** | Bash tool | ! command | @terminal | * command |
| **Multi-Agent** | ❌ | ❌ | ❌ | ✅ |
| **Interactive Terminal** | ❌ | ❌ | ❌ | ✅ Full REPL |
| **GitHub Integration** | Via gh CLI | Via tools | ✅ Native @github | Via tools |
| **Code Review** | Manual | Manual | Manual | ✅ /review |

## Which Agent for Which Task?

### Use Claude Code for:
- Complex multi-file refactoring
- Creating new features from scratch
- Debugging with checkpoints/rollback
- Working with project-specific Skills

### Use Gemini CLI for:
- Quick codebase exploration (@dir/ queries)
- Shell integration workflows (! commands)
- Custom command automation (.toml files)
- Headless scripting (gemini -p)

### Use GitHub Copilot for:
- Inline code completions while coding in Xcode/VS Code
- Quick documentation generation (/doc)
- Test scaffolding (/tests)
- GitHub-integrated workflows

### Use Warp for:
- Multi-agent parallel work
- Interactive debugging (lldb, REPL)
- Plan-based development (/plan)
- Code review workflows (/review)

---

**Last Updated:** November 29, 2025
**Version:** v1.0 shipped, v1.1 planning (Swift 6 migration)

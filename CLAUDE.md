# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Nestory Pro** is a native iOS 17+ app for home inventory management designed for insurance documentation. Built with Swift 6 with strict concurrency, SwiftUI, and SwiftData. Core features: fast item capture, receipt OCR via Vision framework, documentation status tracking, and insurance-ready PDF exports.

### Swift Version
- **Language Mode:** Swift 6.0 with strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`)
- **Toolchain:** Xcode 16+ with Swift 6.2.1
- **Default Actor Isolation:** `@MainActor` (set in `Common.xcconfig`)
- **Note:** UI tests use `@MainActor` annotations on test classes to properly access XCUIElement properties.

## Build & Test Commands

```bash
# Open in Xcode
open Nestory-Pro.xcodeproj

# Build (Debug)
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -configuration Debug

# Build for simulator (always use iPhone 17 Pro Max)
xcodebuild -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

# Run all tests (recommended)
bundle exec fastlane test

# Run tests with xcodebuild
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

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

## Test Infrastructure & CI/CD

### Test Plans

Three test plans optimized for Xcode Cloud with parallel execution enabled:

| Test Plan | Purpose | Time | Skipped Tests |
|-----------|---------|------|---------------|
| **FastTests** | PR validation | ~5 min | Performance, Snapshots, DataModelHarness, ReportGenerator |
| **FullTests** | Main branch | ~15 min | Snapshots only |
| **CriticalPath** | Smoke tests | ~2 min | All except core unit tests |

**Usage:**
```bash
# Run specific test plan
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -testPlan FastTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

### Test Tagging System

Tests are tagged for selective execution:

```swift
// TestInfrastructure/TestTags.swift
enum TestTag: String {
    case fast, medium, slow           // Speed
    case unit, integration, performance, snapshot  // Type
    case model, service, viewModel, ui  // Layer
    case critical, regression          // Priority
}

// Example usage in test class
class ItemTests: XCTestCase {
    override var tags: [String] {
        [TestTag.fast.rawValue, TestTag.unit.rawValue, TestTag.model.rawValue]
    }
}
```

### Xcode Cloud Workflows

**Active Workflows:**
- **PR Fast Tests** (ID: `06d2431c-105b-4d94-87e4-448a4a9f7072`) - Automatic on PRs, runs FastTests plan (~5 min)
- **Release Builds** (ID: `dd86c07d-9030-4821-a301-64969a23ef6d`) - Tag-triggered (v*), full test + archive (~15 min)

**Projected Usage:** 7.1 hours/month (71% under 25-hour free tier)

| Workflow | Test Plan | Device | Time | Monthly |
|----------|-----------|--------|------|---------|
| PR Validation | FastTests | iPhone 17 Pro Max | 5 min | 1.7 hrs (20 PRs) |
| Main Branch | FullTests | iPhone 17 Pro Max | 10 min | 5.0 hrs (30 commits) |
| Pre-Release | FullTests | iPhone 17 Pro Max | 12 min | 0.4 hrs (2 releases) |

**CLI Tool:** `Tools/xcodecloud-cli` - Full CLI for workflow management via App Store Connect API

```bash
# Build CLI (one-time)
cd Tools/xcodecloud-cli && swift build -c release

# CLI location
CLI="Tools/xcodecloud-cli/.build/arm64-apple-macosx/release/xcodecloud-cli"

# List workflows
$CLI list-workflows --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF

# Monitor latest build for a workflow
./Tools/xcodecloud-cli/Scripts/xc-watch-latest.sh dd86c07d-9030-4821-a301-64969a23ef6d

# One-command release (tag + monitor)
./Tools/xcodecloud-cli/Scripts/release.sh 1.0.1

# List recent builds for workflow
$CLI list-builds --workflow dd86c07d-9030-4821-a301-64969a23ef6d --limit 5

# Monitor specific build
$CLI monitor-build --build <BUILD_ID> --follow

# Open build in browser
$CLI open-build --build <BUILD_ID>
```

**Credentials:** Stored in macOS Keychain (see `Tools/xcodecloud-cli/README.md` for setup)

**Configuration Scripts:**
- `Scripts/xc-cloud-create-workflows.sh` - Create workflows via API
- `Scripts/xc-cloud-usage.sh` - Monitor compute hour budget
- `Scripts/xc-env.sh` - Load App Store Connect credentials

**Documentation:**
- [Tools/xcodecloud-cli/README.md](Tools/xcodecloud-cli/README.md) - CLI documentation
- [Tools/xcodecloud-cli/XCODE_CLOUD_STATUS.md](Tools/xcodecloud-cli/XCODE_CLOUD_STATUS.md) - Feature status
- [XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md](docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md) - 19 advanced techniques
- [XCODE_CLOUD_TEST_OPTIMIZATION.md](docs/XCODE_CLOUD_TEST_OPTIMIZATION.md) - Full optimization strategy
- [IOS_BUILD_OPTIMIZATIONS.md](docs/IOS_BUILD_OPTIMIZATIONS.md) - Local build optimizations

## Project Configuration (XcodeGen)

**IMPORTANT:** The Xcode project is generated from `project.yml`. DO NOT hand-edit `.xcodeproj`.

```bash
# Regenerate project after modifying project.yml
xcodegen generate

# Or use the helper script
./Scripts/regenerate_project.sh           # Regenerate only
./Scripts/regenerate_project.sh --validate # Regenerate + validation build
```

### Build Configurations

| Config | Type | xcconfig | Use Case |
|--------|------|----------|----------|
| Debug | debug | Config/Debug.xcconfig | Development (Thread Sanitizer, Main Thread Checker) |
| Beta | release | Config/Beta.xcconfig | TestFlight (optimized with debug symbols) |
| Release | release | Config/Release.xcconfig | App Store (full optimization) |

### Schemes

| Scheme | Config | Purpose |
|--------|--------|---------|
| Nestory-Pro | Debug | Development & testing |
| Nestory-Pro-Beta | Beta | TestFlight builds |
| Nestory-Pro-Release | Release | App Store builds |

### Adding Dependencies

Add SwiftPM packages via `project.yml`, not Xcode UI:

```yaml
# In project.yml
packages:
  NewPackage:
    url: https://github.com/owner/repo
    from: 1.0.0

targets:
  Nestory-ProTests:
    dependencies:
      - package: NewPackage
```

Then regenerate: `xcodegen generate`

### Versioning (CRITICAL)

**Important:** Version numbers are defined in TWO places that MUST stay in sync:

| File | Keys | Purpose |
|------|------|---------|
| `project.yml` | `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` | XcodeGen project generation |
| `Config/Common.xcconfig` | `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` | Build settings |

**Problem:** XcodeGen settings in `project.yml` override xcconfig values during project generation. If they differ, the build uses the `project.yml` values.

**Solution - Version Bump Workflow:**
```bash
# 1. Update BOTH files (project.yml and Config/Common.xcconfig)
# In project.yml:
#   MARKETING_VERSION: "1.2.0"
#   CURRENT_PROJECT_VERSION: "2"
# In Config/Common.xcconfig:
#   MARKETING_VERSION = 1.2.0
#   CURRENT_PROJECT_VERSION = 2

# 2. Regenerate the project
xcodegen generate

# 3. Verify version before archiving
grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" project.yml Config/Common.xcconfig

# 4. Clean DerivedData to ensure fresh build
rm -rf ~/Library/Developer/Xcode/DerivedData/Nestory-Pro-*
```

**iOS Versioning Concepts:**
- **Version** (`CFBundleShortVersionString` / `MARKETING_VERSION`): User-visible version like "1.2.0"
- **Build** (`CFBundleVersion` / `CURRENT_PROJECT_VERSION`): Internal build number
- TestFlight requires unique build numbers per version
- Build numbers must increment (can't reuse)

**Verify Archive Version:**
```bash
# After archiving, verify the version is correct
plutil -p "path/to/archive.xcarchive/Products/Applications/Nestory-Pro.app/Info.plist" | grep -E "(CFBundleShortVersionString|CFBundleVersion)"
```

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

### Xcode Cloud (Primary)

All tests and builds run on Xcode Cloud:
- **PR validation**: Automatic via "PR Fast Tests" workflow
- **Release builds**: Tag-triggered via "Release Builds" workflow (push `v*` tag)
- **Monitoring**: Use `xcodecloud-cli` or helper scripts in `Tools/xcodecloud-cli/Scripts/`

### GitHub Actions

**`.github/workflows/xcodecloud-proxy.yml`** - Displays Xcode Cloud status on PRs and tags (placeholder for future integration)

**`.github/workflows/beta.yml`** - Legacy Fastlane workflow (requires secrets if used):
- `FASTLANE_APPLE_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT` (base64 .p8)

**Recommended workflow**: Use Xcode Cloud for all CI/CD. GitHub Actions provides visibility but actual work happens on Xcode Cloud.

## Monetization

- **Free**: Up to 100 items, basic PDF exports, loss list up to 20 items
- **Pro** ($19.99-$24.99 one-time): Unlimited items, PDF with photos, CSV/JSON export

---

## Claude Code-Specific Features

> **Platform:** Claude Code CLI (terminal-based agentic coding)
> **Unique Capabilities:** Checkpoints, Skills, Hooks, Plan Mode

### Checkpoints & Rollback

Claude Code supports **checkpoints** for saving progress and rolling back:

```bash
# Checkpoints are automatic during sessions
# Use rewind to rollback to previous state
/rewind

# View checkpoint history
/checkpoints
```

**Note:** Checkpoints track Claude's direct file edits but NOT bash commands like `rm`, `mv`, `cp`.

### Skills System

**Skills** are folders containing instructions, scripts, and resources that Claude loads dynamically:

```bash
# List available skills
/skills

# Create a custom skill
mkdir -p .claude/skills/nestory-test-runner
cat > .claude/skills/nestory-test-runner/SKILL.md << 'EOF'
---
name: Nestory Test Runner
description: Runs Nestory Pro tests with proper configuration
tools: [Bash, Read]
---

# Instructions
Always use iPhone 17 Pro Max simulator for tests.
Run unit tests before UI tests.
Check for Swift concurrency warnings.
EOF

# Use the skill
/nestory-test-runner
```

**Skill Locations:**
- **Personal:** `~/.claude/skills/` (global)
- **Project:** `.claude/skills/` (committed to git)

### Hooks for Customization

Hooks let you customize Claude's behavior at specific points:

```bash
# Example: Validate bash commands before execution
mkdir -p .claude/hooks
cat > .claude/hooks/bash-pre-call.py << 'EOF'
#!/usr/bin/env python3
import json, sys

data = json.load(sys.stdin)
command = data.get("tool_input", {}).get("command", "")

# Block dangerous commands
if "rm -rf /" in command:
    print("Blocked: Dangerous command", file=sys.stderr)
    sys.exit(2)  # Exit code 2 blocks the call
EOF

chmod +x .claude/hooks/bash-pre-call.py
```

**Hook Types:**
- `session-start` - Run when session begins
- `bash-pre-call` - Before bash commands
- `user-prompt-submit` - After user submits prompt

### Plan Mode

Use **Plan Mode** to preview implementation strategy before execution:

```bash
# Enter plan mode
/plan

# Claude will:
# 1. Analyze the task
# 2. Create step-by-step plan
# 3. Wait for your approval
# 4. Execute after approval
```

### Custom Commands

Create slash commands for repeated tasks:

```bash
# Create command
mkdir -p .claude/commands
echo "Run all tests with fastlane and report results" > .claude/commands/test-all.md

# Use command
/test-all
```

### Brave Mode

For autonomous operation without approval prompts:

```bash
# Enable brave mode (use with caution)
/brave

# Disable
/brave off
```

**Warning:** Only use in controlled environments. Claude will edit files and run commands without asking.

## Additional Documentation

- [PRODUCT-SPEC.md](PRODUCT-SPEC.md) - Complete product specs and UI layouts
- [TestingStrategy.md](TestingStrategy.md) - Comprehensive testing guide
- [WARP.md](WARP.md) - Extended development guide
- [PreviewExamples.md](PreviewExamples.md) - Preview and fixtures documentation
- [TODO.md](TODO.md) - Task management and version roadmap (agents MUST follow)
- [TODO-COMPLETE.md](TODO-COMPLETE.md) - Completed v1.0 tasks archive

**Note:** Always use iPhone 17 Pro Max as the simulator target.

---

## Snapshot Testing (v1.1+)

> **Package:** [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
> **Location:** `Nestory-ProTests/SnapshotTests/`

### Setup (One-Time)

1. Add package in Xcode: File → Add Package Dependencies
2. URL: `https://github.com/pointfreeco/swift-snapshot-testing`
3. Add `SnapshotTesting` framework to `Nestory-ProTests` target

### Writing Snapshot Tests

```swift
import SnapshotTesting
import XCTest
@testable import Nestory_Pro

final class InventorySnapshotTests: XCTestCase {
    @MainActor
    func testInventoryList_Empty() {
        let view = InventoryTab()
            .modelContainer(PreviewContainer.empty())

        assertSnapshot(
            matching: snapshotController(for: view),
            as: .image(on: .iPhone13ProMax),
            named: "empty"
        )
    }
}
```

### Standard Devices

Use `SnapshotDevice` enum from `SnapshotHelpers.swift`:
- `iPhone17ProMax` - Primary test device
- `iPhone17Pro` - Standard size
- `iPhoneSE3` - Small screen edge cases
- `iPadPro12_9` - Tablet layout

### Recording Baselines

```bash
# Set record mode in test file
isRecording = true

# Run tests once to generate baselines
xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro \
  -only-testing:Nestory-ProTests/SnapshotTests

# Set back to false for CI
isRecording = false
```

### Baselines Location

- Stored in `__Snapshots__/` directories next to test files
- Committed to git for CI comparison
- Review carefully when approving snapshot changes

---

## Agent Collaboration Rules

> **Authority:** These rules govern how Claude Code agents interact with this project.
> **Scope:** Applies to all strategic decisions, code changes, and documentation updates.

### Philosophy: Proactive Within Guardrails

You are **encouraged** to be proactive and opinionated:
- Propose concrete improvements
- Pre-draft files/sections and ask if wanted
- Suggest better structure, naming, workflows

**Critical Rule:** For strategic or high-impact changes, you MUST:
1. Propose the change in chat with concise rationale
2. Use `AskUserQuestion` tool to get explicit decision
3. Only then edit strategic docs/configuration

### Strategic Changes Requiring Approval

The following categories require `AskUserQuestion` before editing:

#### 1. Pricing & Monetization
- Tier names, prices, feature mappings
- Adding/removing pricing tiers
- Reassigning features between tiers

**Workflow:**
- Notice inconsistencies → propose fixes
- Draft updated Pricing Tier table
- Show diff → use `AskUserQuestion`: "Approve or revise?"
- Apply only after confirmation

**Exception:** Typo/formatting fixes that don't change meaning are OK.

#### 2. Release Schedule & Roadmap
- Version numbers (v1.1, v2.0, etc.)
- Target dates
- Moving tasks between versions
- Adding new roadmap versions

**Workflow:**
- Suggest: "Move task X from v1.3 → v1.4 because dependency Y"
- Draft updated version table + affected tasks
- Use `AskUserQuestion` before committing

#### 3. Product Behavior Mismatches
When PRODUCT-SPEC.md ≠ Tests ≠ Implementation:

**Workflow:**
- Identify mismatch: "Spec says X, tests expect Y, code does Z"
- Propose options:
  - A: Change spec to match tests
  - B: Change tests to match spec
  - C: Change implementation to match spec
- Use `AskUserQuestion` to choose
- Implement aligned fix across all three

#### 4. Constitution-Level Documents
Files: `PRODUCT-SPEC.md`, `TODO.md`, `CLAUDE.md`, `WARP.md`

**Allowed without asking:**
- Fix typos, grammar, formatting
- Improve clarity without changing intent
- Add clarifying comments/pointers

**Requires approval:**
- Change meaning of a rule
- Reorder governance precedence
- Rewrite sections that change agent/dev expectations

**Workflow:**
- Draft new wording
- Show before/after diff
- Use `AskUserQuestion` before applying

#### 5. Destructive/Structural Changes
- Deleting, merging, or rewriting planning files
- Major task structure/ID/phase reshuffles

**Workflow:**
- Discover → report: "Found TODO-OLD.md, here's contents"
- Propose migration plan
- Use `AskUserQuestion` before:
  - Deleting files
  - Merging them
  - Renumbering tasks/IDs in bulk

#### 6. Compliance/Security/Data Constraints
- GDPR flows, data retention, audit logs
- Multi-tenant behavior
- Any change affecting user data handling/exposure

**Workflow:**
- Propose changes
- Use `AskUserQuestion` before altering spec/behavior

### Orphaned Code Integration Protocol

**Definition:** Code that exists but isn't in build targets, unreferenced by production, or experimental/preview leftovers.

**Detection:**
- When you find orphaned code, summarize:
  - "Found OrphanedView.swift not in target, candidate for Settings"
  - "Found InventoryMigrationHelper in dead code path"
- **Do not auto-delete or auto-integrate**

**Proposal:**
- Suggest integration strategies:
  - A: Wire into Settings tab as advanced section
  - B: Move logic into existing ItemDetailViewModel
  - C: Archive into Legacy/ and note in TODO-COMPLETE.md

**Decision:**
- Use `AskUserQuestion` when you want to:
  - Integrate orphaned code into production
  - Delete/archive it
- Include: code description, recommended option, files to edit

**Execution:**
- After approval: wire in cleanly (UI, ViewModels, tests)
- Update TODO.md if needed
- Mention in session summary

### Autonomous Operation (No Approval Needed)

You can act independently for:
- Refactoring internals (public behavior unchanged)
- Bug fixes where correct behavior is clear from tests/spec/patterns
- Adding/expanding tests (coverage increase, no semantic change)
- Small design/UX polish within screens (matches spec, doesn't change pricing/paywall)
- Clarifying comments, better naming, small doc improvements
- Adjusting stale snapshots/layouts to match current spec

**Process:**
- Fix the thing
- Update tests
- Summarize in session summary

**When unsure:** Treat as strategic → use `AskUserQuestion`

### How to Use AskUserQuestion Effectively

**Pattern:**
1. **Think & draft first**
   - Draft updated section (TODO.md/PRODUCT-SPEC.md/pricing/code)
   - Prepare concise explanation

2. **Clear decision prompt**
   - Example: "Drafted Pricing Tier update: keeps Free as-is, shifts Feature X to Pro. Approve, request edits, or reject?"
   - Or: "Found orphaned FooBarFormatter. (A) Wire into Reports, (B) Move to ReportViewModel, (C) Archive?"

3. **After answer:**
   - Apply change
   - Summarize: "Applied user-approved change: [label]"

---

## Task Management

See [TODO.md](TODO.md) for complete task list and version roadmap.

**Agent Requirements:**
- Read TODO.md before starting work
- Follow checkout procedure for all tasks
- Respect `Blocked-by:` dependencies
- Never modify pricing or roadmap structure without approval (see Agent Collaboration Rules above)
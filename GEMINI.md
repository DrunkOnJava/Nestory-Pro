# GEMINI.md

This file provides guidance to Gemini Code Assist (Gemini CLI) when working with code in this repository.

## Project Overview

**Nestory Pro** is a native iOS 17+ app for home inventory management designed for insurance documentation. Built with Swift 5 (Swift 6 migration planned for v1.1), SwiftUI, and SwiftData. Core features: fast item capture, receipt OCR via Vision framework, documentation status tracking, and insurance-ready PDF exports.

### Swift Version Strategy
- **Current:** Swift 5.0 language mode (Xcode project setting)
- **Toolchain:** Swift 6.2.1 (latest Xcode)
- **v1.0 Launch:** Ship with Swift 5 for stability
- **v1.1 Target:** Migrate to Swift 6 strict concurrency mode
- **Reason:** Swift 6's strict concurrency checking surfaces warnings that need careful fixing. Shipping v1.0 with Swift 5 avoids last-minute concurrency bugs while still benefiting from Swift 6 toolchain optimizations.

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

| Test Plan | Time | Purpose |
|-----------|------|---------|
| FastTests | 5 min | PR validation |
| FullTests | 15 min | Main branch |
| CriticalPath | 2 min | Smoke tests |

All plans use iPhone 17 Pro Max with parallel execution enabled.

### Xcode Cloud

**7.1 hours/month usage** (71% under free tier):
- PR Validation: 1.7 hrs (5 min × 20)
- Main Branch: 5.0 hrs (10 min × 30)
- Pre-Release: 0.4 hrs (12 min × 2)

**Optimization Guides:**
- [XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md](docs/XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md) - 19 techniques
- [IOS_BUILD_OPTIMIZATIONS.md](docs/IOS_BUILD_OPTIMIZATIONS.md) - Build speedups

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

6-field weighted scoring:
- Photo: 30%
- Value: 25%
- Room: 15%
- Category: 10%
- Receipt: 10%
- Serial: 10%

## Key Technical Details

- **Swift 6 strict concurrency** - Use `@MainActor` for UI code, `async/await` for services
- **SwiftData + CloudKit** - Disabled for v1.0, enable in v1.1
- **Photo storage**: File-based with identifiers in database (not Data blobs)
- **iCloud container**: `iCloud.com.drunkonjava.nestory`
- **IAP product ID**: `com.drunkonjava.nestory.pro`

### Apple Frameworks

SwiftUI, SwiftData, Vision/VisionKit (OCR), Swift Charts, StoreKit 2, TipKit, LocalAuthentication

## Monetization

- **Free**: Up to 100 items, basic PDF exports, loss list up to 20 items
- **Pro** ($19.99-$24.99 one-time): Unlimited items, PDF with photos, CSV/JSON export

---

## Gemini CLI-Specific Features

> **Platform:** Gemini CLI (Google's command-line AI workflow tool)
> **Unique Capabilities:** Agent Mode, @ File Referencing, ! Shell Execution, Custom Commands

### Activating Agent Mode

**From Terminal:**
```bash
# Start Gemini CLI
gemini

# You're now in Agent Mode - natural language or commands
> Explain the authentication flow in this project
> Fix the failing tests in ItemTests.swift
```

**File & Directory Referencing with @:**
```bash
gemini

# Reference specific files
> @Nestory-Pro/Models/Item.swift Explain the documentationScore calculation

# Reference directories (git-aware filtering)
> @Nestory-Pro/Services/ Summarize all services and their responsibilities

# Multiple file references
> @Item.swift @ItemTests.swift Are the tests comprehensive?
```

**Shell Command Execution with !:**
```bash
gemini

# Execute commands directly
> !git status
> !bundle exec fastlane test
> !xcodebuild -version

# Toggle into shell mode
> !
Shell Mode> ls -la Nestory-Pro/Models/
Shell Mode> git log --oneline -5
Shell Mode> !  # Exit shell mode
```

### Custom Commands (TOML-based)

Create reusable commands for repeated tasks:

```bash
# Create custom command for running tests
mkdir -p ~/.gemini/commands
cat > ~/.gemini/commands/nestory-test.toml << 'EOF'
description = "Run Nestory Pro tests with proper simulator"
prompt = """
Run the test suite:
1. Use iPhone 17 Pro Max simulator
2. Run unit tests first
3. Then run UI tests
4. Report any failures with details

!{bundle exec fastlane test}
"""
EOF

# Use the command
gemini
> /nestory-test
```

**Shell Injection in Commands:**
```bash
# Command that injects git diff into prompt
cat > ~/.gemini/commands/smart-commit.toml << 'EOF'
description = "Generate commit message from staged changes"
prompt = """
Generate a Conventional Commit message for these changes:

```diff
!{git diff --staged}
```

Follow format: type(scope): description
"""
EOF

# Usage
git add .
gemini
> /smart-commit
```

### Memory & Context Management

Gemini CLI uses `/memory` commands to manage project context:

```bash
gemini

# View current project context (from GEMINI.md)
> /memory show

# Add custom instruction
> /memory add Always use iPhone 17 Pro Max for iOS simulator tests

# Refresh context from GEMINI.md files
> /memory refresh

# List GEMINI.md file locations
> /memory list
```

**Context File Search:** Gemini looks for `GEMINI.md` (configurable via `contextFileName` in settings.json).

### Extensions System

Manage Gemini CLI extensions:

```bash
# List installed extensions
gemini extensions list
# or from within CLI:
> /extensions

# Disable extension globally
gemini extensions disable extension-name

# Disable for current workspace only
gemini extensions disable extension-name --scope=workspace

# Update all extensions
gemini extensions update --all

# Uninstall
gemini extensions uninstall extension-name
```

### Checkpointing (Experimental)

Save and restore conversation and file states:

```bash
# Enable in ~/.gemini/settings.json:
{
  "checkpointing": {
    "enabled": true
  }
}

# Use /restore command in session
gemini
> /restore
```

### Headless Mode for Scripting

Use Gemini CLI in scripts and automation:

```bash
# Simple question
gemini -p "What is the capital of France?"

# Analyze code from stdin
cat Nestory-Pro/Models/Item.swift | gemini -p "Review this model for Swift 6 compatibility"

# Pipe to file
cat TODO.md | gemini -p "Summarize pending v1.1 tasks" > v1.1-summary.txt
```

### Agent Mode Workflow

**Human-in-the-Loop Approval:**
```bash
gemini

# Agent requests permission before running commands
> Deploy to TestFlight

Agent: I need to run: bundle exec fastlane beta
Agent: Press ENTER to confirm, Ctrl-C to cancel

[ENTER]  # Explicitly approve
# Command runs with GEMINI_CLI=1 environment variable
```

### Gemini-Optimized Workflows

**For This Project:**
```bash
gemini

# Codebase analysis
> @Nestory-Pro/ What's the overall architecture and key patterns?

# Multi-file edits
> Update all ViewModels to use Swift 6 @MainActor isolation

# Test analysis
> !bundle exec fastlane test
> Analyze the test results and suggest fixes

# Documentation generation
> @Nestory-Pro/Models/ Generate comprehensive API docs for all models
```

### Configuration File Location

```bash
# System defaults (admin-managed)
/etc/gemini-cli/settings.json

# User settings (highest precedence)
~/.gemini/settings.json

# Workspace settings (project-specific)
.gemini/settings.json

# Environment variable references
{
  "apiKey": "$GEMINI_API_KEY"
}
```

## Testing Strategy

- **Unit tests** (50-70%): Model computed properties, services, validation logic. < 0.1s per test.
- **Integration tests** (20-30%): SwiftData CRUD, relationship cascades. < 1s per test.
- **UI tests** (10-20%): Critical workflows with accessibility identifiers.
- **Performance tests**: Benchmark `documentationScore` with 1000+ items.

### Test Naming Convention

`test<What>_<Condition>_<ExpectedResult>()` - e.g., `testDocumentationScore_AllFieldsFilled_Returns1()`

## Code Style

- **ViewModels**: Use `@Observable` macro (not `@StateObject`)
- **Views**: Keep small and composable, extract to `SharedUI/` when reusable
- **Services**: Use `actor` for thread-safe services with state
- **Tests**: Use `TestFixtures` for predictable test data, `@MainActor` for SwiftData operations

## Additional Documentation

- [CLAUDE.md](CLAUDE.md) - Claude Code agent rules (see for collaboration model)
- [WARP.md](WARP.md) - Warp AI development guide
- [COPILOT.md](COPILOT.md) - GitHub Copilot instructions
- [PRODUCT-SPEC.md](PRODUCT-SPEC.md) - Complete product specs and UI layouts
- [TODO.md](TODO.md) - Task management and version roadmap (agents MUST follow)
- [TODO-COMPLETE.md](TODO-COMPLETE.md) - Completed v1.0 tasks archive

**Note:** Always use iPhone 17 Pro Max as the simulator target.

---

## Agent Collaboration Rules

> **Authority:** All agents MUST follow collaboration rules defined in [CLAUDE.md](CLAUDE.md).
> **Scope:** Strategic decisions, pricing, roadmap, compliance require `AskUserQuestion` approval.

See **CLAUDE.md § Agent Collaboration Rules** for complete governance model.

**Quick Reference:**
- ❌ **Never change** pricing, tiers, release dates without approval
- ❌ **Never modify** PRODUCT-SPEC.md behavior without approval
- ❌ **Never integrate** orphaned code without approval
- ✅ **Always use** `AskUserQuestion` for strategic changes
- ✅ **Autonomous** for bug fixes, refactoring, test additions

---

## Task Management

See [TODO.md](TODO.md) for complete task list and version roadmap.

**Agent Requirements:**
- Read TODO.md before starting work
- Follow checkout procedure for all tasks
- Respect `Blocked-by:` dependencies
- Never modify pricing or roadmap structure without approval

**Current Roadmap:** 52 pending tasks across v1.1 → v3.0 (8 versions)

---

## Gemini CLI Configuration Reference

### Directory Structure

```
~/.gemini/
├── settings.json        # User configuration
├── commands/            # Custom commands (.toml files)
│   ├── nestory-test.toml
│   └── smart-commit.toml
└── extensions/          # Installed extensions

.gemini/                 # Project-specific (optional)
└── settings.json        # Workspace configuration
```

### Recommended Settings

Create `.gemini/settings.json` in project root:

```json
{
  "context": {
    "fileName": ["GEMINI.md"],
    "includeDirectories": ["./"],
    "fileFiltering": {
      "respectGitIgnore": true
    }
  },
  "model": {
    "name": "gemini-2.5-pro",
    "maxSessionTurns": 20
  },
  "ui": {
    "theme": "GitHub",
    "hideTips": false
  },
  "experimental": {
    "checkpointing": {
      "enabled": true
    }
  }
}
```

### Model Selection for Swift/iOS

**Recommended:** `gemini-2.5-pro` for:
- Complex SwiftUI layouts
- SwiftData relationship modeling
- Multi-file refactoring
- Architectural decisions

**Alternative:** `gemini-1.5-flash` for:
- Quick syntax fixes
- Documentation generation
- Simple test additions

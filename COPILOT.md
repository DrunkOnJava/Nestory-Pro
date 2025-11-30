# COPILOT.md

This file provides guidance to GitHub Copilot (VS Code, JetBrains, CLI) when working with code in this repository.

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
```

## Deployment Commands

```bash
bundle exec fastlane beta               # TestFlight (auto-increments build)
bundle exec fastlane release            # App Store
bundle exec fastlane bump_version              # Patch: 1.0.0 -> 1.0.1
bundle exec fastlane bump_version type:minor   # Minor: 1.0.0 -> 1.1.0
```

Push to `main` branch triggers automatic TestFlight upload via GitHub Actions.

## Architecture

**MVVM with Clean Layers:**
- **Presentation**: SwiftUI Views + `@Observable` ViewModels (feature-organized)
- **Service**: Business logic (OCR, Reports, Backup, AppLock)
- **Model**: SwiftData `@Model` entities + value types

**Navigation**: 4-tab structure (Inventory, Capture, Reports, Settings)

## Core Data Models

All models use SwiftData `@Model` with relationships:

- **Item**: Inventory item with photos, receipts, category, room
- **Category**: Predefined + custom categories
- **Room**: Physical locations
- **Receipt**: OCR-extracted data, optional link to Item
- **ItemPhoto**: Photo metadata with file identifiers

## Monetization

- **Free**: Up to 100 items, basic PDF exports, loss list up to 20 items
- **Pro** ($19.99-$24.99 one-time): Unlimited items, PDF with photos, CSV/JSON export

---

## GitHub Copilot-Specific Features

> **Platform:** GitHub Copilot (VS Code, JetBrains, Xcode, CLI)
> **Unique Capabilities:** Inline Completions, Chat Variables, Workspace Context, GitHub Integration

### Keyboard Shortcuts (VS Code)

```typescript
// Chat and completions
Shift+Cmd+L (Mac) | Ctrl+Shift+Alt+L (Win)  // Open Chat
Cmd+I (Mac) | Ctrl+I (Win)                   // Inline Chat
Tab                                           // Accept suggestion
Alt+]                                         // Next suggestion
Alt+[                                         // Previous suggestion
Cmd+→ (Mac) | Ctrl+→ (Win)                   // Accept word
Cmd+↓ (Mac) | Ctrl+↓ (Win)                   // Accept line
```

### Slash Commands

Use slash commands for common tasks:

```swift
// In Copilot Chat:
/explain        // Explain selected code
/fix            // Propose fix for problems
/tests          // Generate unit tests
/doc            // Add documentation comments
/optimize       // Suggest performance improvements
/new            // Scaffold new project or file
/fixTestFailure // Find and fix failing test
/clear          // Start new chat session
```

**Example:**
```swift
// Select Item.swift documentationScore property
// Type in chat: /explain
// Copilot explains the 6-field weighted scoring logic
```

### Chat Variables (VS Code)

Reference specific context in your questions:

```swift
#file:Nestory-Pro/Models/Item.swift          // Reference specific file
#selection                                     // Reference selected text
#function                                      // Reference current function
#class                                         // Reference current class
#sym:documentationScore                        // Reference symbol
#project                                       // Reference entire project
```

**Example Usage:**
```text
@workspace #file:Item.swift How is documentation scoring calculated?

#selection /tests Generate comprehensive test cases for this computed property

@github List all issues with label 'v1.1' assigned to me
```

### Chat Participants

Direct questions to specialized agents:

```swift
@workspace    // Query entire workspace/codebase
@terminal     // Terminal command help
@vscode       // VS Code-specific help
@github       // GitHub operations (issues, PRs, search)
@azure        // Azure services (if applicable)
```

**Example:**
```text
@workspace Where are all the @Observable ViewModels defined?

@github Create a PR for this branch with summary of SwiftData changes

@terminal How do I reset Xcode DerivedData safely?
```

### Path-Specific Instructions

Create `.github/instructions/*.instructions.md` for targeted guidance:

```bash
mkdir -p .github/instructions

# Swift model guidelines
cat > .github/instructions/models.instructions.md << 'EOF'
---
applyTo: "**/Models/**/*.swift"
---

# SwiftData Model Guidelines

- Always use @Model macro
- Define relationships with @Relationship(deleteRule:)
- Computed properties for derived values
- No complex logic in models - use services
- Test all computed properties
EOF

# ViewModel guidelines
cat > .github/instructions/viewmodels.instructions.md << 'EOF'
---
applyTo: "**/ViewModels/**/*.swift"
---

# ViewModel Guidelines

- Use @Observable macro (Swift 5.9+)
- All ViewModels receive AppEnvironment in init
- No @MainActor unless absolutely necessary
- Keep business logic in Services
- Write unit tests for all public methods
EOF

# Test guidelines
cat > .github/instructions/tests.instructions.md << 'EOF'
---
applyTo: "**/*Tests.swift"
---

# Test Guidelines

- Use test<What>_<Condition>_<Expected>() naming
- Always use in-memory containers (TestContainer)
- Tests must be fast: unit < 0.1s, integration < 1s
- Use TestFixtures for predictable data
- @MainActor for SwiftData operations
EOF
```

### GitHub Integration

Copilot integrates deeply with GitHub:

```bash
# In VS Code Copilot Chat:
@github Show me all open PRs with 'bug' label
@github What's the status of issue #42?
@github Search for "SwiftData migration" in our organization's repos
```

### Copilot in Xcode (Limited)

**Note:** GitHub Copilot for Xcode has limited features compared to VS Code:
- Inline code completions work
- Chat features limited or unavailable
- Consider using VS Code for Swift alongside Xcode

**Recommendation:** Use Claude Code or Gemini CLI for terminal-based workflows with this project.

## Code Style & Patterns

- **ViewModels**: Use `@Observable` macro (not `@StateObject`)
- **Views**: Keep small and composable, extract to `SharedUI/` when reusable
- **Services**: Use `actor` for thread-safe services with state
- **Tests**: Use `TestFixtures` for predictable test data, `@MainActor` for SwiftData operations

## Additional Documentation

- [CLAUDE.md](CLAUDE.md) - Claude Code agent rules (primary collaboration model)
- [GEMINI.md](GEMINI.md) - Gemini CLI instructions
- [WARP.md](WARP.md) - Warp AI development guide
- [AGENTS.md](AGENTS.md) - Universal agent instructions
- [PRODUCT-SPEC.md](PRODUCT-SPEC.md) - Complete product specs
- [TODO.md](TODO.md) - Task management and version roadmap

---

## Agent Collaboration Rules

> **Authority:** All agents MUST follow collaboration rules defined in [CLAUDE.md](CLAUDE.md).
> **Summary:** Use `AskUserQuestion` (or equivalent) for strategic changes to pricing, roadmap, product behavior, or governance documents.

See **CLAUDE.md § Agent Collaboration Rules** for complete details.

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

## GitHub Copilot Configuration Reference

### Configuration Files

```
.github/
├── copilot-instructions.md      # Repository-wide instructions
└── instructions/                 # Path-specific instructions
    ├── models.instructions.md    # For **/Models/**/*.swift
    ├── viewmodels.instructions.md # For **/ViewModels/**/*.swift
    ├── tests.instructions.md     # For **/*Tests.swift
    └── services.instructions.md  # For **/Services/**/*.swift

COPILOT.md                       # This file (root)
AGENTS.md                        # Universal agent file (Copilot reads this too)
```

### VS Code Settings

Enable prompt files in `.vscode/settings.json`:

```json
{
  "github.copilot.chat.promptFiles": true
}
```

### Model Recommendations

- **Default:** Use GitHub Copilot's default model for inline completions
- **Chat:** Models updated automatically by GitHub
- **For Swift/iOS:** Copilot has good Swift support but may be less specialized than Claude for iOS frameworks

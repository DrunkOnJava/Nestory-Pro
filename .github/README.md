# .github Configuration

GitHub-specific configuration for Nestory Pro.

## Directory Structure

```
.github/
├── workflows/
│   ├── beta.yml              # Auto TestFlight on push to main
│   └── test.yml              # Run tests on PRs
├── instructions/              # GitHub Copilot path-specific instructions
│   ├── models.instructions.md      # SwiftData model guidelines
│   ├── viewmodels.instructions.md  # ViewModel patterns
│   ├── tests.instructions.md       # Testing conventions
│   └── services.instructions.md    # Service architecture
├── copilot-instructions.md   # Repository-wide Copilot instructions
└── README.md                  # This file
```

## Copilot Instructions

### Repository-Wide Instructions

**File:** `copilot-instructions.md`
**Scope:** All files in repository
**Purpose:** General coding standards, simulator requirements, governance rules

### Path-Specific Instructions

**Directory:** `instructions/`
**Format:** `NAME.instructions.md` with `applyTo` frontmatter
**Precedence:** More specific paths override general instructions

**Current Files:**
- `models.instructions.md` - SwiftData model patterns (`**/Models/**/*.swift`)
- `viewmodels.instructions.md` - ViewModel architecture (`**/ViewModels/**/*.swift`)
- `tests.instructions.md` - Testing conventions (`**/*Tests.swift`)
- `services.instructions.md` - Service layer patterns (`**/Services/**/*.swift`)

### Usage in VS Code

Enable prompt files in `.vscode/settings.json`:

```json
{
  "github.copilot.chat.promptFiles": true
}
```

Then use chat variables:

```text
#file:Item.swift /explain
@workspace How are photos stored?
```

## GitHub Actions Workflows

### beta.yml

**Trigger:** Push to `main` or tag matching `v*-beta*`
**Actions:**
1. Run unit tests
2. Build app
3. Upload to TestFlight

**Required Secrets:**
- `FASTLANE_APPLE_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT`

### test.yml

**Trigger:** Pull requests, push to main
**Actions:**
1. Run unit tests only (fast feedback)
2. Cache DerivedData for speed

## Agent File Priority

Multiple agent instruction files exist. **Precedence:**

1. **AGENTS.md** (root) - Universal instructions, Copilot reads this
2. **.github/copilot-instructions.md** - Copilot-specific, repository-wide
3. **.github/instructions/*.instructions.md** - Path-specific (highest precedence for matching files)

**Also available** (agent-specific):
- **CLAUDE.md** - Claude Code instructions (Copilot can read as alternative)
- **GEMINI.md** - Gemini CLI instructions (Copilot can read as alternative)
- **COPILOT.md** - Detailed Copilot guide
- **WARP.md** - Warp terminal guide

---

**Last Updated:** November 29, 2025

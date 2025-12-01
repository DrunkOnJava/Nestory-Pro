---
description: Create a new Xcode Cloud workflow
allowed-tools: Bash(*)
argument-hint: [name] [type] [scheme]
---

# Create Xcode Cloud Workflow

Create a new Xcode Cloud workflow using the CLI.

**Workflow Types:**
- `pr` - Automatic on pull requests
- `tag` - Automatic on tag creation (use with --tag-pattern)
- `manual` - Manual trigger only

**Common Schemes:**
- `Nestory-Pro` - Debug builds and testing
- `Nestory-Pro-Beta` - TestFlight builds
- `Nestory-Pro-Release` - App Store builds

**Example commands:**

Create PR workflow:
```bash
Tools/xcodecloud-cli/.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "$1" \
  --description "Created via CLI" \
  --type ${2:-pr} \
  --scheme ${3:-Nestory-Pro} \
  --action test
```

Create tag-triggered release workflow:
```bash
Tools/xcodecloud-cli/.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "Release Pipeline" \
  --description "Full test + archive on tags" \
  --type tag \
  --tag-pattern "v*" \
  --scheme Nestory-Pro-Release \
  --action test \
  --action archive
```

**Note:** Branch workflows require file matchers (not yet supported in CLI).

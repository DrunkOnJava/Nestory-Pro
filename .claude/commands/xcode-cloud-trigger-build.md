---
description: Manually trigger an Xcode Cloud build
allowed-tools: Bash(*)
argument-hint: [workflow-id] [branch]
---

# Trigger Xcode Cloud Build

Manually trigger a build for a specific workflow.

**Known Workflow IDs:**
- PR Fast Tests: `06d2431c-105b-4d94-87e4-448a4a9f7072`
- Release Builds: `dd86c07d-9030-4821-a301-64969a23ef6d`

Trigger with provided workflow and branch (defaults to PR Fast Tests on main):
```bash
Tools/xcodecloud-cli/.build/arm64-apple-macosx/release/xcodecloud-cli trigger-build --workflow ${1:-06d2431c-105b-4d94-87e4-448a4a9f7072} --branch ${2:-main}
```

This will start a new build and return the build ID for monitoring.

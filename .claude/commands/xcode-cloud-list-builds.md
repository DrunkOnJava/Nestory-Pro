---
description: List recent builds for an Xcode Cloud workflow
allowed-tools: Bash(*)
argument-hint: [workflow-id] [limit]
---

# List Xcode Cloud Builds

List recent builds for a workflow. If no workflow ID provided, default to PR Fast Tests.

**Known Workflow IDs:**
- PR Fast Tests: `06d2431c-105b-4d94-87e4-448a4a9f7072`
- Release Builds: `dd86c07d-9030-4821-a301-64969a23ef6d`

Run the CLI with the provided workflow (or default):
```bash
Tools/xcodecloud-cli/.build/arm64-apple-macosx/release/xcodecloud-cli list-builds --workflow ${1:-06d2431c-105b-4d94-87e4-448a4a9f7072} --limit ${2:-10}
```

Show build IDs, status, creation date, and completion time in a table format.

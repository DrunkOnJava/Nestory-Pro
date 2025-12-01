---
description: List all Xcode Cloud workflows for Nestory-Pro
allowed-tools: Bash(*)
---

# List Xcode Cloud Workflows

List all Xcode Cloud workflows for Nestory-Pro.

Run the xcodecloud-cli to fetch workflows:

```bash
Tools/xcodecloud-cli/.build/arm64-apple-macosx/release/xcodecloud-cli list-workflows --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF
```

Show workflow names, IDs, and trigger types (PR, tag, branch, manual) in a formatted table.

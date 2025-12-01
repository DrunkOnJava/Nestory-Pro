---
description: Monitor an Xcode Cloud build in real-time
allowed-tools: Bash(*)
argument-hint: [build-id]
---

# Monitor Xcode Cloud Build

Monitor a specific build in real-time until completion.

If build ID is provided as `$ARGUMENTS`, monitor that build:
```bash
Tools/xcodecloud-cli/.build/arm64-apple-macosx/release/xcodecloud-cli monitor-build --build $ARGUMENTS --follow
```

If no build ID provided, get the latest build from the Release Builds workflow and monitor it:
```bash
./Tools/xcodecloud-cli/Scripts/xc-watch-latest.sh dd86c07d-9030-4821-a301-64969a23ef6d
```

Display status updates every 15 seconds until build completes (COMPLETE or ERROR).

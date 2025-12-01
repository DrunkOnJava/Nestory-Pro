---
description: Create a release with tag-triggered Xcode Cloud build
allowed-tools: Bash(*)
argument-hint: [version]
---

# Xcode Cloud Release

Create a release using the one-command release pipeline.

**This will:**
1. Validate version format (e.g., 1.0.2, 1.0.2-rc1)
2. Check if tag already exists
3. Create and push git tag (v*)
4. Trigger Xcode Cloud "Release Builds" workflow
5. Provide monitoring instructions

Run the release script with the provided version `$ARGUMENTS`:
```bash
./Tools/xcodecloud-cli/Scripts/release.sh $ARGUMENTS
```

**After the tag is pushed, Xcode Cloud will:**
1. Run full test suite (iPhone 17 Pro Max)
2. Create optimized archive with Nestory-Pro-Release scheme
3. Upload to App Store Connect
4. Ready for TestFlight or App Store submission

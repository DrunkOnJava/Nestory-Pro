# Xcode Cloud CI Scripts

This directory contains custom build scripts for Xcode Cloud continuous integration.

## Overview

Xcode Cloud automatically runs these scripts at specific points during the build process:

| Script | When It Runs | Purpose |
|--------|-------------|---------|
| `ci_post_clone.sh` | After cloning repository | Install dependencies (Fastlane, gems) |
| `ci_pre_xcodebuild.sh` | Before running xcodebuild | Auto-increment build number, setup environment |

## Scripts

### ci_post_clone.sh

Runs immediately after Xcode Cloud clones your repository. Use this to:
- Install Ruby dependencies via Bundler (`bundle install`)
- Install npm/node packages (if needed)
- Download/configure additional tools
- Verify environment versions

**Current Actions:**
- ✅ Install Fastlane via `bundle install`
- ✅ Verify Xcode and Swift versions
- ✅ Log environment information

### ci_pre_xcodebuild.sh

Runs right before xcodebuild command executes. Use this to:
- Modify build settings
- Auto-increment build/version numbers
- Generate configuration files
- Set environment-specific variables

**Current Actions:**
- ✅ Auto-increment `CFBundleVersion` based on git commit count
- ✅ Log build configuration (scheme, action, workflow)
- ✅ Provide unique build numbers for each CI build

## Environment Variables Available

Xcode Cloud provides these environment variables in scripts:

| Variable | Description | Example |
|----------|-------------|---------|
| `CI_WORKSPACE` | Workspace being built | `Nestory-Pro.xcworkspace` |
| `CI_XCODEBUILD_ACTION` | Build action | `build`, `test`, `archive` |
| `CI_XCODEBUILD_SCHEME` | Scheme being built | `Nestory-Pro` |
| `CI_XCODEBUILD_CONFIGURATION` | Build configuration | `Debug`, `Beta`, `Release` |
| `CI_WORKFLOW` | Workflow name | `PR Validation`, `Main Build` |
| `CI_BUILD_NUMBER` | Xcode Cloud build number | `42` |
| `CI_COMMIT` | Git commit SHA | `abc123...` |
| `CI_BRANCH` | Git branch name | `main`, `feature/xyz` |
| `CI_TAG` | Git tag (if any) | `v1.0.0` |
| `CI_PULL_REQUEST_NUMBER` | PR number (if PR) | `123` |

Full list: [Xcode Cloud Environment Variables](https://developer.apple.com/documentation/xcode/environment-variable-reference)

## Customization

### Adding More Dependencies

Edit `ci_post_clone.sh`:
```bash
# Install node packages (if needed)
if [ -f "package.json" ]; then
    npm install
fi

# Install CocoaPods (if needed)
if [ -f "Podfile" ]; then
    pod install
fi
```

### Custom Build Number Strategy

Edit `ci_pre_xcodebuild.sh`:
```bash
# Option 1: Use Xcode Cloud build number
BUILD_NUMBER=$CI_BUILD_NUMBER

# Option 2: Use date-based versioning
BUILD_NUMBER=$(date +%Y%m%d%H%M)

# Option 3: Use git tag version
BUILD_NUMBER=$(git describe --tags --always)
```

### Conditional Logic by Workflow

Different actions for different workflows:
```bash
if [ "$CI_WORKFLOW" = "Release Build" ]; then
    echo "Running release-specific setup..."
    # Release-only actions
elif [ "$CI_WORKFLOW" = "PR Validation" ]; then
    echo "Running PR-specific setup..."
    # PR-only actions
fi
```

## Debugging

To test these scripts locally before pushing:
```bash
# Simulate post-clone
CI_WORKFLOW="local" ./ci_scripts/ci_post_clone.sh

# Simulate pre-xcodebuild
CI_WORKFLOW="local" \
CI_XCODEBUILD_SCHEME="Nestory-Pro" \
CI_XCODEBUILD_ACTION="build" \
./ci_scripts/ci_pre_xcodebuild.sh
```

## Best Practices

1. **Keep scripts fast** - They run on every build
2. **Use `set -e`** - Exit on first error to fail fast
3. **Log verbosely** - Cloud logs are your only debugging tool
4. **Test locally first** - Simulate CI environment variables
5. **Version control everything** - No manual cloud configuration

## Troubleshooting

**Script not running?**
- Verify scripts are executable: `chmod +x ci_scripts/*.sh`
- Check script names match exactly: `ci_post_clone.sh`, `ci_pre_xcodebuild.sh`
- Ensure scripts are in `ci_scripts/` directory at repository root

**Bundle install failing?**
- Verify `Gemfile` exists in repository root
- Check Xcode Cloud macOS version supports Ruby version
- Consider using specific Ruby version in `Gemfile`

**Build number not updating?**
- Check script logs in Xcode Cloud build results
- Verify Info.plist path is correct
- Ensure PlistBuddy command has correct key path

## References

- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- [Custom Build Scripts Guide](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [Environment Variables Reference](https://developer.apple.com/documentation/xcode/environment-variable-reference)

---

**Last Updated:** November 30, 2025

#!/bin/sh
set -e

echo "========================================="
echo "Xcode Cloud: Pre-Xcodebuild Setup"
echo "========================================="

# Auto-increment build number based on commit count
# This ensures each Xcode Cloud build has a unique build number
if [ "$CI_WORKFLOW" != "" ]; then
    echo "📊 Calculating build number..."

    # Handle shallow clones (Xcode Cloud uses shallow by default)
    if git rev-parse --is-shallow-repository 2>/dev/null | grep -q true; then
        BUILD_NUMBER=$(date +%Y%m%d%H%M)
        echo "📊 Using timestamp for shallow clone: $BUILD_NUMBER"
    else
        BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || date +%Y%m%d%H%M)
        echo "📈 Build number from git history: $BUILD_NUMBER"
    fi

    # Update Info.plist with new build number
    # Note: Xcode Cloud uses Info.plist in project root or target
    # Adjust path if your Info.plist is elsewhere
    if [ -f "Nestory-Pro/Info.plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "Nestory-Pro/Info.plist"
        echo "✅ Updated CFBundleVersion to $BUILD_NUMBER"
    else
        echo "ℹ️  Using build number from project settings"
    fi
fi

# Print build configuration
echo ""
echo "🔍 Build Environment:"
echo "  Scheme: ${CI_XCODEBUILD_SCHEME:-unknown}"
echo "  Configuration: ${CI_XCODEBUILD_CONFIGURATION:-unknown}"
echo "  Action: ${CI_XCODEBUILD_ACTION:-unknown}"
echo "  Workflow: ${CI_WORKFLOW:-local}"

echo ""
echo "✅ Pre-xcodebuild setup complete"
echo "========================================="

#!/bin/sh
set -e

echo "========================================="
echo "Xcode Cloud: Post-Clone Setup"
echo "========================================="

# Install Ruby dependencies (Fastlane)
if [ -f "Gemfile" ]; then
    echo "📦 Installing Fastlane and dependencies..."
    bundle install
    echo "✅ Bundle install complete"
else
    echo "⚠️  No Gemfile found, skipping bundle install"
fi

# Verify Xcode version
echo ""
echo "🔍 Xcode version:"
xcodebuild -version

# Verify Swift version
echo ""
echo "🔍 Swift version:"
swift --version

echo ""
echo "✅ Post-clone setup complete"
echo "========================================="

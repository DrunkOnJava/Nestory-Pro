#!/bin/sh
set -e

echo "========================================="
echo "Xcode Cloud: Post-Xcodebuild Analysis"
echo "========================================="

# Extract build timing information if available
if [ -n "$CI_RESULT_BUNDLE_PATH" ]; then
    echo "📊 Extracting build timing information..."
    echo "Build Timing Summary:" >> "$CI_RESULT_BUNDLE_PATH/timing.txt"
    echo "Result bundle: $CI_RESULT_BUNDLE_PATH"
fi

# Print test execution summary
if [ "$CI_XCODEBUILD_ACTION" = "test" ]; then
    echo ""
    echo "🧪 Test Execution Summary:"
    echo "  Action: ${CI_XCODEBUILD_ACTION}"
    echo "  Scheme: ${CI_XCODEBUILD_SCHEME}"
    echo "  Configuration: ${CI_XCODEBUILD_CONFIGURATION}"
fi

# Performance metrics logging
echo ""
echo "⏱️  Build Performance Metrics:"
echo "  Workflow: ${CI_WORKFLOW:-local}"
echo "  Completed: $(date)"

echo ""
echo "✅ Post-xcodebuild analysis complete"
echo "========================================="

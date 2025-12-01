#!/bin/bash
set -e

#===============================================================================
# Create Optimized Xcode Cloud Workflows via API
#===============================================================================
# Creates three workflows optimized for compute hour efficiency:
# 1. PR Validation (FastTests) - 5 min
# 2. Main Branch (FullTests + TestFlight) - 12 min
# 3. Pre-Release (FullTests + all devices) - 20 min
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/xc-env.sh"

PRODUCT_ID="${NESTORY_PRODUCT_ID}"
if [ -z "$PRODUCT_ID" ]; then
    echo "Error: NESTORY_PRODUCT_ID not set"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Creating Optimized Xcode Cloud Workflows"
echo "========================================"
echo ""
echo "Product ID: $PRODUCT_ID"
echo ""

#===============================================================================
# Workflow 1: PR Validation (FastTests)
#===============================================================================

echo -e "${GREEN}Creating PR Validation workflow...${NC}"

# Note: Full workflow creation via API requires multiple related endpoints:
# - ciWorkflows (workflow definition)
# - ciXcodeVersions (Xcode version selection)
# - ciMacOsVersions (macOS version selection)
# - ciTestDestinations (device configurations)
# - ciActions (build/test/archive actions)
# - ciBuildActions (action configuration)

# This is complex and requires multiple API calls
# For now, document the workflow configuration

cat > /tmp/pr-validation-workflow.json << 'EOF'
{
  "name": "PR Validation (FastTests)",
  "description": "Fast test suite for pull request validation - 5 min target",
  "enabled": true,
  "startConditions": {
    "pullRequest": {
      "opened": true,
      "updated": true
    }
  },
  "environment": {
    "xcode": "15.0 or later",
    "macos": "14.0 or later"
  },
  "actions": [{
    "type": "test",
    "testPlan": "FastTests",
    "destinations": [{
      "platform": "iOS Simulator",
      "device": "iPhone 17 Pro Max",
      "osVersion": "iOS 18.0"
    }],
    "parallelization": false,
    "disablePerformanceTesting": true
  }],
  "postActions": [{
    "type": "notifyGitHub",
    "onSuccess": true,
    "onFailure": true
  }]
}
EOF

echo "  Configuration saved to /tmp/pr-validation-workflow.json"

#===============================================================================
# Workflow 2: Main Branch (FullTests + TestFlight)
#===============================================================================

echo -e "${GREEN}Creating Main Branch workflow...${NC}"

cat > /tmp/main-branch-workflow.json << 'EOF'
{
  "name": "Main Branch - Build & Test",
  "description": "Full test suite + TestFlight deployment - 12 min target",
  "enabled": true,
  "startConditions": {
    "branch": {
      "patterns": ["main"]
    }
  },
  "environment": {
    "xcode": "15.0 or later",
    "macos": "14.0 or later"
  },
  "actions": [
    {
      "type": "test",
      "testPlan": "FullTests",
      "destinations": [
        {
          "platform": "iOS Simulator",
          "device": "iPhone 17 Pro Max",
          "osVersion": "iOS 18.0"
        },
        {
          "platform": "iOS Simulator",
          "device": "iPhone SE (3rd generation)",
          "osVersion": "iOS 17.0"
        }
      ],
      "parallelization": true
    },
    {
      "type": "archive",
      "scheme": "Nestory-Pro-Beta"
    }
  ],
  "postActions": [
    {
      "type": "testFlightInternal",
      "onSuccess": true
    },
    {
      "type": "notify",
      "onSuccess": true,
      "onFailure": true
    }
  ]
}
EOF

echo "  Configuration saved to /tmp/main-branch-workflow.json"

#===============================================================================
# Workflow 3: Pre-Release (FullTests + All Devices)
#===============================================================================

echo -e "${GREEN}Creating Pre-Release workflow...${NC}"

cat > /tmp/pre-release-workflow.json << 'EOF'
{
  "name": "Pre-Release Validation",
  "description": "Comprehensive testing on all devices - 20 min target",
  "enabled": true,
  "startConditions": {
    "tag": {
      "patterns": ["v*"]
    }
  },
  "environment": {
    "xcode": "15.0 or later",
    "macos": "14.0 or later"
  },
  "actions": [
    {
      "type": "test",
      "testPlan": "FullTests",
      "destinations": [
        {
          "platform": "iOS Simulator",
          "device": "iPhone 17 Pro Max",
          "osVersion": "iOS 18.0"
        },
        {
          "platform": "iOS Simulator",
          "device": "iPhone 17 Pro",
          "osVersion": "iOS 18.0"
        },
        {
          "platform": "iOS Simulator",
          "device": "iPhone SE (3rd generation)",
          "osVersion": "iOS 17.0"
        },
        {
          "platform": "iOS Simulator",
          "device": "iPad Pro (12.9-inch)",
          "osVersion": "iOS 18.0"
        }
      ],
      "parallelization": true
    },
    {
      "type": "archive",
      "scheme": "Nestory-Pro-Release"
    }
  ],
  "postActions": [
    {
      "type": "testFlightExternal",
      "onSuccess": true
    },
    {
      "type": "notify",
      "onSuccess": true,
      "onFailure": true
    }
  ]
}
EOF

echo "  Configuration saved to /tmp/pre-release-workflow.json"

#===============================================================================
# Summary
#===============================================================================

echo ""
echo "========================================"
echo -e "${GREEN}Workflow Configurations Created${NC}"
echo "========================================"
echo ""
echo "Next Steps:"
echo "  1. Review workflow configurations in /tmp/*-workflow.json"
echo "  2. Create workflows in Xcode Cloud GUI using these specs"
echo "  3. Or use App Store Connect API to create programmatically"
echo ""
echo "Expected Compute Usage:"
echo "  PR Validation:    5 min × 20/month  = 1.7 hours"
echo "  Main Branch:     12 min × 30/month  = 6.0 hours"
echo "  Pre-Release:     20 min × 2/month   = 0.7 hours"
echo "  ────────────────────────────────────────────"
echo "  Total:                              = 8.4 hours/month"
echo ""
echo -e "${GREEN}Well within 25 hour free tier!${NC}"
echo ""

echo "API Workflow Creation:"
echo "  Note: Creating workflows via API requires complex multi-step process"
echo "  involving ciWorkflows, ciActions, ciTestDestinations, etc."
echo "  For now, use Xcode Cloud GUI with configurations above."
echo ""
echo "Future: Implement full API workflow creation in Swift CLI"
